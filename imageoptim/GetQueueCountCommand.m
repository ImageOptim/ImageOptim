#import "GetQueueCountCommand.h"
#import "ImageOptimController.h"
#import "FilesController.h"

@implementation GetQueueCountCommand

- (id)performDefaultImplementation {
    ImageOptimController *imageoptim = (ImageOptimController *)[[NSApplication sharedApplication] delegate];

    return imageoptim.filesController.queueCount;
}

@end
