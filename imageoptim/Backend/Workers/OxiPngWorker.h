//
//  AdvCompWorker.h
//
//  Created by porneL on 30.wrz.07.
//

@import Cocoa;
#import "CommandWorker.h"

@interface OxiPngWorker : CommandWorker {
    NSInteger optlevel;
    BOOL strip;

    NSInteger idatSize;
    NSUInteger fileSize;
    NSUInteger fileSizeOptimized;
}

- (instancetype)initWithLevel:(NSInteger)level stripMetadata:(BOOL)aStrip file:(Job *)aFile;
@end
