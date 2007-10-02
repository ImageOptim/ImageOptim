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

-(id)initWithMaxWorkers:(int)max isAsync:(BOOL)async
{
	if (self = [self init])
	{	
		isAsync = async;
		[self setMaxWorkersCount:max];
		runningWorkers = [[NSMutableArray alloc] init];
		queuedWorkers =  [[NSMutableArray alloc] init];
		runningWorkersCount=0;
		workersLock = [NSLock new];
	}
	return self;
}

-(void)setMaxWorkersCount:(int)m
{
	maxWorkersCount = m;
}

-(void)runWorkers
{	
	NSLog(@"Run workers");
	
	BOOL keepRunning = NO;
	Worker *runWorker = NULL;
	do
	{		
		[workersLock lock];	
		
			if(runningWorkersCount < maxWorkersCount && [queuedWorkers count])
			{
				Worker *w = [queuedWorkers lastObject];	
				
				[runningWorkers addObject:w];
				[queuedWorkers removeLastObject];
				
				runningWorkersCount++;
				runWorker = w;
			}	
			
			keepRunning = (runningWorkersCount < maxWorkersCount && [queuedWorkers count]);

		[workersLock unlock];
		
		if (runWorker)
		{
			NSLog(@"Taken worker %@ from queue",runWorker);
			if (isAsync) 
			{
				[NSThread detachNewThreadSelector:@selector(threadEntry:) toTarget:self withObject:runWorker];
			}
			else
			{
				[runWorker run];
				[self workerHasFinished:runWorker];
			}
			runWorker=NULL;
		}
	}
	while(keepRunning);
	
	NSLog(@"Run workers finished");
}

-(void)addWorker:(Worker *)w
{
	NSLog(@"Adding worker %@",w);
	[workersLock lock];
	
	[queuedWorkers addObject:w];
		
	[workersLock unlock];
}

-(void)workerHasFinished:(Worker *)w
{
	NSLog(@"Worker %@ finished",w);
	[workersLock lock];

		[w retain];
		[runningWorkers removeObjectIdenticalTo:w];
		runningWorkersCount--;
	
	[workersLock unlock];
	
	id delegate = [w delegate];
	if (delegate)
	{
		[delegate workerHasFinished:w];
	}
	[w release];
	
	[self runWorkers];
}

-(void)threadEntry:(Worker *)w
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[w run];
	[self workerHasFinished:w];
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
