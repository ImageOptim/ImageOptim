//
//  AdvCompWorker.h
//
//  Created by porneL on 30.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface GifsicleWorker : CommandWorker {
    BOOL interlace;
}

- (instancetype)initWithInterlace:(BOOL)yn file:(File *)aFile;
@end
