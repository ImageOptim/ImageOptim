
#import "RevealButtonCell.h"

// These defines should be on, and are simply for demo purposes
#define HIT_TEST 1
#define EDIT_FRAME 1
#define TRACKING 1
#define TRACKING_AREA 1


@implementation RevealButtonCell

- (instancetype)init {
    if ((self = [super init])) {
        [self setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    return self;
}


- (SEL)infoButtonAction {
    return iInfoButtonAction;
}

- (void)setInfoButtonAction:(SEL)action {
    iInfoButtonAction = action;
}

- (NSImage *)infoButtonImage {
    static NSImage *image;
    if (!image) image = [NSImage imageNamed:@"NSRevealFreestandingTemplate"];
    return image;
}

#define PADDING_BEFORE_IMAGE 2.0f
#define PADDING_BETWEEN_TITLE_AND_IMAGE 4.0f
#define VERTICAL_PADDING_FOR_IMAGE 0.0f
#define INFO_IMAGE_SIZE 14.0f
#define PADDING_AROUND_INFO_IMAGE 2.0f
#define IMAGE_SIZE 0.0f

- (NSImage *)infoButtonImageFaded {
    static NSImage *image;
    if (!image) {
        NSImage *opaqueImage = [self infoButtonImage];
        NSRect dimensions = NSMakeRect(0, 0, INFO_IMAGE_SIZE, INFO_IMAGE_SIZE);
        image = [[NSImage alloc] initWithSize:dimensions.size];
        [image lockFocus];
        [opaqueImage drawInRect:dimensions fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:0.3f respectFlipped:YES hints:nil];
        [image unlockFocus];
    }
    return image;
}


- (NSRect)rectForInfoButtonBasedOnTitleRect:(NSRect)titleRect inBounds:(NSRect)bounds {
    NSRect buttonRect = titleRect;

    //display at column right
    buttonRect.origin.x = NSMaxX(bounds) - INFO_IMAGE_SIZE-PADDING_BETWEEN_TITLE_AND_IMAGE;
    //display directly after text
    //buttonRect.origin.x = NSMaxX(titleRect) + PADDING_BETWEEN_TITLE_AND_IMAGE;
    buttonRect.origin.y += 2.0f;
    buttonRect.size.height = INFO_IMAGE_SIZE;
    buttonRect.size.width = INFO_IMAGE_SIZE;
    // Make sure it doesn't go past the bounds -- if so, we don't want to draw it.
    if (NSMaxX(buttonRect) - NSMaxX(bounds) > 0) {
        buttonRect = NSZeroRect;
    }
    //buttonRect.origin.x = round(buttonRect.origin.x);
    return buttonRect;
}

- (NSRect)infoButtonRectForBounds:(NSRect)bounds {
    NSRect titleRect = [self titleRectForBounds:bounds];
    return [self rectForInfoButtonBasedOnTitleRect:titleRect inBounds:bounds];
}

- (NSRect)titleRectForBounds:(NSRect)bounds {
    NSAttributedString *title = [self attributedStringValue];
    NSRect result = bounds;
    // The x origin is easy
    result.origin.x += PADDING_BEFORE_IMAGE + IMAGE_SIZE + PADDING_BETWEEN_TITLE_AND_IMAGE;
    // The y origin should be inline with the image
    result.origin.y += VERTICAL_PADDING_FOR_IMAGE;
    // Set the width and the height based on the texts real size. Notice the nil check! Otherwise, the resulting NSSize could be undefined if we messaged a nil object.
    if (title != nil) {
        result.size = [title size];
    } else {
        result.size = NSZeroSize;
    }
    // Now, we have to constrain us to the bounds. The max x we can go to has to be the same as the bounds, but minus the info image location
    CGFloat maxX = NSMaxX(bounds) - (PADDING_AROUND_INFO_IMAGE + INFO_IMAGE_SIZE + PADDING_AROUND_INFO_IMAGE);
    CGFloat maxWidth = maxX - NSMinX(result);
    if (maxWidth < 0) maxWidth = 0;
    // Constrain us to these bounds
    result.size.width = MIN(NSWidth(result), maxWidth);
    return result;
}

- (NSSize)cellSizeForBounds:(NSRect)bounds {
    NSSize result;
    // Figure out the natural cell size and confine it to the bounds given
    NSRect titleRect = [self titleRectForBounds:bounds];
    result.width = PADDING_BEFORE_IMAGE + IMAGE_SIZE + PADDING_BETWEEN_TITLE_AND_IMAGE + titleRect.size.width;
    // Add in spacing for the info image
    result.width += PADDING_AROUND_INFO_IMAGE + INFO_IMAGE_SIZE + PADDING_AROUND_INFO_IMAGE;
    result.height = VERTICAL_PADDING_FOR_IMAGE + IMAGE_SIZE + VERTICAL_PADDING_FOR_IMAGE;
    // Constrain it to the bounds passed in
    result.width = MIN(result.width, NSWidth(bounds));
    result.height = MIN(result.height, NSHeight(bounds));
    return result;
}

- (void)drawInteriorWithFrame:(NSRect)bounds inView:(NSView *)controlView {
    NSRect titleRect = [self titleRectForBounds:bounds];
    NSAttributedString *title = [self attributedStringValue];
    if ([title length] > 0) {
        [title drawInRect:titleRect];
    }

    NSRect infoButtonRect = [self infoButtonRectForBounds:bounds];

    if (iMouseHoveredInInfoButton || [self isHighlighted]) {
        float opacity = [self isHighlighted] ? 0.5f : 1.f;
        NSImage *opaqueImage = [self infoButtonImage];
        [opaqueImage drawInRect:infoButtonRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:opacity respectFlipped:YES hints:nil];
    } else {
        NSImage *fadedImage = [self infoButtonImageFaded];
        [fadedImage drawInRect:infoButtonRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.f respectFlipped:YES hints:nil];
    }
}

- (NSCellHitResult)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
    NSPoint point = [controlView convertPoint:[event locationInWindow] fromView:nil];

    NSRect titleRect = [self titleRectForBounds:cellFrame];
    if (NSMouseInRect(point, titleRect, [controlView isFlipped])) {
        return NSCellHitContentArea | NSCellHitEditableTextArea;
    }

    // How about the info button?
    NSRect infoButtonRect = [self infoButtonRectForBounds:cellFrame];
    if (NSMouseInRect(point, infoButtonRect, [controlView isFlipped])) {
        return NSCellHitContentArea | NSCellHitTrackableArea;
    }

    return NSCellHitNone;
}


+ (BOOL)prefersTrackingUntilMouseUp {
    // NSCell returns NO for this by default. If you want to have trackMouse:inRect:ofView:untilMouseUp: always track until the mouse is up, then you MUST return YES. Otherwise, strange things will happen.
    return YES;
}

// Mouse tracking -- the only part we want to track is the "info" button
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {

    NSRect infoButtonRect = [self infoButtonRectForBounds:cellFrame];
    while ([theEvent type] != NSEventTypeLeftMouseUp) {
        // This is VERY simple event tracking. We simply check to see if the mouse is in the "i" button or not and dispatch entered/exited mouse events
        NSPoint point = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
        BOOL mouseInButton = NSMouseInRect(point, infoButtonRect, [controlView isFlipped]);
        if (iMouseDownInInfoButton != mouseInButton) {
            iMouseDownInInfoButton = mouseInButton;
            [controlView setNeedsDisplayInRect:cellFrame];
        }
        if ([theEvent type] == NSEventTypeMouseEntered || [theEvent type] == NSEventTypeMouseExited) {
            [NSApp sendEvent:theEvent];
        }
        // Note that we process mouse entered and exited events and dispatch them to properly handle updates
        theEvent = [[controlView window] nextEventMatchingMask:(NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged | NSEventMaskMouseEntered | NSEventMaskMouseExited)];
    }

    // Another way of implementing the above code would be to keep an NSButtonCell as an ivar, and simply call trackMouse:inRect:ofView:untilMouseUp: on it, if the tracking area was inside of it.

    if (iMouseDownInInfoButton) {
        // Send the action, and redisplay
        iMouseDownInInfoButton = NO;
        [controlView setNeedsDisplayInRect:cellFrame];
        if (iInfoButtonAction) {
            [NSApp sendAction:iInfoButtonAction to:[self target] from:controlView];
        }
    }

    // We return YES since the mouse was released while we were tracking. Not returning YES when you processed the mouse up is an easy way to introduce bugs!
    return YES;
}


// Mouse movement tracking -- we have a custom NSOutlineView subclass that automatically lets us add mouseEntered:/mouseExited: support to any cell!
- (void)addTrackingAreasForView:(NSView *)controlView inRect:(NSRect)cellFrame withUserInfo:(NSDictionary *)userInfo mouseLocation:(NSPoint)mouseLocation {
    NSRect infoButtonRect = [self infoButtonRectForBounds:cellFrame];

    NSTrackingAreaOptions options = NSTrackingEnabledDuringMouseDrag | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways;

    BOOL mouseIsInside = NSMouseInRect(mouseLocation, infoButtonRect, [controlView isFlipped]);
    if (mouseIsInside) options |= NSTrackingAssumeInside;

    if (iMouseHoveredInInfoButton != mouseIsInside) {
        iMouseHoveredInInfoButton = mouseIsInside;
        [controlView setNeedsDisplayInRect:cellFrame];
    }
    // We make the view the owner, and it delegates the calls back to the cell after it is properly setup for the corresponding row/column in the outlineview
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:infoButtonRect options:options owner:controlView userInfo:userInfo];
    [controlView addTrackingArea:area];
}

- (void)setMouseEntered:(BOOL)y {
    iMouseHoveredInInfoButton = y;
}

@end
