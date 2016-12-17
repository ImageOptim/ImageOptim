
#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface PngquantWorker : CommandWorker {
    NSUInteger minQuality, speed;
}

-(id)initWithLevel:(NSInteger)level minQuality:(NSUInteger)aMinQ file:(Job*)f;
-(BOOL)makesNonOptimizingModifications;

@end
