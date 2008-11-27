//
//  PngoutWorker.h
//
//  Created by porneL on 29.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface PngoutWorker : CommandWorker {
	int fileSizeOptimized;
}


-(BOOL)makesNonOptimizingModifications;

@end
