//
//  AdvCompWorker.h
//
//  Created by porneL on 30.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface AdvCompWorker : CommandWorker {
    int level;
    
	int fileSizeOptimized;	
}

@end
