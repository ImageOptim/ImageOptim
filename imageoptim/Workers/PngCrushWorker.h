//
//  PngCrushWorker.h
//
//  Created by porneL on 1.paź.07.
//

#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface PngCrushWorker : CommandWorker {    
	int firstIdatSize;	
    BOOL strip, brute;
}

- (instancetype)initWithLevel:(NSInteger)level defaults:(NSUserDefaults *)defaults file:(File *)aFile;
@property (readonly) BOOL makesNonOptimizingModifications;

@end
