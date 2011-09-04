
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

@interface DragDropImageView : NSImageView
{
    BOOL highlight;//highlight the drop zone
}
- (id)initWithCoder:(NSCoder *)coder;
@end
