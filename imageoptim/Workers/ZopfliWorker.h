
#import "CommandWorker.h"

@interface ZopfliWorker : CommandWorker {
    NSInteger iterations;
    BOOL strip, alternativeStrategy;
}

-(instancetype)initWithLevel:(NSInteger)aLevel defaults:(NSUserDefaults *)defaults file:(File *)aFile;
@property (atomic, assign) BOOL alternativeStrategy;

@end
