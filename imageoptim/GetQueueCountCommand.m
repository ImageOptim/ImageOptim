#import "GetQueueCountCommand.h"
#import "ImageOptimController.h"
#import "FilesController.h"

@implementation GetQueueCountCommand

- (id)performDefaultImplementation {
    ImageOptimController *imageOptim = (ImageOptimController *)[[NSApplication sharedApplication] delegate];

    return imageOptim.filesController.queueCount;
}

@end
