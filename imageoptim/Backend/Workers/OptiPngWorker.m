//
//  AdvCompWorker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "OptiPngWorker.h"
#import "../Job.h"
#import "../TempFile.h"

@implementation OptiPngWorker

-(instancetype)initWithLevel:(NSInteger)level file:(Job *)aJob {
    if (self = [super initWithFile:aJob]) {
        optlevel = MAX(3, MIN(level+1, 7));
    }
    return self;
}


-(NSInteger)settingsIdentifier {
    return optlevel*2;
}

-(BOOL)optimizeFile:(File *)file toTempPath:(NSURL *)temp {

    NSMutableArray *args = [NSMutableArray arrayWithObjects: [NSString stringWithFormat:@"-o%d",(int)(optlevel ? optlevel : 6)],
                            @"-i0",
                            @"-out",temp.path,@"--",file.path,nil];

    if (![self taskForKey:@"OptiPng" bundleName:@"optipng" arguments:args]) {
        return NO;
    }

    NSPipe *commandPipe = [NSPipe pipe];
    NSFileHandle *commandHandle = [commandPipe fileHandleForReading];

    [task setStandardError: commandPipe];
    [task setStandardOutput: commandPipe];

    [self launchTask];

    [self parseLinesFromHandle:commandHandle];

    BOOL ok = [self waitUntilTaskExit];
    [commandHandle closeFile];

    if (!ok) return NO;

    if (fileSizeOptimized) {
        return [job setFileOptimized:[file tempCopyOfPath:temp size:fileSizeOptimized] toolName:@"OptiPNG"];
    }
    return NO;
}

-(BOOL)parseLine:(NSString *)line {
    NSUInteger res;

    if ([line length] > 20) {
        if ((res = [self readNumberAfter:@"Output file size = " inLine:line])) {
            fileSizeOptimized = res;
            return YES;
        }
    }
    return NO;
}

@end
