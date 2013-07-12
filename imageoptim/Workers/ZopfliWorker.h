
#import "CommandWorker.h"

@interface ZopfliWorker : CommandWorker {
    int iterations;
    BOOL strip, alternativeStrategy;
}

@property (atomic, assign) BOOL alternativeStrategy;

@end
