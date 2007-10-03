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

-(id)initWithMaxWorkers:(int)max isAsync:(BOOL)async delegate:(id <WorkerQueueDelegate>)d
{
	if (self = [self init])
	{	
		delegate = d;
		isAsync = async;
		[self setMaxWorkersCount:max];
		runningWorkers = [[NSMutableArray alloc] init];
		queuedWorkers =  [[NSMutableArray alloc] init];
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
	NSLog(@"Run workers in %@ of %@",self,delegate);
	
	BOOL keepRunning = NO;
	BOOL completelyFinished = NO;
	int maxtries = [queuedWorkers count];
	
	Worker *runWorker = NULL;
	do
	{		
		[workersLock lock];	
		
			if([runningWorkers count] < maxWorkersCount && [queuedWorkers count])
			{
				Worker *w = [queuedWorkers lastObject];	
				Worker *dependence;
				
				if ((dependence = [w dependsOn]) && (NSNotFound != [runningWorkers indexOfObjectIdenticalTo:dependence] || NSNotFound != [queuedWorkers indexOfObjectIdenticalTo:dependence]))
				{
					NSLog(@"worker %@ is not ready, because %@ hasn't finished",w, dependence);
					[queuedWorkers insertObject:w atIndex:0];
					[queuedWorkers removeLastObject];
				}
				else
				{	
					NSLog(@"worker %@ is good to go",w);
					[runningWorkers addObject:w];
					[queuedWorkers removeLastObject];
					
					runWorker = w;										
				}
			}	
			
			keepRunning = (--maxtries && [runningWorkers count] < maxWorkersCount && [queuedWorkers count]);

			completelyFinished = !runWorker && [runningWorkers count] == 0 && [queuedWorkers count] == 0;
			
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
				[delegate workerHasFinished:runWorker];
			}
			runWorker=NULL;
		}
	}
	while(keepRunning);
	
	if (completelyFinished)
	{
		NSLog(@"no more pesky workers in %@ (%@/%@)!",self, queuedWorkers, runningWorkers);
		[delegate workersHaveFinished:self];
	}
	
	NSLog(@"Run workers finished");
}

-(void)addWorker:(Worker *)w after:(Worker *)dependence
{
	NSLog(@"Adding worker %@ in %@",w,self);
	
	[w setDependsOn:dependence];
	
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
	
	[workersLock unlock];
	
	[delegate workerHasFinished:w];

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
