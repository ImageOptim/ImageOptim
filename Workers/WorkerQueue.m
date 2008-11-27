//
//  WorkerQueue.m
//
//  Created by porneL on 29.wrz.07.
//

#import "WorkerQueue.h"
#import "Worker.h";
#import "FilesQueue.h";

@implementation WorkerQueue
-(id)initWithMaxWorkers:(int)max
{
	if (self = [self init])
	{	
		isAsync = (max>0);
		[self setMaxWorkersCount:MAX(1,max)];
		runningWorkers = [[NSMutableArray alloc] init];
		queuedWorkers =  [[NSMutableArray alloc] init];
		workersLock = [NSRecursiveLock new];
		owner = nil;
	}
	return self;
}

-(void)setMaxWorkersCount:(int)m
{
	maxWorkersCount = m;
}

-(void)setOwner:(id)o
{
	owner = o;
}

-(BOOL)hasFinished
{
	BOOL res;
	[workersLock lock];
	res = [runningWorkers count]==0 && [queuedWorkers count]==0;
	[workersLock unlock];
	return res;
}


-(void)removeWorkersOf:(File *)file
{
	[workersLock lock];	
	NSEnumerator *enu;
	Worker *w;
	NSMutableArray *toRemove = [NSMutableArray new];
	
	enu = [runningWorkers objectEnumerator];
	while(w = [enu nextObject])
		if ([w isRelatedTo:file])
			[toRemove addObject:file];
	
	[runningWorkers removeObjectsInArray:toRemove];
	
	enu = [queuedWorkers objectEnumerator];
	while(w = [enu nextObject])
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
							[queuedWorkers replaceObjectAtIndex:i withObject:[queuedWorkers lastObject]];
							[queuedWorkers removeLastObject];
							
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

-(void)addWorker:(Worker *)w after:(Worker *)dependence
{	
	[workersLock lock];
	
	[w setDependsOn:dependence];	
//	NSLog(@"Adding worker %@ in %@",w,self);		
	[queuedWorkers addObject:w];
		
	[workersLock unlock];
}

-(void)workerHasFinished:(Worker *)w
{
	[workersLock lock];
//		NSLog(@"Worker %@ finished",w);

		[w retain];
		[runningWorkers removeObjectIdenticalTo:w];
	
	[w release];
	
	[workersLock unlock];
	
	[self runWorkers];
}

-(void)threadEntry:(Worker *)w
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	NSLog(@"Worker %@ thread start",w);
	@try
	{
		[[w delegate] workerHasStarted:w];
		[w run];
//		NSLog(@"worker's %@ [run] ended, starting delegate",w);
		[[w delegate] workerHasFinished:w];
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

-(void)dealloc
{
	[workersLock release]; workersLock = nil;
	[runningWorkers release]; runningWorkers = nil;
	[queuedWorkers release]; queuedWorkers = nil;
	[super dealloc];
}
@end
