#import "WebPWorker.h"
#import "../Job.h"
#import "../TempFile.h"
#import "../../log.h"

@implementation WebPWorker

- (NSInteger)settingsIdentifier {
    return quality * 2 + lossy;
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults file:(Job *)aFile {
    if (self = [super initWithFile:aFile]) {
        lossy = [defaults boolForKey:@"LossyEnabled"];
        quality = lossy ? [defaults integerForKey:@"WebpQuality"] : 100;
        if (quality <= 0) quality = 85;
    }
    return self;
}

- (BOOL)makesNonOptimizingModifications {
    return lossy && quality < 100;
}

- (BOOL)optimizeFile:(File *)file toTempPath:(NSURL *)temp {
    if (file->isAnimated) {
        return NO; // Animated WebP cannot be safely re-encoded via PNG
    }

    NSString *dwebpPath = [self pathForExecutableName:@"dwebp"];
    NSString *cwebpPath = [self pathForExecutableName:@"cwebp"];

    if (!dwebpPath || !cwebpPath) {
        IOWarn("cwebp/dwebp not found in bundle");
        [job setError:@"WebP tools not found"];
        return NO;
    }

    // Decode WebP to temp PNG
    NSURL *pngTemp = [[temp URLByDeletingPathExtension] URLByAppendingPathExtension:@"png"];

    NSTask *decodeTask = [NSTask new];
    [decodeTask setLaunchPath:dwebpPath];
    [decodeTask setArguments:@[file.path.path, @"-o", pngTemp.path]];
    @try {
        [decodeTask launch];
        [decodeTask waitUntilExit];
    } @catch (NSException *e) {
        IOWarn("dwebp failed: %@", e);
        return NO;
    }

    if ([decodeTask terminationStatus] != 0) {
        [[NSFileManager defaultManager] removeItemAtURL:pngTemp error:nil];
        return NO;
    }

    // Re-encode to WebP
    NSMutableArray *args = [NSMutableArray array];
    if (lossy && quality < 100) {
        [args addObjectsFromArray:@[@"-q", [NSString stringWithFormat:@"%ld", (long)quality]]];
    } else {
        [args addObject:@"-lossless"];
    }
    [args addObjectsFromArray:@[@"-m", @"6", @"-mt", pngTemp.path, @"-o", temp.path]];

    [self taskWithPath:cwebpPath arguments:args];
    [self launchTask];
    BOOL success = [self waitUntilTaskExit];

    [[NSFileManager defaultManager] removeItemAtURL:pngTemp error:nil];

    if (!success) {
        return NO;
    }

    NSString *toolName = (lossy && quality < 100)
        ? [NSString stringWithFormat:@"WebP %ld%%", (long)quality]
        : @"WebP";
    return [job setFileOptimized:[file tempCopyOfPath:temp] toolName:toolName];
}

@end
