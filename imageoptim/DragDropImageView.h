
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

@interface DragDropImageView : NSView
{
    BOOL highlight; //highlight the drop zone
    BOOL smoothSizes; // use blurry fractional sizes for smooth animation during live resize
}

@end
