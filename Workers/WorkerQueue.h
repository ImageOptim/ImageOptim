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
-(void)workersHaveFinished:(WorkerQueue *)q;
@end

@interface WorkerQueue : NSObject {
	NSMutableArray *runningWorkers;
	NSMutableArray *queuedWorkers;
	
	int maxWorkersCount;
	
	BOOL isAsync;
	
	id <WorkerQueueDelegate> delegate;
	
	NSLock *workersLock;
}
-(id)initWithMaxWorkers:(int)max isAsync:(BOOL)async delegate:(id <WorkerQueueDelegate>)d;

-(void)addWorker:(Worker *)w after:(Worker *)a;

-(void)runWorkers;

-(void)setMaxWorkersCount:(int)i;
-(void)workerHasFinished:(Worker *)w; // not a delegate method
-(void)threadEntry:(Worker *)w;

@end
