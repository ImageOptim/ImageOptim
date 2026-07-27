#import "CommandWorker.h"

@interface AVIFWorker : CommandWorker {
    NSInteger quality;
    BOOL lossy;
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults file:(Job *)aFile;

@end
