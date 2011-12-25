//
//  JpegoptimWorker.h
//
//  Created by porneL on 7.paź.07.
//

#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface JpegoptimWorker : CommandWorker {
    NSInteger maxquality;
    NSInteger fileSizeOptimized;
    BOOL strip;
}
@end
