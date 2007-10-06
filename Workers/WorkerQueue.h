//
//  WorkerQueue.h
//  ImageOptim
//
//  Created by porneL on 29.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class Worker;
@class WorkerQueue;

@protocol WorkerQueueDelegate
-(void)workerHasFinished:(Worker *)w;
-(void)workerHasStarted:(Worker *)w;
@end

@interface WorkerQueue : NSObject {
	NSMutableArray *runningWorkers;
	NSMutableArray *queuedWorkers;
	
	int maxWorkersCount;
	
	BOOL isAsync;	
	
	id owner;
	
	NSRecursiveLock *workersLock;
}

-(void)setOwner:(id)o;

-(id)initWithMaxWorkers:(int)max;

-(void)addWorker:(Worker *)w after:(Worker *)a;

-(void)runWorkers;

-(void)setMaxWorkersCount:(int)i;
-(void)workerHasFinished:(Worker *)w; // not a delegate method
-(void)threadEntry:(Worker *)w;
-(BOOL)hasFinished;
@end
