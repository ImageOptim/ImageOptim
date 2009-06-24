//
//  Worker.h
//
//  Created by porneL on 30.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import "WorkerQueue.h";
#import "File.h";

@interface Worker : NSObject {
	Worker *dependsOn;
}

-(BOOL)isRelatedTo:(File *)f;

-(BOOL)makesNonOptimizingModifications;

-(id <WorkerQueueDelegate>)delegate;

-(void)run;
-(void)main;
-(void)addDependency:(Worker*)w;

@property (retain) Worker *dependsOn;
@end
