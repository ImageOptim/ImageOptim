
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

    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *nodePath1 = @"/usr/local/bin/node";
    NSString *nodePath2 = @"/opt/homebrew/bin/node";
    NSString *nodePath;
    if ([fm isExecutableFileAtPath:nodePath1]) {
        nodePath = nodePath1;
    } else if ([fm isExecutableFileAtPath:nodePath2]) {
        nodePath = nodePath2;
    } else {
        IOWarn(@"Node not installed at %@", nodePath1);
        return NO;
    }

    [self taskWithPath:nodePath arguments:args];

    [self launchTask];

    BOOL ok = [self waitUntilTaskExit];
    if (!ok) return NO;

    return [job setFileOptimized:[file tempCopyOfPath:temp] toolName:useLossy ? @"SVGO" : @"SVGO lite"];
}

@end
