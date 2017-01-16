
#import "SvgoWorker.h"
#import "../Job.h"
#import "../TempFile.h"
#import "../../log.h"

@implementation SvgoWorker

- (NSInteger)settingsIdentifier {
    return 2;
}

- (BOOL)optimizeFile:(File *)file toTempPath:(NSURL *)temp {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *scriptPath = [bundle pathForResource:@"svgo" ofType:@"js"];
    if (!scriptPath) {
        return NO;
    }

    NSArray *args = @[
        scriptPath,
        file.path.path,
        temp.path
    ];

    NSString *nodePath = @"/usr/local/bin/node";
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:nodePath]) {
        IOWarn(@"Node not installed at %@", nodePath);
        return NO;
    }

    [self taskWithPath:nodePath arguments:args];

    [self launchTask];
    
    BOOL ok = [self waitUntilTaskExit];
    if (!ok) return NO;

    return [job setFileOptimized:[file tempCopyOfPath:temp] toolName:@"SVGO"];
}

@end
