
#import "CommandWorker.h"

@interface SvgoWorker : CommandWorker {
    BOOL useLossy;
}

- (instancetype)initWithLossy:(BOOL)lossy job:(Job *)f;

// Path of the system-wide Node.js that SVGO needs, or nil when it isn't installed
+ (NSString *)nodeExecutablePath;

@end
