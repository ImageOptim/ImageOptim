
#import "CommandWorker.h"

@interface ZopfliWorker : CommandWorker {
    int iterations;
    BOOL strip, alternativeStrategy;
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults file:(File *)aFile;
@property (atomic, assign) BOOL alternativeStrategy;

@end
