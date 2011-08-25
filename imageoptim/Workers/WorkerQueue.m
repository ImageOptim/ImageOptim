//
//  WorkerQueue.m
//
//  Created by porneL on 29.wrz.07.
//

#import "WorkerQueue.h"
#import "Worker.h";
#import "FilesQueue.h";

@interface WorkerQueue ()

-(void)runWorkers;
-(void)workerHasFinished:(Worker *)w; // not a delegate method
-(void)threadEntry:(Worker *)w;

@end


@implementation WorkerQueue
-(id)init
{
	if (self = [super init])
	{
		runningWorkers = [[NSMutableArray alloc] init];
		queuedWorkers =  [[NSMutableArray alloc] init];
		workersLock = [NSRecursiveLock new];
		owner = nil;
	}
	return self;
}

-(void)setMaxConcurrentOperationCount:(int)max {
    isAsync = (max>0);
    maxWorkersCount = MAX(1,max);
}

-(void)removeWorkersOf:(File *)file
{
	[workersLock lock];
	Worker *w;
	NSMutableArray *toRemove = [NSMutableArray new];

	for(w in runningWorkers)
		if ([w isRelatedTo:file])
			[toRemove addObject:file];

	[runningWorkers removeObjectsInArray:toRemove];

	for(w in queuedWorkers)
		if ([w isRelatedTo:file])
			[toRemove addObject:file];

	[queuedWorkers removeObjectsInArray:toRemove];

	[workersLock unlock];



}

-(void)runWorkers
{
	[workersLock lock];
	@try
	{
//		NSLog(@"Run workers in %@",self);


		BOOL keepRunning = NO;
		BOOL completelyFinished = NO;

		Worker *runWorker = NULL;
		do
		{
			int i,count;
				if([runningWorkers count] < maxWorkersCount && (count = [queuedWorkers count]))
				{
					for(i=0; i < [queuedWorkers count]; i++)
					{
						Worker *w = [queuedWorkers objectAtIndex:i];
						Worker *dependence;

						if (!(dependence = [w dependsOn]) || (NSNotFound == [runningWorkers indexOfObjectIdenticalTo:dependence] && NSNotFound == [queuedWorkers indexOfObjectIdenticalTo:dependence]))
						{
//							NSLog(@"runnable worker found %@",w);
							[runningWorkers addObject:w];
                            [queuedWorkers removeObjectAtIndex:i];
							/*[queuedWorkers replaceObjectAtIndex:i withObject:[queuedWorkers lastObject]];
							[queuedWorkers removeLastObject];*/

							runWorker = w;

//							NSLog(@"queue:%@",self);
							break;
						}
						else
						{
//							NSLog(@"worker %@ is not runnable, needs %@",w,dependence);
							/*int dependenceIndex = [queuedWorkers indexOfObjectIdenticalTo:dependence];
							if (dependenceIndex != NSNotFound && dependenceIndex > i)
							{
//								NSLog(@"Swapping %d with %d",i,dependenceIndex);
								[queuedWorkers replaceObjectAtIndex:i withObject:dependence];
								[queuedWorkers replaceObjectAtIndex:dependenceIndex withObject:w];
//								NSLog(@"queue:%@",self);
								continue;
							}*/
						}
					}
				}

				keepRunning = (runWorker && [runningWorkers count] < maxWorkersCount && [queuedWorkers count]);

				completelyFinished = !runWorker && [runningWorkers count] == 0 && [queuedWorkers count] == 0;

			if (runWorker)
			{
				if (isAsync)
				{
					[NSThread detachNewThreadSelector:@selector(threadEntry:) toTarget:self withObject:runWorker];
				}
				else
				{
					[self threadEntry:runWorker];
				}
				runWorker=NULL;
			}
		}
		while(keepRunning);

		if (completelyFinished)
		{
			[owner workersHaveFinished:self];
		}
	}
	@catch(NSException *e)
	{
		NSLog(@"RunWorkers failed: Exception %@ >> %@ << {{ %@ }}",[e name],e,[e userInfo]);
	}
	@finally
	{
		[workersLock unlock];
	}
}

-(void)addOperation:(Worker *)w
{
	[workersLock lock];

//	NSLog(@"Adding worker %@ in %@",w,self);
	[queuedWorkers addObject:w];

	[workersLock unlock];

	[self runWorkers];
}

-(void)workerHasFinished:(Worker *)w
{
    [w retain];
	[workersLock lock];
//		NSLog(@"Worker %@ finished",w);
		[runningWorkers removeObjectIdenticalTo:w];
        [w autorelease];
	[workersLock unlock];

	[self runWorkers];
}

-(void)threadEntry:(Worker *)w
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	NSLog(@"Worker %@ thread start",w);
	@try
	{
		[w main];
//		NSLog(@"worker's %@ [run] ended, starting delegate",w);
//		NSLog(@"worker's %@ [delegate workerHasFinished] finished",w);
	}
	@catch(NSException *e)
	{
//		NSLog(@"Thread failed: Exception %@ >> %@ << {{ %@ }}",[e name],e,[e userInfo]);
//		NSLog(@"Failed thread's (%@) worker: %@",self,w);
	}
	@finally {
		[self workerHasFinished:w];
		[pool release];
	}
//	NSLog(@"Worker %@ thread end",w);
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"queued: %@ running: %@",[queuedWorkers description],[runningWorkers description]];
}
-(NSArray*)operations {
    if ([queuedWorkers count]) return queuedWorkers;
    return runningWorkers;
}
-(void)dealloc
{
	[workersLock release]; workersLock = nil;
	[runningWorkers release]; runningWorkers = nil;
	[queuedWorkers release]; queuedWorkers = nil;
	[super dealloc];
}
@synthesize queuedWorkers;
@synthesize owner;
@end
