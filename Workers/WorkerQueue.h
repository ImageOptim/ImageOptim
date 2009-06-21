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

-(id)initWithMaxWorkers:(int)max;

-(void)addWorker:(Worker *)w after:(Worker *)a;

-(void)runWorkers;

-(void)workerHasFinished:(Worker *)w; // not a delegate method
-(void)threadEntry:(Worker *)w;
-(BOOL)hasFinished;
@property (readonly,retain) NSMutableArray *runningWorkers;
@property (readonly,retain) NSMutableArray *queuedWorkers;
@property (assign,readonly) int maxWorkersCount;
@property (assign,readonly) BOOL isAsync;
@property (assign) id owner;
@property (retain,nonatomic) NSRecursiveLock *workersLock;
@end
