
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

    if ([file isLarge]) {
        actualIterations /= 2; // use faster setting for large files
    }

    if ([file isSmall]) {
        actualIterations *= 2;
        [args insertObject:@"--splitting=3" atIndex:0]; // try both splitting strategies
    } else if (alternativeStrategy) {
        [args insertObject:@"--splitting=2" atIndex:0]; // by default splitting=1, so make second run use different split
    }

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
    [task waitUntilExit];

    [commandHandle closeFile];

    if ([task terminationStatus]) return NO;

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
