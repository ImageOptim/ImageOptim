//
//  Worker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "Worker.h"

@implementation Worker

@synthesize file, nextOperation;

-(id)initWithFile:(File *)aFile
{
	if (self = [self init])
	{
		self.file = aFile;
	}
	return self;
}

-(BOOL)isRelatedTo:(File *)f
{
	return (f == file);
}

-(void)main {

    [file workerHasStarted:self];
    @try {
        if (![self isCancelled]) {
            [self run];
        }
    }
    @finally {
        [file workerHasFinished:self];
        [nextOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
    }
}

-(void)run
{
//	NSLog(@"Run and did nothing %@",[self className]);
}

-(BOOL)makesNonOptimizingModifications
{
	return NO;
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"%@ %X ready %d, running %d, deleg %@",
            [self className],(unsigned int)[self hash],[self isReady],[self isExecuting],file];
}

@end
