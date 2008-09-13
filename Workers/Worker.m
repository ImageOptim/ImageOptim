//
//  Worker.m
//  ImageOptim
//
//  Created by porneL on 30.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Worker.h"
#import "WorkerQueue.h"

@implementation Worker

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

-(void)setDependsOn:(Worker *)w
{
	if (dependsOn != w)
	{
		[dependsOn release];
		dependsOn = [w retain];		
	}
}

-(Worker *)dependsOn
{
	return dependsOn;
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
