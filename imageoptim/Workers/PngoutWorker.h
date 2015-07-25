//
//  PngoutWorker.h
//
//  Created by porneL on 29.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface PngoutWorker : CommandWorker {
    BOOL removechunks, interruptIfTakesTooLong;
    NSInteger level;
    
	NSInteger fileSizeOptimized;
}

- (instancetype)initWithLevel:(NSInteger)level defaults:(NSUserDefaults *)defaults file:(File *)aFile;
@property (readonly) BOOL makesNonOptimizingModifications;

@end
