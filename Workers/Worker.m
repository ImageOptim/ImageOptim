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
-(id)initWithQueue:(WorkerQueue *)q
{
	if (self = [super init])
	{
		queue = [q retain];
	}
	return self;
}

-(id)delegate
{
	return nil;
}

-(void)dealloc
{
	[queue release];
	[super dealloc];
}


-(void)run
{
	NSLog(@"Run and did nothing %@",[self className]);
}


@end
