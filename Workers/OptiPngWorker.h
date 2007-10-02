//
//  AdvCompWorker.h
//  ImageOptim
//
//  Created by porneL on 30.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface OptiPngWorker : CommandWorker {
	int idatSize;
	int fileSize;	
	int fileSizeOptimized;	
}

@end
