#import "GetQueueCountCommand.h"
#import "Utilities.h"


@implementation GetQueueCountCommand


- (id)performDefaultImplementation {
	
    
	return [Utilities utilitiesSharedSingleton].queueCount;
}

@end
