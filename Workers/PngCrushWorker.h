//
//  PngCrushWorker.h
//
//  Created by porneL on 1.paź.07.
//

#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface PngCrushWorker : CommandWorker {    
    NSArray *chunks;
    BOOL tryfix;
    
	int firstIdatSize;	

}

-(BOOL)makesNonOptimizingModifications;

@end
