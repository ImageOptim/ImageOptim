/*
    File:       DragDropImageView.m

    Contains:   A sample to demonstrate Drag and Drop with Images in Cocoa
*/

#import "DragDropImageView.h"
#import "ImageOptimController.h"
#import "FilesController.h"

@implementation DragDropImageView

- (void)awakeFromNib {
    [self registerForDraggedTypes:@[ NSFilenamesPboardType ]];
}

- (BOOL)allowsVibrancy {
    return NSAppKitVersionNumber >= NSAppKitVersionNumber10_10;
}

- (BOOL)isOpaque {
    return NSAppKitVersionNumber < NSAppKitVersionNumber10_10;
    ;
}

// Destination Operations
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    highlight = YES;
    [self setNeedsDisplay:YES];
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag {
    return NSDragOperationCopy; // send data as copy operation
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    highlight = NO; // remove highlight of the drop zone
    [self setNeedsDisplay:YES];
}

- (void)viewWillStartLiveResize {
    smoothSizes = YES;
    [super viewWillStartLiveResize];
}

- (void)drawRect:(NSRect)rect {
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10) {
        [[NSColor windowBackgroundColor] setFill];
    } else {
        [[NSColor clearColor] set];
    }
    NSRectFillUsingOperation(rect, NSCompositeSourceOver);

    NSColor *gray = [NSColor colorWithDeviceWhite:0 alpha:highlight ? 1.0/4.0 : 1.0/8.0];
    [gray set];
    [gray setFill];

    NSRect bounds = [self bounds];
    CGFloat size = MIN(bounds.size.width/4.0, bounds.size.height/1.5);
    CGFloat width = MAX(2.0, size/32.0);
    NSRect frame = NSMakeRect((bounds.size.width-size)/2.0, (bounds.size.height-size)/2.0, size, size);

    if (!smoothSizes) {
        width = round(width);
        size = ceil(size);
        frame = NSMakeRect(round(frame.origin.x) + ((int)width & 1) / 2.0, round(frame.origin.y) + ((int)width & 1) / 2.0, round(frame.size.width), round(frame.size.height));
    }

    [NSBezierPath setDefaultLineWidth:width];

    NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:size / 14.0 yRadius:size / 14.0];
    const CGFloat dash[2] = { size / 10.0, size / 16.0 };
    [p setLineDash:dash count:2 phase:2];
    [p stroke];

    NSBezierPath *r = [NSBezierPath bezierPath];
    CGFloat baseWidth=size/8.0, baseHeight = size/8.0, arrowWidth=baseWidth*2, pointHeight=baseHeight*3.0, offset=-size/8.0;
    [r moveToPoint:NSMakePoint(bounds.size.width/2.0 - baseWidth, bounds.size.height/2.0 + baseHeight - offset)];
    [r lineToPoint:NSMakePoint(bounds.size.width/2.0 + baseWidth, bounds.size.height/2.0 + baseHeight - offset)];
    [r lineToPoint:NSMakePoint(bounds.size.width/2.0 + baseWidth, bounds.size.height/2.0 - baseHeight - offset)];
    [r lineToPoint:NSMakePoint(bounds.size.width/2.0 + arrowWidth, bounds.size.height/2.0 - baseHeight - offset)];
    [r lineToPoint:NSMakePoint(bounds.size.width/2.0, bounds.size.height/2.0 - pointHeight - offset)];
    [r lineToPoint:NSMakePoint(bounds.size.width/2.0 - arrowWidth, bounds.size.height/2.0 - baseHeight - offset)];
    [r lineToPoint:NSMakePoint(bounds.size.width/2.0 - baseWidth, bounds.size.height/2.0 - baseHeight - offset)];
    [r fill];
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    highlight = NO; // finished with the drag so remove any highlighting
    [self setNeedsDisplay:YES];
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    if ([sender draggingSource] != self) {
        NSArray *files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
        [filesController performSelectorInBackground:@selector(addPaths:) withObject:files];
    }
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    return YES; // so source doesn't have to be the active window
}

@end
