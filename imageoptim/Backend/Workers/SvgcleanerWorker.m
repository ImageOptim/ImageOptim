
#import "SvgcleanerWorker.h"
#import "../Job.h"
#import "../TempFile.h"
#import "../../log.h"

@implementation SvgcleanerWorker

- (instancetype)initWithLossy:(BOOL)lossy job:(Job *)f {
    if (self = [super initWithFile:f]) {
        useLossy = lossy;
    }
    return self;
}

- (NSInteger)settingsIdentifier {
    return useLossy ? 5 : 6;
}

- (BOOL)optimizeFile:(File *)file toTempPath:(NSURL *)temp {
    NSMutableArray *args = [NSMutableArray arrayWithObjects:@"--stdout", @"--", file.path,
                                                            nil];

    if (![self taskForKey:@"Svgcleaner" bundleName:@"svgcleaner" arguments:args]) {
        return NO;
    }

    NSError *err = nil;
    [[NSData new] writeToURL:temp atomically:NO]; // make the file
    NSFileHandle *fileOutputHandle = [NSFileHandle fileHandleForWritingToURL:temp error:&err];

    if (!fileOutputHandle) {
        IOWarn("Can't create %@ %@", temp.path, err);
        return NO;
    }

    [task setStandardOutput:fileOutputHandle];

    NSFileHandle *devnull = [NSFileHandle fileHandleWithNullDevice];

    [task setStandardInput:devnull];
    [task setStandardError:devnull];

    [self launchTask];
    BOOL ok = [self waitUntilTaskExit];

    [devnull closeFile];
    [fileOutputHandle closeFile];

    if (!ok) return NO;

    return [job setFileOptimized:[file tempCopyOfPath:temp] toolName:@"Svgcleaner"];
}

@end
