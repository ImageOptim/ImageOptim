#import "TaskStateCell.h"

@implementation TaskStateCell

- (NSColor *)badgeColorForState:(NSString *)state {
    if ([state isEqualToString:NSLocalizedString(@"Failed", @"task state")]) {
        return NSColor.systemRedColor;
    }
    if ([state isEqualToString:NSLocalizedString(@"Optimized", @"task state")]) {
        return NSColor.systemGreenColor;
    }
    if ([state isEqualToString:NSLocalizedString(@"No change", @"task state")]) {
        return NSColor.systemBlueColor;
    }
    if ([state isEqualToString:NSLocalizedString(@"Queued", @"task state")]) {
        return NSColor.systemGrayColor;
    }
    return NSColor.controlAccentColor;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSString *state = self.stringValue ?: @"";
    if (!state.length) {
        return;
    }

    NSFont *font = [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold];
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = NSTextAlignmentCenter;
    style.lineBreakMode = NSLineBreakByTruncatingTail;

    NSColor *badgeColor = [self badgeColorForState:state];
    NSDictionary *attributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: badgeColor,
        NSParagraphStyleAttributeName: style,
    };

    CGFloat targetWidth = ceil([state sizeWithAttributes:attributes].width) + 18;
    NSRect badgeRect = NSInsetRect(cellFrame, 6, 5);
    badgeRect.size.width = MIN(NSWidth(badgeRect), MAX(54, targetWidth));
    badgeRect.origin.y = NSMidY(cellFrame) - 10;
    badgeRect.size.height = 20;

    NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeRect xRadius:10 yRadius:10];
    [[badgeColor colorWithAlphaComponent:0.13] setFill];
    [badgePath fill];

    [[badgeColor colorWithAlphaComponent:0.22] setStroke];
    [badgePath setLineWidth:1];
    [badgePath stroke];

    NSRect textRect = NSInsetRect(badgeRect, 8, 0);
    textRect.origin.y += floor((NSHeight(textRect) - font.capHeight) / 2) - 2;
    [state drawWithRect:textRect options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
}

@end
