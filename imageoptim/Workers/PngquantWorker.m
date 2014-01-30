
#import "PngquantWorker.h"
#import "../File.h"
#import "../log.h"

@implementation PngquantWorker

-(id)initWithFile:(File*)f minQuality:(NSUInteger)aMinQ {
    if (self = [super initWithFile:f]) {
        minQuality = aMinQ;
    }
    return self;
}

-(id)settingsIdentifier {
    return @(minQuality);
}

-(BOOL)runWithTempPath:(NSURL *)temp {
    NSArray *args = @[@"256",@"--skip-if-larger",@"--quality",[NSString stringWithFormat:@"%d-100",(int)minQuality],@"-"];
    if (![self taskForKey:@"PngQuant" bundleName:@"pngquant" arguments:args]) {
        return NO;
    }

    NSError *err = nil;
    NSFileHandle *fileInputHandle = [NSFileHandle fileHandleForReadingFromURL:file.filePathOptimized error:&err];
    if (!fileInputHandle) {
        IOWarn("Can't read %@ %@",file.filePathOptimized.path, err);
        return NO;
    }

    [[NSData new] writeToURL:temp atomically:NO];
    NSFileHandle *fileOutputHandle = [NSFileHandle fileHandleForWritingToURL:temp error:&err];

    if (!fileOutputHandle) {
        IOWarn("Can't create %@ %@",temp.path, err);
        return NO;
    }

    NSPipe *commandPipe = [NSPipe pipe];
    NSFileHandle *commandHandle = [commandPipe fileHandleForReading];

    [task setStandardInput: fileInputHandle];
    [task setStandardOutput: fileOutputHandle];
    [task setStandardError: commandPipe];

    [self launchTask];
    [commandHandle readInBackgroundAndNotify];

    [task waitUntilExit];
    [commandHandle closeFile];
    [fileOutputHandle closeFile];

    int status = [task terminationStatus];
    // 98/99 == written 24-bit instead (which is fine too, because it applies color profiles)
    if (status == 99) {
        IODebug(@"pngquant skipped image due to low quality");
    }
    else if (status == 98) {
        IODebug(@"pngquant skipped image due to poor compression");
    }
    else if (status) {
        IODebug(@"pngquant error %d", status);
        return NO;
    }

    NSUInteger fileSizeOptimized = [File fileByteSize:temp];
    return [file setFilePathOptimized:temp size:fileSizeOptimized toolName:@"pngquant"];
}

-(BOOL)makesNonOptimizingModifications {
    return minQuality<100;
}

@end
