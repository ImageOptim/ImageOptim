//
//  WorkerQueue.m
//  ImageOptim
//
//  Created by porneL on 29.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "WorkerQueue.h"
#import "Worker.h";

@implementation WorkerQueue

#define MAX_WORKERS 3

-(id)init
{
	if (self = [super init])
	{		
		runningWorkers = [[NSMutableArray alloc] init];
		queuedWorkers =  [[NSMutableArray alloc] init];
		runningWorkersCount=0;
		workersLock = [NSLock new];
	}
	return self;
}

-(void)runWorkers
{	
	NSLog(@"Run workers");
	
	BOOL keepRunning = NO;
	Worker *runWorker = NULL;
	do
	{		
		[workersLock lock];	
		
			if(runningWorkersCount < MAX_WORKERS && [queuedWorkers count])
			{
				Worker *w = [queuedWorkers lastObject];	
				
				[runningWorkers addObject:w];
				[queuedWorkers removeLastObject];
				
				runningWorkersCount++;
				runWorker = w;
			}	
			
			keepRunning = (runningWorkersCount < MAX_WORKERS && [queuedWorkers count]);

		[workersLock unlock];
		
		if (runWorker)
		{
			NSLog(@"Taken worker %@ from queue",runWorker);
			[self runAsync:runWorker];
			runWorker=NULL;
		}
	}
	while(keepRunning);
	
	NSLog(@"Run workers finished");
}

-(void)addWorker:(Worker *)w
{
	NSLog(@"Adding worker");
	BOOL run = NO;
	[workersLock lock];
	
		if (runningWorkersCount < MAX_WORKERS)
		{
			[runningWorkers addObject:w];
			runningWorkersCount++;
			run = YES;
		}
		else
		{
			[queuedWorkers addObject:w];
		}	
		
	[workersLock unlock];
		
	if (run) 
	{
		NSLog(@"Can immediately run worker %@",w);
		[self runAsync:w];		
	}
	else NSLog(@"Queued worker %@ for later",w);
}

-(void)workerFinished:(Worker *)w
{
	NSLog(@"Worker %@ finished",w);
	[workersLock lock];

		[runningWorkers removeObjectIdenticalTo:w];
		runningWorkersCount--;
	
	[workersLock unlock];
	
	[self runWorkers];
}



-(void)runAsync:(Worker *)w
{	
	NSLog(@"Async start, %d workers",runningWorkersCount);
	[NSThread detachNewThreadSelector:@selector(threadEntry:) toTarget:self withObject:w];
}

-(void)threadEntry:(Worker *)w
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[w run];
	[self workerFinished:w];
	[pool release];
}

-(void)dealloc
{
	[workersLock release];
	[runningWorkers release];
	[queuedWorkers release];
	[super dealloc];
}
@end
