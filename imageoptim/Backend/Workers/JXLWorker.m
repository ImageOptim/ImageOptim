#import "JXLWorker.h"
#import "../Job.h"
#import "../TempFile.h"
#import "../../log.h"

static BOOL HasAdditionalDecodedFiles(NSString *pngPath) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dirPath = [pngPath stringByDeletingLastPathComponent];
    NSString *baseName = [[pngPath lastPathComponent] stringByDeletingPathExtension];
    NSString *extension = [pngPath pathExtension];
    NSString *framePrefix = [baseName stringByAppendingString:@"-"];
    NSString *frameSuffix = [@"." stringByAppendingString:extension];

    NSInteger frameCount = [fm fileExistsAtPath:pngPath] ? 1 : 0;
    NSArray<NSString *> *entries = [fm contentsOfDirectoryAtPath:dirPath error:nil];
    for (NSString *entry in entries) {
        if ([entry hasPrefix:framePrefix] && [entry hasSuffix:frameSuffix]) {
            frameCount++;
            if (frameCount > 1) {
                return YES;
            }
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
    NSString *dirPath = [pngPath stringByDeletingLastPathComponent];
    NSString *baseName = [[pngPath lastPathComponent] stringByDeletingPathExtension];
    NSString *extension = [pngPath pathExtension];
    NSString *framePrefix = [baseName stringByAppendingString:@"-"];
    NSString *frameSuffix = [@"." stringByAppendingString:extension];

    [fm removeItemAtPath:pngPath error:nil];
    NSArray<NSString *> *entries = [fm contentsOfDirectoryAtPath:dirPath error:nil];
    for (NSString *entry in entries) {
        if ([entry hasPrefix:framePrefix] && [entry hasSuffix:frameSuffix]) {
            [fm removeItemAtPath:[dirPath stringByAppendingPathComponent:entry] error:nil];
        }
    }
}

@implementation JXLWorker

- (NSInteger)settingsIdentifier {
    return quality * 2 + lossy;
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults file:(Job *)aFile {
    if (self = [super initWithFile:aFile]) {
        lossy = [defaults boolForKey:@"LossyEnabled"];
        quality = lossy ? [defaults integerForKey:@"JxlQuality"] : 100;
        if (quality <= 0) quality = 85;
    }
    return self;
}

- (BOOL)makesNonOptimizingModifications {
    return lossy && quality < 100;
}

- (BOOL)hasPngCompatibleSamplesAtPath:(NSString *)path infoPath:(NSString *)jxlinfoPath {
    [self taskWithPath:jxlinfoPath arguments:@[@"-v", path]];
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    [self launchTask];
    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    if (![self waitUntilTaskExit]) {
        return NO;
    }

    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    if (!output) {
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

    if (![self hasPngCompatibleSamplesAtPath:file.path.path infoPath:jxlinfoPath]) {
        return NO; // PNG cannot preserve floating-point or greater-than-16-bit samples
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
        [self launchTask];
        decoded = [self waitUntilTaskExit];
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
    NSMutableArray *args = [NSMutableArray array];
    if (lossy && quality < 100) {
        [args addObjectsFromArray:@[@"-q", [NSString stringWithFormat:@"%ld", (long)quality]]];
    } else {
        [args addObjectsFromArray:@[@"-q", @"100"]];
    }
    [args addObjectsFromArray:@[@"-e", @"9", decodedFramePath, temp.path]];

    [self taskWithPath:cjxlPath arguments:args];
    [self launchTask];
    BOOL success = [self waitUntilTaskExit];

    CleanupDecodedFiles(pngPath);

    if (!success) {
        return NO;
    }

    NSString *toolName = (lossy && quality < 100)
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
