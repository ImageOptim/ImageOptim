//
//  Worker.h
//
//  Created by porneL on 30.wrz.07.
//

@import Cocoa;

@class Worker;
@class Job;

@interface Worker : NSOperation {
    NSOperation *nextOperation;
    Job *job;
    int fileType;
}

// nextOperation will make given operation high priority after this one finishes,
// which can be used to cause domino effect and process operations in order for each file
// as long as there are more queued operations than processing threads.
@property (atomic, strong) NSOperation *nextOperation;
@property (atomic, strong) Job *job;

- (instancetype)initWithFile:(Job *)aFile;

- (BOOL)isRelatedTo:(Job *)f;

@property (readonly) BOOL makesNonOptimizingModifications;

- (void)run;

@property (readonly) NSInteger settingsIdentifier;
@property (getter=isIdempotent, readonly) BOOL idempotent;
@end
