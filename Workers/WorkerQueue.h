//
//  WorkerQueue.h
//  ImageOptim
//
//  Created by porneL on 29.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class Worker;

@interface WorkerQueue : NSObject {
	NSMutableArray *runningWorkers;
	NSMutableArray *queuedWorkers;
	
	int maxWorkersCount;
	int runningWorkersCount;
	
	BOOL isAsync;
	
	NSLock *workersLock;
}
-(id)initWithMaxWorkers:(int)max isAsync:(BOOL)async;

-(void)addWorker:(Worker *)w;
-(void)workerHasFinished:(Worker *)w;


-(void)setMaxWorkersCount:(int)i;


-(void)threadEntry:(Worker *)w;

@end
