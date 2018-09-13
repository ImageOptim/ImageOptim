//
//  AdvCompWorker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "OxiPngWorker.h"
#import "../Job.h"
#import "../TempFile.h"

@implementation OxiPngWorker

-(instancetype)initWithLevel:(NSInteger)level stripMetadata:(BOOL)aStrip file:(Job *)aJob {
    if (self = [super initWithFile:aJob]) {
        optlevel = MAX(2, MIN(level, 6));
        strip = aStrip;
    }
    return self;
}


-(NSInteger)settingsIdentifier {
    return optlevel*2 + strip;
}

-(BOOL)optimizeFile:(File *)file toTempPath:(NSURL *)temp {

    NSMutableArray *args = [NSMutableArray arrayWithObjects: [NSString stringWithFormat:@"-o%d",(int)(optlevel ? optlevel : 6)],
                            @"-i0", "-a",
                            @"--out",temp.path,@"--",file.path,nil];
    if (strip) {
        [args insertObject:@"--strip=safe" atIndex:0];
    }

    if (![self taskForKey:@"OptiPng" bundleName:@"oxipng" arguments:args]) {
        return NO;
    }

    NSPipe *commandPipe = [NSPipe pipe];
    NSFileHandle *commandHandle = [commandPipe fileHandleForReading];

    [task setStandardError:commandPipe];
    [task setStandardOutput:commandPipe];

    [self launchTask];

    [self parseLinesFromHandle:commandHandle];

    BOOL ok = [self waitUntilTaskExit];
    [commandHandle closeFile];

    if (!ok) return NO;

    if (fileSizeOptimized) {
        return [job setFileOptimized:[file tempCopyOfPath:temp size:fileSizeOptimized] toolName:@"OxiPNG"];
    }
    return NO;
}

- (BOOL)parseLine:(NSString *)line {
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
