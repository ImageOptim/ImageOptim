//
//  Worker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "Worker.h"
#import "WorkerQueue.h"

@implementation Worker

@synthesize dependsOn;

-(id <WorkerQueueDelegate>)delegate
{
	return nil;
}

-(BOOL)isRelatedTo:(File *)f
{
	return NO;
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
	return [NSString stringWithFormat:@"%@ %X <dep %@>",[self className],[self hash],dependsOn];
}

-(void)dealloc 
{
//	NSLog(@"### Worker dealloc %@",[self className]);
	[dependsOn release]; dependsOn = nil;
	[super dealloc];
}

@end
