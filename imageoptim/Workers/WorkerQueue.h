//
//  WorkerQueue.h
//
//  Created by porneL on 29.wrz.07.
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

-(void)setMaxConcurrentOperationCount:(int)max;
-(NSArray*)operations;
-(void)addOperation:(Worker *)w;

@property (readonly,retain) NSMutableArray *queuedWorkers;
@property (assign) id owner;
@end
