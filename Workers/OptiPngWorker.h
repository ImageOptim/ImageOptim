//
//  AdvCompWorker.h
//
//  Created by porneL on 30.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface OptiPngWorker : CommandWorker {
    int optlevel, interlace;
    
    
	int idatSize;
	unsigned int fileSize;	
	unsigned int fileSizeOptimized;	
}
@end
