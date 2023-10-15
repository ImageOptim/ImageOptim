
#import "CommandWorker.h"

@interface SvgcleanerWorker : CommandWorker {
    BOOL useLossy;
}

- (instancetype)initWithLossy:(BOOL)lossy job:(Job *)f;

@end
