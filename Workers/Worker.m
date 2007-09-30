//
//  Worker.m
//  ImageOptim
//
//  Created by porneL on 30.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Worker.h"


@implementation Worker
-(id)initWithQueue:(WorkerQueue *)q
{
	if (self = [super init])
	{
		queue = [q retain];
	}
	return self;
}

-(void)dealloc
{
	[queue release];
	[super dealloc];
}



-(void)runAsync
{	
	[NSThread detachNewThreadSelector:@selector(threadEntry:) toTarget:self withObject:nil];
}

-(void)threadEntry
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self run];
	[pool release];
}


-(void)run
{
	/* stub */
}


@end
