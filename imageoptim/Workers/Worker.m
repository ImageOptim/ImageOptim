//
//  Worker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "Worker.h"
#import "File.h"
#import "log.h"

@implementation Worker

@synthesize file, nextOperation;

-(NSInteger)settingsIdentifier {
    return 0;
}

-(instancetype)initWithFile:(File *)aFile {
    if (self = [self init]) {
        self.file = aFile;
    }
    return self;
}

-(BOOL)isRelatedTo:(File *)f {
    return (f == file);
}

-(BOOL)canSkip {

    if (![self isIdempotent]) return NO;

    NSDictionary *resultsBySettings;
    @synchronized(file) {
        resultsBySettings = (file.workersPreviousResults)[[self className]];
    }
    if (!resultsBySettings) return NO;

    NSNumber *previousResult = resultsBySettings[@([self settingsIdentifier])];
    if (!previousResult) return NO;

    return file.byteSizeOptimized == [previousResult integerValue];
}

-(void)markResultForSkipping {
    @synchronized(file) {
        NSMutableDictionary *resultsBySettings = (file.workersPreviousResults)[[self className]];
        if (!resultsBySettings) {
            resultsBySettings = [NSMutableDictionary new];
            (file.workersPreviousResults)[[self className]] = resultsBySettings;
        }
        resultsBySettings[@([self settingsIdentifier])] = @(file.byteSizeOptimized);
    }
}

-(void)main {
    [file updateStatusOfWorker:self running:YES];

    @try {
        if (![self isCancelled]) {
            if (![self canSkip]) {
                [self run];
                if (![self isCancelled]) [self markResultForSkipping];
            } else {
                IODebug("Skipping %@, because it already optimized %@", [self className], file.fileName);
            }
        }
    }
    @finally {
        if (![self isCancelled]) {
            [nextOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
        }
        [file updateStatusOfWorker:self running:NO];
    }
}

-(void)run {
}

-(BOOL)isIdempotent {
    return YES;
}

-(BOOL)makesNonOptimizingModifications {
    return NO;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@ %X ready %d, running %d, deleg %@",
            [self className],(unsigned int)[self hash],[self isReady],[self isExecuting],file];
}

@end
