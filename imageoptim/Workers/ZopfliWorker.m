
#import "ZopfliWorker.h"
#import "../File.h"

@implementation ZopfliWorker

@synthesize alternativeStrategy;

-(id)init {
    if (self = [super init])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        iterations = [defaults integerForKey:@"ZopfliIterations"];
        strip = [[NSUserDefaults standardUserDefaults] boolForKey:@"PngOutRemoveChunks"];
    }
    return self;
}

-(void)run
{
	NSString *temp = [self tempPath];

	NSMutableArray *args = [NSMutableArray arrayWithObjects: @"--lossy_transparent",@"-y",/*@"--",*/[file filePath],temp,nil];

    if (!strip) {
        // FIXME: that's crappy. Should list actual chunks in file :/
        [args insertObject:@"--keepchunks=tEXt,zTXt,iTXt,gAMA,sRGB,iCCP,bKGD,pHYs,sBIT,tIME,oFFs,acTL,fcTL,fdAT,prVW,mkBF,mkTS,mkBS,mkBT" atIndex:0];
    }

    int actualIterations = iterations;
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
		[args insertObject:[NSString stringWithFormat:@"--iterations=%d", actualIterations] atIndex:0];
	}

    if (![self taskForKey:@"Zopfli" bundleName:@"zopflipng" arguments:args]) {
        return;
    }

	NSPipe *commandPipe = [NSPipe pipe];
	NSFileHandle *commandHandle = [commandPipe fileHandleForReading];

	[task setStandardOutput: commandPipe];
	[task setStandardError: commandPipe];

    [self launchTask];

    [commandHandle readInBackgroundAndNotify];
	[task waitUntilExit];

    [commandHandle closeFile];

    if ([self isCancelled]) return;

    NSInteger fileSizeOptimized = [File fileByteSize:temp];
	if (![task terminationStatus] && fileSizeOptimized > 70) {
		[file setFilePathOptimized:temp size:fileSizeOptimized toolName:@"Zopfli"];
	}
}

-(BOOL)makesNonOptimizingModifications {
    return YES;
}

@end
