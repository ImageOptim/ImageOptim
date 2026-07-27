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

// avifdec --info dump of the image, or nil if it could not be read
- (NSString *)infoForPath:(NSString *)path decoderPath:(NSString *)avifdecPath {
    [self taskWithPath:avifdecPath arguments:@[@"--info", path]];
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    if (![self launchTask]) {
        return nil;
    }
    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    if (![self waitUntilTaskExit]) {
        return nil;
    }

    return [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
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

    NSString *info = [self infoForPath:file.path.path decoderPath:avifdecPath];
    if (!info) {
        return NO; // Do not risk changing files whose auxiliary data cannot be inspected
    }
    if ([info rangeOfString:@" * Gain map       : Absent"].location == NSNotFound) {
        return NO; // PNG cannot preserve AVIF gain maps
    }
    // avifdec writes >8-bit images as 16-bit PNG, from which avifenc infers 12 bits,
    // so a 10-bit image has to be re-encoded at its original depth explicitly.
    const NSInteger depth = [self readNumberAfter:@" * Bit Depth      : " inLine:info];

    // Decode AVIF to temp PNG
    NSURL *pngTemp = [[temp URLByDeletingPathExtension] URLByAppendingPathExtension:@"png"];

    BOOL decoded = NO;
    @try {
        [self taskWithPath:avifdecPath arguments:@[file.path.path, pngTemp.path]];
        decoded = [self launchTask] && [self waitUntilTaskExit];
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
    if (depth == 10 || depth == 12) {
        [args addObjectsFromArray:@[@"-d", [NSString stringWithFormat:@"%ld", (long)depth]]];
    }
    [args addObjectsFromArray:@[@"-s", @"4", pngTemp.path, temp.path]];

    [self taskWithPath:avifencPath arguments:args];
    BOOL success = [self launchTask] && [self waitUntilTaskExit];

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
