//
//  Worker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "Worker.h"
#import "Job.h"
#import "log.h"

@implementation Worker

@synthesize job, nextOperation;

-(NSInteger)settingsIdentifier {
    return 0;
}

-(instancetype)initWithFile:(Job *)aFile {
    if (self = [super init]) {
        self.job = aFile;
    }
    return self;
}

-(BOOL)isRelatedTo:(Job *)f {
    return (f == job);
}

-(BOOL)canSkip {

    if (![self isIdempotent]) return NO;

    NSDictionary *resultsBySettings;
    @synchronized(job) {
        resultsBySettings = (job.workersPreviousResults)[[self className]];
    }
    if (!resultsBySettings) return NO;

    NSNumber *previousResult = resultsBySettings[@([self settingsIdentifier])];
    if (!previousResult) return NO;

    return job.byteSizeOptimized == [previousResult integerValue];
}

-(void)markResultForSkipping {
    @synchronized(job) {
        NSMutableDictionary *resultsBySettings = (job.workersPreviousResults)[[self className]];
        if (!resultsBySettings) {
            resultsBySettings = [NSMutableDictionary new];
            (job.workersPreviousResults)[[self className]] = resultsBySettings;
        }
        resultsBySettings[@([self settingsIdentifier])] = @(job.byteSizeOptimized);
    }
}

-(void)main {
    [job updateStatusOfWorker:self running:YES];

    @try {
        if (![self isCancelled]) {
            if (![self canSkip]) {
                [self run];
                if (![self isCancelled] && !job.isFailed) {
                    [self markResultForSkipping];
                }
            } else {
                IODebug("Skipping %@, because it already optimized %@", [self className], job.fileName);
            }
        }
    }
    @finally {
        if (![self isCancelled]) {
            [nextOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
        }
        [job updateStatusOfWorker:self running:NO];
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
            [self className],(unsigned int)[self hash],[self isReady],[self isExecuting],job];
}

@end
