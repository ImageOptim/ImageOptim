//
//  PngCrushWorker.h
//  ImageOptim
//
//  Created by porneL on 1.paź.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface PngCrushWorker : CommandWorker {
	int firstIdatSize;	

}

-(BOOL)makesNonOptimizingModifications;
@end
