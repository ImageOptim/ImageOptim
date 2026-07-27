#import "CommandWorker.h"

@interface JXLWorker : CommandWorker {
    NSInteger quality;
}

- (instancetype)initWithQuality:(NSInteger)quality file:(Job *)aFile;

@end
