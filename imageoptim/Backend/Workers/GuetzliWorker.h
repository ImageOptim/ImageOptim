//
//  GuetzliWorker.h
//  ImageOptim
//
//  Created by Peter Kovacs on 3/17/17.
//
//

#ifndef GuetzliWorker_h
#define GuetzliWorker_h

#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface GuetzliWorker : CommandWorker {
    NSInteger level;
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults file:(Job *)aFile;
@end

#endif /* GuetzliWorker_h */
