
#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface PngquantWorker : CommandWorker {
    NSUInteger minQuality;
}

-(id)initWithFile:(File*)f minQuality:(NSUInteger)aMinQ;
-(BOOL)makesNonOptimizingModifications;

@end
