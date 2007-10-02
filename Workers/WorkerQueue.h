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
	
	int runningWorkersCount;
	
	NSLock *workersLock;
	
	NSString *defaultsKey;
}
-(id)initWithDefaultsKey:(NSString *)key;

-(void)addWorker:(Worker *)w;
-(void)workerHasFinished:(Worker *)w;


-(void)runAsync:(Worker *)w;
-(void)threadEntry:(Worker *)w;

@end
