#import "JXLWorker.h"
#import "../Job.h"
#import "../TempFile.h"
#import "../../log.h"

static BOOL HasMultipleDecodedFrames(NSString *pngPath) {
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

static void CleanupDecodedFrames(NSString *pngPath) {
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

- (BOOL)optimizeFile:(File *)file toTempPath:(NSURL *)temp {
    if (file->isAnimated) {
        return NO; // Animated JXL cannot be safely re-encoded via PNG
    }

    NSString *djxlPath = [self pathForExecutableName:@"djxl"];
    NSString *cjxlPath = [self pathForExecutableName:@"cjxl"];

    if (!djxlPath || !cjxlPath) {
        IOWarn("cjxl/djxl not found in bundle");
        [job setError:@"JPEG XL tools not found"];
        return NO;
    }

    // Decode JXL to temp PNG
    NSURL *pngTemp = [[temp URLByDeletingPathExtension] URLByAppendingPathExtension:@"png"];
    NSString *pngPath = pngTemp.path;

    NSTask *decodeTask = [NSTask new];
    [decodeTask setLaunchPath:djxlPath];
    [decodeTask setArguments:@[file.path.path, pngPath, @"--output_frames"]];
    @try {
        [decodeTask launch];
        [decodeTask waitUntilExit];
    } @catch (NSException *e) {
        IOWarn("djxl failed: %@", e);
        return NO;
    }

    if ([decodeTask terminationStatus] != 0) {
        CleanupDecodedFrames(pngPath);
        return NO;
    }

    if (HasMultipleDecodedFrames(pngPath)) {
        CleanupDecodedFrames(pngPath);
        return NO; // Animated JXL expands to multiple frame files with --output_frames
    }

    NSString *decodedFramePath = DecodedFramePath(pngPath);
    if (!decodedFramePath) {
        CleanupDecodedFrames(pngPath);
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

    CleanupDecodedFrames(pngPath);

    if (!success) {
        return NO;
    }

    NSString *toolName = (lossy && quality < 100)
        ? [NSString stringWithFormat:@"JPEG XL %ld%%", (long)quality]
        : @"JPEG XL";
    return [job setFileOptimized:[file tempCopyOfPath:temp] toolName:toolName];
}

@end
