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

    // Decode AVIF to temp PNG
    NSURL *pngTemp = [[temp URLByDeletingPathExtension] URLByAppendingPathExtension:@"png"];

    NSTask *decodeTask = [NSTask new];
    [decodeTask setLaunchPath:avifdecPath];
    [decodeTask setArguments:@[file.path.path, pngTemp.path]];
    @try {
        [decodeTask launch];
        [decodeTask waitUntilExit];
    } @catch (NSException *e) {
        IOWarn("avifdec failed: %@", e);
        return NO;
    }

    if ([decodeTask terminationStatus] != 0) {
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
    return [job setFileOptimized:[file tempCopyOfPath:temp] toolName:toolName];
}

@end
