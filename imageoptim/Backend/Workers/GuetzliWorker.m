//
//  GuezilWorker.m
//  ImageOptim
//
//  Created by Peter Kovacs on 3/17/17.
//
//

#import "GuetzliWorker.h"
#import "../Job.h"
#import "../TempFile.h"
#import "../../log.h"

@implementation GuetzliWorker

-(instancetype)initWithDefaults:(NSUserDefaults *)defaults serialQueue:(dispatch_queue_t)q file:(Job *)aFile {
    if (self = [super initWithFile:aFile]) {
        queue = q;
        level = [defaults boolForKey:@"LossyEnabled"] ? [defaults integerForKey:@"JpegOptimMaxQuality"] : 95;
        if (level < 84) {
            level = 84;
        }
    }
    return self;
}

- (BOOL)makesNonOptimizingModifications {
    return YES;
}

- (BOOL)optimizeFile:(File *)file toTempPath:(NSURL *)temp {
    NSMutableArray *args = [NSMutableArray arrayWithObjects:
                            @"--quality", [NSString stringWithFormat:@"%ld", (long)level],
                            file.path,
                            temp.path,
                            nil];

    if (![self taskForKey:@"Guetzli" bundleName:@"guetzli" arguments:args]) {
        return NO;
    }

    NSString *guetzliPath = [self pathForExecutableName:@"guetzli"];
    if (!guetzliPath) {
        return NO;
    }

    BOOL __block ok = NO;
    NSPipe *commandPipe = [NSPipe pipe];
    NSFileHandle *commandHandle = [commandPipe fileHandleForReading];

    void (^run)(void) = ^{
        [task setStandardOutput:commandPipe];
        [task setStandardError:commandPipe];

        [self launchTask];

        [commandHandle readToEndOfFileInBackgroundAndNotify];

        ok = [self waitUntilTaskExit];
    };
    if (![file isSmall]) {
        // Guetzli uses so much memory, that it's dangerous to run all images in parallel
        dispatch_sync(queue, run);
    } else {
        run();
    }

    [commandHandle closeFile];

    if (!ok) return NO;

    TempFile *output = [file tempCopyOfPath:temp];

    return [job setFileOptimized:output toolName:@"Guetzli"];
}

@end
