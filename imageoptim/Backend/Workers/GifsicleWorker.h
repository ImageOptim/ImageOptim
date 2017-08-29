//
//  AdvCompWorker.h
//
//  Created by porneL on 30.wrz.07.
//

@import Cocoa;
#import "CommandWorker.h"

@interface GifsicleWorker : CommandWorker {
    NSUInteger quality;
    BOOL interlace;
}

- (instancetype)initWithInterlace:(BOOL)yn quality:(NSUInteger)quality file:(Job *)aFile;
@end
