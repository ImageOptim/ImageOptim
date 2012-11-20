//
//  Worker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "Worker.h"

@implementation Worker

-(NSObject <WorkerQueueDelegate>*)delegate
{
	return nil;
}

-(BOOL)isRelatedTo:(File *)unused
{
	return NO;
}

-(void)main {
	assert([self delegate]);
    [[self delegate] workerHasStarted:self];
    @try {
        [self run]; 
    }
    @catch (NSException *exception) {
        NSLog(@"Caught %@: %@ %@", [exception name], [exception  reason], self);
    }
    @finally {        
		assert([self delegate]);
        [[self delegate] workerHasFinished:self];        
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
            [self className],(unsigned int)[self hash],[self isReady],[self isExecuting],[self delegate]];
}

@end
