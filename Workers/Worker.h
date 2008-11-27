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

-(Worker *)dependsOn;
-(void)setDependsOn:(Worker *)w;

@end
