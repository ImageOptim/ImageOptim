//
//  Worker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "Worker.h"

@implementation Worker
//@synthesize dependsOn;

-(NSObject <WorkerQueueDelegate>*)delegate
{
	return nil;
}

-(BOOL)isRelatedTo:(File *)unused
{
	return NO;
}

-(void)main {
//    NSLog(@"Worker start %@",self);
	assert([self delegate]);
    [[self delegate] workerHasStarted:self];
    @try {
        [self run];
    }
    @catch (NSException *exception) {
        NSLog(@"Caught %@: %@ %@", [exception name], [exception  reason], self);
    }
    @finally {
//                [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:@"WorkersMayHaveFinished" object:nil]
//                                                           postingStyle:NSPostWhenIdle
//                                                           coalesceMask:NSNotificationCoalescingOnName forModes:nil];
		assert([self delegate]);
        [[self delegate] workerHasFinished:self];
    }
//    NSLog(@"Worker done ok %@",self);
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
            [self className],[self hash],[self isReady],[self isExecuting],[self delegate]];
}

@end
