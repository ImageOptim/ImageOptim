//
//  GuetzliWorker.h
//  ImageOptim
//
//  Created by Peter Kovacs on 3/17/17.
//
//

#ifndef GuetzliWorker_h
#define GuetzliWorker_h

@import Cocoa;
#import "CommandWorker.h"

@interface GuetzliWorker : CommandWorker {
    NSInteger level;
    dispatch_queue_t queue;
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults serialQueue:(dispatch_queue_t)q file:(Job *)aFile;
@end

#endif /* GuetzliWorker_h */
