//
//  WebpWorker.m
//
//  Recompresses losslessly-compressed WebP images with a higher effort setting.
//
//  There is only one WebP encoder, so unlike PNG there is no second tool to
//  compete with. The gain comes purely from cwebp's -z level: most WebP files
//  in the wild were written at the default effort, and re-encoding them at the
//  maximum is lossless but noticeably smaller. Files that were already written
//  at a high effort barely shrink, which is fine — the result is only kept if
//  it is smaller.
//
//  Job.m only ever hands us files detected as FILETYPE_WEBP_LOSSLESS, so a
//  lossy bitstream can never reach this worker.
//

#import "WebpWorker.h"
#import "../Job.h"
#import "../TempFile.h"

@implementation WebpWorker

- (instancetype)initWithLevel:(NSInteger)level stripMetadata:(BOOL)aStrip file:(Job *)aJob {
    if (self = [super initWithFile:aJob]) {
        // cwebp's -z goes 0..9. The default it was probably written with is 6,
        // so anything below that would be pointless.
        effort = MAX(7, MIN(level + 5, 9));
        strip = aStrip;
    }
    return self;
}

- (NSInteger)settingsIdentifier {
    return effort * 2 + strip;
}

- (BOOL)optimizeFile:(File *)file toTempPath:(NSURL *)temp {
    // "-o" has to come before "--": cwebp treats the argument after "--" as
    // the input file and stops parsing, so a trailing "-o" would be swallowed
    // and it would exit 0 without writing anything.
    NSArray *args = @[ @"-quiet",
                       @"-lossless",
                       // Without this cwebp zeroes the RGB channels of fully
                       // transparent pixels. That is invisible when composited,
                       // but it destroys data in images that pack information
                       // under the alpha mask, so it is not lossless in the
                       // sense this tool promises.
                       @"-exact",
                       @"-z", [NSString stringWithFormat:@"%d", (int)effort],
                       @"-metadata", strip ? @"none" : @"all",
                       @"-o", temp.path,
                       @"--", file.path ];

    if (![self taskForKey:@"Webp" bundleName:@"cwebp" arguments:args]) {
        return NO;
    }

    NSFileHandle *devnull = [NSFileHandle fileHandleWithNullDevice];

    [task setStandardInput:devnull];
    [task setStandardError:devnull];
    [task setStandardOutput:devnull];

    [self launchTask];

    BOOL ok = [self waitUntilTaskExit];

    if (!ok) return NO;

    return [job setFileOptimized:[file tempCopyOfPath:temp] toolName:@"WebP"];
}

@end
