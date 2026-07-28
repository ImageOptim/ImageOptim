#import "AVIFWorker.h"
#import "../Job.h"
#import "../TempFile.h"
#import "../../log.h"

@implementation AVIFWorker

- (NSInteger)settingsIdentifier {
    return quality * 2 + lossy;
}

- (instancetype)initWithLossy:(BOOL)lossyEnabled defaults:(NSUserDefaults *)defaults file:(Job *)aFile {
    if (self = [super initWithFile:aFile]) {
        lossy = lossyEnabled;
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
    if ([info rangeOfString:@" * Transformations: None"].location == NSNotFound) {
        // avifdec bakes clap/irot/imir into the decoded pixels and drops pasp entirely,
        // and avifenc recreates none of them, so the round-trip would alter the geometry
        return NO;
    }
    if ([info rangeOfString:@" * Alpha          : Premultiplied"].location != NSNotFound) {
        // PNG has no premultiplied form, so avifdec divides the colour out by the alpha
        // and avifenc writes the result back without the prem association: the samples
        // are no longer the ones a compositor can use directly
        return NO;
    }
    // An ICC profile survives verbatim in the PNG's iCCP chunk, but of the CICP values
    // only sRGB reliably does: avifdec always writes them to a cICP chunk, yet avifenc
    // reads that chunk back only when its libpng has cICP support, and the cHRM/gAMA it
    // falls back on is approximate, or absent for curves with no gamma (PQ, HLG).
    if ([info rangeOfString:@" * ICC Profile    : Present"].location == NSNotFound) {
        const NSInteger primaries = [self readNumberAfter:@" * Color Primaries: " inLine:info];
        const NSInteger transfer = [self readNumberAfter:@" * Transfer Char. : " inLine:info];
        if (primaries != 1 || transfer != 13) { // BT.709 primaries, sRGB transfer
            return NO;
        }
    }
    // avifdec writes >8-bit images as 16-bit PNG, from which avifenc infers 12 bits,
    // so a 10-bit image has to be re-encoded at its original depth explicitly.
    const NSInteger depth = [self readNumberAfter:@" * Bit Depth      : " inLine:info];
    if (depth > 8 && [self readNumberAfter:@" * Matrix Coeffs. : " inLine:info] != 0) {
        // At 8 bits the decoded RGB is exactly what the round-trip stores back, but a
        // deeper image is converted to 16-bit RGB first, and quantizing that down to the
        // original depth does not undo the YUV conversion for any matrix but identity.
        return NO;
    }

    // Decode AVIF to temp PNG
    NSURL *pngTemp = [[temp URLByDeletingPathExtension] URLByAppendingPathExtension:@"png"];

    BOOL decoded = NO;
    @try {
        [self taskWithPath:avifdecPath arguments:@[file.path.path, pngTemp.path]];
        decoded = [self launchTask] && [self waitUntilTaskExit];
    } @catch (NSException *e) {
        IOWarn("avifdec failed: %@", e);
        [[NSFileManager defaultManager] removeItemAtURL:pngTemp error:nil];
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
