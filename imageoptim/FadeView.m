
#import "FadeView.h"

@implementation FadeView

- (void)awakeFromNib {
    [self setAlphaValue:1.0];
}

- (BOOL)allowsVibrancy {
    return NSAppKitVersionNumber >= NSAppKitVersionNumber10_10;
}

- (void)setHidden:(BOOL)flag {
    if (!flag) {
        [super setHidden:NO];
    }

    [self.animator setAlphaValue:flag ? 0 : 1];
}

- (BOOL)isHidden {
    return [super isHidden] || self.alphaValue < 1.0f;
}

- (NSView *)hitTest:(NSPoint)aPoint {
    if ([self isHidden]) {
        return nil; // just to make sure that hacked hidden property doesn't screw it up
    }
    return [super hitTest:aPoint];
}

@end
