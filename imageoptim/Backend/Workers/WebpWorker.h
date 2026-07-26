//
//  WebpWorker.h
//
//  Recompresses losslessly-compressed WebP images with a higher effort setting.
//

@import Cocoa;
#import "CommandWorker.h"

@interface WebpWorker : CommandWorker {
    NSInteger effort;
    BOOL strip;
}

- (instancetype)initWithLevel:(NSInteger)level stripMetadata:(BOOL)aStrip file:(Job *)aFile;
@end
