#import <Cocoa/Cocoa.h>


/* This class implements a simple verb with no parameters.  The verb 
returns an integer number.  Verbs don't get much simpler than this. */

@interface GetQueueCountCommand : NSScriptCommand {
    
}

- (id)performDefaultImplementation;

@end
