//
//  PngoutWorker.h
//
//  Created by porneL on 29.wrz.07.
//

@import Cocoa;
#import "CommandWorker.h"

@interface PngoutWorker : CommandWorker {
    BOOL removechunks;
    NSInteger level, timelimit;

    NSInteger fileSizeOptimized;
}

- (instancetype)initWithLevel:(NSInteger)level defaults:(NSUserDefaults *)defaults file:(Job *)aFile;
@property (readonly) BOOL makesNonOptimizingModifications;

@end
