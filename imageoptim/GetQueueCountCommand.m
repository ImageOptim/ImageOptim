#import "GetQueueCountCommand.h"
#import "ImageOptimController.h"
#import "FilesQueue.h"

@implementation GetQueueCountCommand

- (id)performDefaultImplementation {
    ImageOptimController *imageoptim = (ImageOptimController *)[[NSApplication sharedApplication] delegate];

    return imageoptim.filesQueue.queueCount;
}

@end
