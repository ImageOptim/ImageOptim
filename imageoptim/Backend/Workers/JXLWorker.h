#import "CommandWorker.h"

@interface JXLWorker : CommandWorker {
    NSInteger quality;
    BOOL lossy;
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults file:(Job *)aFile;

@end
