//
//  AdvCompWorker.h
//
//  Created by porneL on 30.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface OptiPngWorker : CommandWorker {
    NSInteger optlevel, interlace;


	NSInteger idatSize;
	NSUInteger fileSize;
	NSUInteger fileSizeOptimized;
}
@end
