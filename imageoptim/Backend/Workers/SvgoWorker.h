
#import "CommandWorker.h"

@interface SvgoWorker : CommandWorker {
    BOOL useLossy;
}

- (instancetype)initWithLossy:(BOOL)lossy job:(Job *)f;

@end
