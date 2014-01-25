#import "GetQueueCountCommand.h"
#import "ImageOptim.h"
#import "FilesQueue.h"

@implementation GetQueueCountCommand

- (id)performDefaultImplementation {
    ImageOptim *imageoptim = (ImageOptim *)[[NSApplication sharedApplication] delegate];

    return imageoptim.filesQueue.queueCount;
}

@end
