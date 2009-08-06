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

@property (nonatomic,assign) BOOL interlace;
@end
