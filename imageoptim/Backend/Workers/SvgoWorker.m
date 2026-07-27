
#import "SvgoWorker.h"
#import "../Job.h"
#import "../TempFile.h"
#import "../../log.h"

@implementation SvgoWorker

- (instancetype)initWithLossy:(BOOL)lossy job:(Job *)f {
    if (self = [super initWithFile:f]) {
        useLossy = lossy;
    }
    return self;
}

- (NSInteger)settingsIdentifier {
    return useLossy ? 5 : 6;
}

+ (NSString *)nodeExecutablePath {
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *path in @[ @"/usr/local/bin/node", @"/opt/homebrew/bin/node" ]) {
        if ([fm isExecutableFileAtPath:path]) {
            return path;
        }
    }
    return nil;
}

- (BOOL)optimizeFile:(File *)file toTempPath:(NSURL *)temp {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *scriptPath = [bundle pathForResource:@"svgo" ofType:@"js"];
    if (!scriptPath) {
        IOWarn(@"Broken install, missing script");
        return NO;
    }

    NSArray *args = @[
        scriptPath,
        useLossy ? @"1" : @"0",
        file.path.path,
        temp.path
    ];

    NSString *nodePath = [SvgoWorker nodeExecutablePath];
    if (!nodePath) {
        IOWarn(@"Node not installed at /usr/local/bin/node or /opt/homebrew/bin/node");
        return NO;
    }

    [self taskWithPath:nodePath arguments:args];

    [self launchTask];

    BOOL ok = [self waitUntilTaskExit];
    if (!ok) return NO;

    return [job setFileOptimized:[file tempCopyOfPath:temp] toolName:useLossy ? @"SVGO" : @"SVGO lite"];
}

@end
