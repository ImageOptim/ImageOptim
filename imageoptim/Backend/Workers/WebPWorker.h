#import "CommandWorker.h"

@interface WebPWorker : CommandWorker {
    NSInteger quality;
    BOOL lossy;
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults file:(Job *)aFile;

@end
