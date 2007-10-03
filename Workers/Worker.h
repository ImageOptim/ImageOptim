//
//  Worker.h
//  ImageOptim
//
//  Created by porneL on 30.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class WorkerQueue;

@interface Worker : NSObject {
	Worker *dependsOn;
}

-(BOOL)makesNonOptimizingModifications;

-(id)delegate;

-(void)run;

-(Worker *)dependsOn;
-(void)setDependsOn:(Worker *)w;

@end
