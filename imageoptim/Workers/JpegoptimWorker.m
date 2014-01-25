//
//  JpegoptimWorker.m
//
//  Created by porneL on 7.paź.07.
//

#import "JpegoptimWorker.h"
#import "../File.h"
#import "../log.h"

@implementation JpegoptimWorker

-(id)settingsIdentifier {
    return @(maxquality*2+strip);
}

-(id)initWithFile:(File *)aFile {
    if (self = [super initWithFile:aFile])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        // Sharing setting with jpegtran
        strip = [defaults boolForKey:@"JpegTranStripAll"];

        maxquality = [defaults integerForKey:@"JpegOptimMaxQuality"];
    }
    return self;
}

-(BOOL)makesNonOptimizingModifications {
    return maxquality < 100;
}

-(BOOL)runWithTempPath:(NSString*)temp
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;

    if (![fm copyItemAtPath:[file filePath] toPath:temp error:&error])
    {
        IOWarn("Can't make temp copy of %@ in %@",[file filePath],temp);
    }

    NSMutableArray *args = [NSMutableArray arrayWithObjects: @"-q",@"--",temp,nil];


    if (strip) {
        [args insertObject:@"--strip-all" atIndex:0];
    }

    if (maxquality > 10 && maxquality < 100)
    {
        [args insertObject:[NSString stringWithFormat:@"-m%d",(int)maxquality] atIndex:0];
    }

    if (![self taskForKey:@"JpegOptim" bundleName:@"jpegoptim" arguments:args]) {
        return NO;
    }

    NSPipe *commandPipe = [NSPipe pipe];
    NSFileHandle *commandHandle = [commandPipe fileHandleForReading];

    [task setStandardOutput: commandPipe];
    [task setStandardError: commandPipe];

    [self launchTask];

    [self parseLinesFromHandle:commandHandle];

    [commandHandle readInBackgroundAndNotify];
    [task waitUntilExit];

    [commandHandle closeFile];

    BOOL isSignificantlySmaller;
    @synchronized(file) {
        // require at least 5% gain when doing lossy optimization
        isSignificantlySmaller = file.byteSizeOptimized*0.95 > fileSizeOptimized;
    }

    if (![self makesNonOptimizingModifications] || isSignificantlySmaller) {
        return [file setFilePathOptimized:temp size:fileSizeOptimized toolName:@"JpegOptim"];
    }
    return NO;
}

-(BOOL)parseLine:(NSString *)line
{
    NSInteger size;
    if ((size = [self readNumberAfter:@" --> " inLine:line]))
    {
        fileSizeOptimized = size;
        return YES;
    }
    return NO;
}


@end
