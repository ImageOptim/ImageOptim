#import "CommandWorker.h"

@interface AVIFWorker : CommandWorker {
    NSInteger quality;
    BOOL lossy;
}

- (instancetype)initWithLossy:(BOOL)lossyEnabled defaults:(NSUserDefaults *)defaults file:(Job *)aFile;

@end
