#import "JXLWorker.h"
#import "../Job.h"
#import "../TempFile.h"
#import "../../log.h"

/* djxl names the frames of a multi-frame file "<base>-<n>.<ext>" next to the
   output path it was given, so they're found by prefix and suffix. Detection
   and cleanup share this so they can't drift apart. */
static NSArray<NSString *> *DecodedFrameSiblingPaths(NSString *pngPath) {
    NSString *dirPath = [pngPath stringByDeletingLastPathComponent];
    NSString *framePrefix = [[[pngPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@"-"];
    NSString *frameSuffix = [@"." stringByAppendingString:[pngPath pathExtension]];

    NSMutableArray<NSString *> *paths = [NSMutableArray array];
    NSArray<NSString *> *entries = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
    for (NSString *entry in entries) {
        if ([entry hasPrefix:framePrefix] && [entry hasSuffix:frameSuffix]) {
            [paths addObject:[dirPath stringByAppendingPathComponent:entry]];
        }
    }
    return paths;
}

static BOOL HasAdditionalDecodedFiles(NSString *pngPath) {
    NSInteger frameCount = [[NSFileManager defaultManager] fileExistsAtPath:pngPath] ? 1 : 0;
    return frameCount + (NSInteger)DecodedFrameSiblingPaths(pngPath).count > 1;
}

/* jxlinfo -v names every container box it reads. The round trip rebuilds the
   container structure and the codestream itself, and Exif and XMP survive it
   because djxl writes them into the PNG and cjxl reads them back. Any other
   auxiliary box (JUMBF, a gain map, an application-defined box jxlinfo doesn't
   know) would be dropped, and dropping it also makes the file smaller, so the
   result would look like a win. A bare codestream has no boxes at all. */
static BOOL HasUnsupportedBoxes(NSString *jxlinfoOutput) {
    static NSSet<NSString *> *roundTrippableBoxTypes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /* "brob" is a Brotli-compressed metadata box; the loop below checks
           what it holds, because only Exif and XMP survive. */
        roundTrippableBoxTypes = [NSSet setWithObjects:@"JXL ", @"ftyp", @"jxlc", @"jxlp", @"jxll", @"Exif", @"xml ", @"brob", nil];
    });

    NSRange wholeOutput = NSMakeRange(0, jxlinfoOutput.length);
    NSRegularExpression *boxPattern =
        [NSRegularExpression regularExpressionWithPattern:@"^  type: \"(.{4})\"\n  size: [0-9]+\n  contents size: ([0-9]+)$"
                                                  options:NSRegularExpressionAnchorsMatchLines
                                                    error:nil];
    NSRegularExpression *metadataPattern =
        [NSRegularExpression regularExpressionWithPattern:@"^(?:Uncompressed|Brotli-compressed) (.{4}) metadata:"
                                                  options:NSRegularExpressionAnchorsMatchLines
                                                    error:nil];
    if (!boxPattern || !metadataPattern) {
        return YES;
    }

    for (NSTextCheckingResult *match in [boxPattern matchesInString:jxlinfoOutput options:0 range:wholeOutput]) {
        NSString *boxType = [jxlinfoOutput substringWithRange:[match rangeAtIndex:1]];
        if (![roundTrippableBoxTypes containsObject:boxType]) {
            return YES;
        }
        /* ftyp holds the major brand, the minor version and the list of
           compatible brands, four bytes each. cjxl writes a fresh standard one
           declaring "jxl " as the only compatible brand, so anything longer
           than those twelve bytes is a compatibility declaration the round trip
           would drop. */
        if ([boxType isEqualToString:@"ftyp"] &&
            [[jxlinfoOutput substringWithRange:[match rangeAtIndex:2]] integerValue] > 12) {
            return YES;
        }
    }
    for (NSTextCheckingResult *match in [metadataPattern matchesInString:jxlinfoOutput options:0 range:wholeOutput]) {
        NSString *boxType = [jxlinfoOutput substringWithRange:[match rangeAtIndex:1]];
        if (![boxType isEqualToString:@"Exif"] && ![boxType isEqualToString:@"xml "]) {
            return YES;
        }
    }
    return NO;
}

static NSString *DecodedFramePath(NSString *pngPath) {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:pngPath]) {
        return pngPath;
    }

    NSString *frame0Path = [NSString stringWithFormat:@"%@-0.%@",
                                                      [pngPath stringByDeletingPathExtension],
                                                      [pngPath pathExtension]];
    if ([fm fileExistsAtPath:frame0Path]) {
        return frame0Path;
    }

    return nil;
}

static void CleanupDecodedFiles(NSString *pngPath) {
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:pngPath error:nil];
    for (NSString *framePath in DecodedFrameSiblingPaths(pngPath)) {
        [fm removeItemAtPath:framePath error:nil];
    }
}

@implementation JXLWorker

- (NSInteger)settingsIdentifier {
    return quality;
}

/* Quality 100 re-encodes losslessly. Job decides when a lossy pass is allowed,
   so that starting an already-optimized file again can't degrade it twice. */
- (instancetype)initWithQuality:(NSInteger)aQuality file:(Job *)aFile {
    if (self = [super initWithFile:aFile]) {
        quality = aQuality;
    }
    return self;
}

- (BOOL)makesNonOptimizingModifications {
    return quality < 100;
}

/* A JXL is only safe to re-encode through PNG if PNG can hold all of its
   samples and the file carries nothing that the round trip would drop. */
- (BOOL)canRoundTripThroughPngAtPath:(NSString *)path infoPath:(NSString *)jxlinfoPath {
    [self taskWithPath:jxlinfoPath arguments:@[@"-v", path]];
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    if (![self launchTask]) {
        return NO;
    }
    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    if (![self waitUntilTaskExit]) {
        return NO;
    }

    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    if (!output) {
        return NO;
    }
    if ([output rangeOfString:@"JPEG bitstream reconstruction data"].location != NSNotFound) {
        /* The file was losslessly transcoded from a JPEG, and djxl can restore
           that JPEG bit-for-bit. Decoding to PNG and re-encoding would drop the
           reconstruction data for good, so leave the file alone. */
        return NO;
    }
    if ([output rangeOfString:@"Have animation: 0"].location == NSNotFound) {
        /* An animation can consist of a single frame, so the number of files
           djxl writes can't tell one apart from a still image. Re-encoding one
           would drop its frame durations and loop count. jxlinfo -v always
           reports this, so a missing line means the file wasn't understood. */
        return NO;
    }
    if ([output rangeOfString:@"Have preview: 0"].location == NSNotFound) {
        /* djxl writes only the main image, so re-encoding would drop the
           embedded preview — and the file would shrink by losing it, so the
           result would look like a win. Reported like the animation flag. */
        return NO;
    }
    if ([output rangeOfString:@"alpha premultiplied: 1"].location != NSNotFound) {
        /* PNG stores unassociated alpha, so djxl has to unpremultiply the
           colour samples and cjxl writes back a file with unassociated alpha.
           The rounding in between changes the samples, which the quality 100
           path presents as lossless. */
        return NO;
    }
    if (HasUnsupportedBoxes(output)) {
        return NO;
    }

    NSError *error = nil;
    NSRegularExpression *bitDepthPattern =
        [NSRegularExpression regularExpressionWithPattern:@"(?:, (?=[0-9]+-bit\\b)|bits per sample: )([0-9]+)(?:-bit\\b)?"
                                                   options:0
                                                     error:&error];
    if (!bitDepthPattern || error) {
        return NO;
    }

    NSArray<NSTextCheckingResult *> *matches =
        [bitDepthPattern matchesInString:output options:0 range:NSMakeRange(0, output.length)];
    if (!matches.count || [output rangeOfString:@"float ("].location != NSNotFound ||
        [output rangeOfString:@"float, with exponent_bits_per_sample:"].location != NSNotFound) {
        return NO;
    }
    for (NSTextCheckingResult *match in matches) {
        if ([[output substringWithRange:[match rangeAtIndex:1]] integerValue] > 16) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)optimizeFile:(File *)file toTempPath:(NSURL *)temp {
    if (file->isAnimated) {
        return NO; // Animated JXL cannot be safely re-encoded via PNG
    }

    NSString *djxlPath = [self pathForExecutableName:@"djxl"];
    NSString *cjxlPath = [self pathForExecutableName:@"cjxl"];
    NSString *jxlinfoPath = [self pathForExecutableName:@"jxlinfo"];

    if (!djxlPath || !cjxlPath || !jxlinfoPath) {
        IOWarn("cjxl/djxl/jxlinfo not found in bundle");
        [job setError:@"JPEG XL tools not found"];
        return NO;
    }

    if (![self canRoundTripThroughPngAtPath:file.path.path infoPath:jxlinfoPath]) {
        return NO; // PNG cannot preserve floating-point or greater-than-16-bit samples, nor JPEG reconstruction data
    }

    // Decode JXL to temp PNG
    NSURL *pngTemp = [[temp URLByDeletingPathExtension] URLByAppendingPathExtension:@"png"];
    NSString *pngPath = pngTemp.path;

    BOOL decoded = NO;
    @try {
        [self taskWithPath:djxlPath arguments:@[
            file.path.path,
            pngPath,
            @"--output_frames",
            @"--output_extra_channels"
        ]];
        decoded = [self launchTask] && [self waitUntilTaskExit];
    } @catch (NSException *e) {
        IOWarn("djxl failed: %@", e);
        CleanupDecodedFiles(pngPath);
        return NO;
    }

    if (!decoded || [self isCancelled]) {
        CleanupDecodedFiles(pngPath);
        return NO;
    }

    if (HasAdditionalDecodedFiles(pngPath)) {
        CleanupDecodedFiles(pngPath);
        return NO; // PNG cannot preserve animations or additional JXL channels
    }

    NSString *decodedFramePath = DecodedFramePath(pngPath);
    if (!decodedFramePath) {
        CleanupDecodedFiles(pngPath);
        return NO;
    }

    // Re-encode to JXL
    NSArray *args = @[@"-q", [NSString stringWithFormat:@"%ld", (long)quality],
                      @"-e", @"9", decodedFramePath, temp.path];

    BOOL success = NO;
    @try {
        [self taskWithPath:cjxlPath arguments:args];
        success = [self launchTask] && [self waitUntilTaskExit];
    } @catch (NSException *e) {
        IOWarn("cjxl failed: %@", e);
    }

    CleanupDecodedFiles(pngPath);

    if (!success) {
        return NO;
    }

    NSString *toolName = quality < 100
        ? [NSString stringWithFormat:@"JPEG XL %ld%%", (long)quality]
        : @"JPEG XL";
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
