//
//  Worker.h
//
//  Created by porneL on 30.wrz.07.
//

#import <Cocoa/Cocoa.h>



@class Worker;
@class File;

@protocol WorkerQueueDelegate
-(void)workerHasFinished:(Worker *)w;
-(void)workerHasStarted:(Worker *)w;
@end


@interface Worker : NSOperation {

}

-(BOOL)isRelatedTo:(File *)f;

-(BOOL)makesNonOptimizingModifications;

-(NSObject <WorkerQueueDelegate> *)delegate;

-(void)run;
@end
