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
    NSOperation *nextOperation;
    File *file;
    int fileType;
}

// nextOperation will make given operation high priority after this one finishes,
// which can be used to cause domino effect and process operations in order for each file
// as long as there are more queued operations than processing threads.
@property (atomic,retain) NSOperation *nextOperation;
@property (atomic, retain) File *file;

-(id)initWithFile:(File *)aFile;

-(BOOL)isRelatedTo:(File *)f;

-(BOOL)makesNonOptimizingModifications;

-(void)run;
@end
