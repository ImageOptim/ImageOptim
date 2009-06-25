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

-(BOOL)isRelatedTo:(File *)f
{
	return NO;
}


-(void)main {
    [[self delegate] workerHasStarted:self];
    @try {
        [self run]; 
    }
    @finally {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WorkersMayHaveFinished" object:nil];
//                [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:@"WorkersMayHaveFinished" object:nil] 
//                                                           postingStyle:NSPostWhenIdle 
//                                                           coalesceMask:NSNotificationCoalescingOnName forModes:nil];
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
	return [NSString stringWithFormat:@"%@ %X",[self className],[self hash]];
}

@end
