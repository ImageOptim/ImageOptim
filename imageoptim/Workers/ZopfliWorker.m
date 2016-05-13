
#import "ZopfliWorker.h"
#import "../File.h"

@implementation ZopfliWorker

@synthesize alternativeStrategy;

-(instancetype)initWithLevel:(NSInteger)aLevel defaults:(NSUserDefaults *)defaults file:(File *)aFile {
    if (self = [super initWithFile:aFile]) {
        iterations = 3 + 3*aLevel;
        strip = [defaults boolForKey:@"PngOutRemoveChunks"];
        timelimit = [self timelimitForLevel:aLevel];
    }
    return self;
}

-(NSInteger)settingsIdentifier {
    return iterations*4 + strip*2 + alternativeStrategy;
}

-(BOOL)runWithTempPath:(NSURL *)temp {
    NSMutableArray *args = [NSMutableArray arrayWithObjects: @"--lossy_transparent",@"-y",/*@"--",*/file.filePathOptimized.path,temp.path,nil];

    if (!strip) {
        // FIXME: that's crappy. Should list actual chunks in file :/
        [args insertObject:@"--keepchunks=tEXt,zTXt,iTXt,gAMA,sRGB,iCCP,bKGD,pHYs,sBIT,tIME,oFFs,acTL,fcTL,fdAT,prVW,mkBF,mkTS,mkBS,mkBT" atIndex:0];
    }

    NSInteger actualIterations = iterations;

    NSString *filters = @"--filters=0pme";

    if ([file isLarge]) {
        actualIterations = 5 + actualIterations/3; // use faster setting for large files
        filters = @"--filters=p";
    }

    if (alternativeStrategy) {
        timelimit *= 1.4;
        filters = @"--filters=bp";
    } else {
        timelimit *= 0.8;
    }

    [args insertObject:filters atIndex:0];

    if (actualIterations) {
        [args insertObject:[NSString stringWithFormat:@"--iterations=%d", (int)actualIterations] atIndex:0];
    }

    [args insertObject:[NSString stringWithFormat:@"--timelimit=%lu", timelimit] atIndex:0];

    if (![self taskForKey:@"Zopfli" bundleName:@"zopflipng" arguments:args]) {
        return NO;
    }

    NSPipe *commandPipe = [NSPipe pipe];
    NSFileHandle *commandHandle = [commandPipe fileHandleForReading];

    [task setStandardOutput: commandPipe];
    [task setStandardError: commandPipe];

    [self launchTask];

    [commandHandle readInBackgroundAndNotify];
    BOOL ok = [self waitUntilTaskExit];

    [commandHandle closeFile];

    if (!ok) return NO;

    NSInteger fileSizeOptimized = [File fileByteSize:temp];
    if (fileSizeOptimized > 70) {
        return [file setFilePathOptimized:temp size:fileSizeOptimized toolName:@"Zopfli"];
    }
    return NO;
}

-(BOOL)isIdempotent {
    return NO;
}

-(BOOL)makesNonOptimizingModifications {
    return YES;
}

@end
