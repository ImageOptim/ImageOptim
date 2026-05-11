/*
    File:       DragDropImageView.m

    Contains:   A sample to demonstrate Drag and Drop with Images in Cocoa
*/

#import "DragDropImageView.h"
#import "ImageOptimController.h"
#import "FilesController.h"

@interface DragDropImageView ()
@property (strong) NSImageView *iconView;
@property (strong) NSTextField *titleLabel;
@property (strong) NSTextField *subtitleLabel;
@property (strong) NSButton *addButton;
@end

@implementation DragDropImageView

- (void)awakeFromNib {
    [self registerForDraggedTypes:@[ NSFilenamesPboardType ]];
    [self buildEmptyState];
}

- (NSTextField *)emptyStateLabelWithString:(NSString *)string font:(NSFont *)font color:(NSColor *)color {
    NSTextField *label = [NSTextField labelWithString:string];
    label.font = font;
    label.textColor = color;
    label.alignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

- (void)buildEmptyState {
    self.iconView = [[NSImageView alloc] initWithFrame:NSZeroRect];
    self.iconView.image = NSApp.applicationIconImage;
    self.iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;

    self.titleLabel = [self emptyStateLabelWithString:NSLocalizedString(@"Drop images to optimize", @"empty state title")
                                                font:[NSFont systemFontOfSize:18 weight:NSFontWeightSemibold]
                                               color:NSColor.labelColor];
    self.subtitleLabel = [self emptyStateLabelWithString:NSLocalizedString(@"PNG, JPEG, GIF, and SVG files are supported", @"empty state subtitle")
                                                   font:[NSFont systemFontOfSize:12 weight:NSFontWeightRegular]
                                                  color:NSColor.secondaryLabelColor];

    self.addButton = [NSButton buttonWithTitle:NSLocalizedString(@"Add Files", @"empty state button")
                                        target:self
                                        action:@selector(browseForFiles:)];
    self.addButton.bezelStyle = NSBezelStyleRounded;
    self.addButton.controlSize = NSControlSizeRegular;
    self.addButton.image = [NSImage imageWithSystemSymbolName:@"plus" accessibilityDescription:NSLocalizedString(@"Add Files", @"empty state button")];
    self.addButton.imagePosition = NSImageLeft;
    self.addButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.addButton.toolTip = NSLocalizedString(@"Add files or folders to optimize", @"empty state button tooltip");

    [self addSubview:self.iconView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.subtitleLabel];
    [self addSubview:self.addButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.iconView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.iconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-52],
        [self.iconView.widthAnchor constraintEqualToConstant:64],
        [self.iconView.heightAnchor constraintEqualToConstant:64],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.iconView.bottomAnchor constant:14],
        [self.titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor constant:32],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-32],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:6],
        [self.subtitleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor constant:32],
        [self.subtitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-32],
        [self.subtitleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.addButton.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:16],
        [self.addButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
    ]];
}

- (BOOL)allowsVibrancy {
    return true;
}

- (BOOL)isOpaque {
    return false;
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

- (void)drawRect:(NSRect) _unused {
    NSRect rect = self.bounds;

    [[NSColor clearColor] set];
    NSRectFillUsingOperation(rect, NSCompositingOperationSourceOver);

    NSRect bounds = [self bounds];
    CGFloat cardWidth = MIN(440, MAX(260, bounds.size.width - 72));
    CGFloat cardHeight = MIN(230, MAX(180, bounds.size.height - 48));
    NSRect cardRect = NSMakeRect((bounds.size.width - cardWidth) / 2,
                                 (bounds.size.height - cardHeight) / 2,
                                 cardWidth,
                                 cardHeight);

    if (!smoothSizes) {
        cardRect = NSIntegralRect(cardRect);
    }

    NSBezierPath *cardPath = [NSBezierPath bezierPathWithRoundedRect:cardRect xRadius:12 yRadius:12];
    [[[NSColor controlBackgroundColor] colorWithAlphaComponent:0.88] setFill];
    [cardPath fill];

    NSColor *strokeColor = highlight ? NSColor.controlAccentColor : NSColor.separatorColor;
    [[strokeColor colorWithAlphaComponent:highlight ? 0.55 : 0.45] setStroke];
    [cardPath setLineWidth:highlight ? 2 : 1];
    if (!highlight) {
        CGFloat dash[2] = { 6, 4 };
        [cardPath setLineDash:dash count:2 phase:0];
    }
    [cardPath stroke];
}

- (IBAction)browseForFiles:(id)sender {
    id delegate = NSApp.delegate;
    if ([delegate respondsToSelector:@selector(browseForFiles:)]) {
        [delegate browseForFiles:sender];
    }
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
