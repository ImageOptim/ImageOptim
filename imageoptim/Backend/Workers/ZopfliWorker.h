
#import "CommandWorker.h"

@interface ZopfliWorker : CommandWorker {
    NSInteger iterations, timelimit;
    BOOL strip, alternativeStrategy;
}

-(instancetype)initWithLevel:(NSInteger)aLevel defaults:(NSUserDefaults *)defaults file:(Job *)aFile;
@property (atomic, assign) BOOL alternativeStrategy;

@end
