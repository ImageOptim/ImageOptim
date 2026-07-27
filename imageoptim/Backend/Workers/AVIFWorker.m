#import "AVIFWorker.h"
#import "../Job.h"
#import "../TempFile.h"
#import "../../log.h"

@implementation AVIFWorker

- (NSInteger)settingsIdentifier {
    return quality * 2 + lossy;
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults file:(Job *)aFile {
    if (self = [super initWithFile:aFile]) {
        lossy = [defaults boolForKey:@"LossyEnabled"];
        quality = lossy ? [defaults integerForKey:@"AvifQuality"] : 100;
        if (quality <= 0) quality = 85;
    }
    return self;
}

- (BOOL)makesNonOptimizingModifications {
    return lossy && quality < 100;
}

- (BOOL)hasGainMapAtPath:(NSString *)path decoderPath:(NSString *)avifdecPath {
    [self taskWithPath:avifdecPath arguments:@[@"--info", path]];
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    [self launchTask];
    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    if (![self waitUntilTaskExit]) {
        return YES; // Do not risk changing files whose auxiliary data cannot be inspected
    }

    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    return [output rangeOfString:@" * Gain map       : Absent"].location == NSNotFound;
}

- (BOOL)optimizeFile:(File *)file toTempPath:(NSURL *)temp {
    if (file->isAnimated) {
        return NO; // Animated AVIF cannot be safely re-encoded via PNG
    }

    NSString *avifdecPath = [self pathForExecutableName:@"avifdec"];
    NSString *avifencPath = [self pathForExecutableName:@"avifenc"];

    if (!avifdecPath || !avifencPath) {
        IOWarn("avifenc/avifdec not found in bundle");
        [job setError:@"AVIF tools not found"];
        return NO;
    }

    if ([self hasGainMapAtPath:file.path.path decoderPath:avifdecPath]) {
        return NO; // PNG cannot preserve AVIF gain maps
    }

    // Decode AVIF to temp PNG
    NSURL *pngTemp = [[temp URLByDeletingPathExtension] URLByAppendingPathExtension:@"png"];

    BOOL decoded = NO;
    @try {
        [self taskWithPath:avifdecPath arguments:@[file.path.path, pngTemp.path]];
        [self launchTask];
        decoded = [self waitUntilTaskExit];
    } @catch (NSException *e) {
        IOWarn("avifdec failed: %@", e);
        return NO;
    }

    if (!decoded || [self isCancelled]) {
        [[NSFileManager defaultManager] removeItemAtURL:pngTemp error:nil];
        return NO;
    }

    // Re-encode to AVIF
    NSMutableArray *args = [NSMutableArray array];
    if (lossy && quality < 100) {
        [args addObjectsFromArray:@[@"-q", [NSString stringWithFormat:@"%ld", (long)quality]]];
    } else {
        [args addObjectsFromArray:@[@"--lossless"]];
    }
    [args addObjectsFromArray:@[@"-s", @"4", pngTemp.path, temp.path]];

    [self taskWithPath:avifencPath arguments:args];
    [self launchTask];
    BOOL success = [self waitUntilTaskExit];

    [[NSFileManager defaultManager] removeItemAtURL:pngTemp error:nil];

    if (!success) {
        return NO;
    }

    NSString *toolName = (lossy && quality < 100)
        ? [NSString stringWithFormat:@"AVIF %ld%%", (long)quality]
        : @"AVIF";
    TempFile *output = [file tempCopyOfPath:temp];
    if (!output) {
        return NO;
    }
    if ([self makesNonOptimizingModifications] && output.byteSize > file.byteSize * 0.95) {
        return NO; // Require at least 5% savings when degrading the image
    }
    return [job setFileOptimized:output toolName:toolName];
}

@end
