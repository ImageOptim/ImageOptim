//
//  PrefsController.m
//
//  Created by porneL on 24.wrz.07.
//

#import "PrefsController.h"
#import "ImageOptimController.h"
#import "Transformers.h"

@implementation PrefsController

- (instancetype)init {
    if ((self = [super initWithWindowNibName:@"PrefsController"])) {
        CeilFormatter *cf = [CeilFormatter new];
        [NSValueTransformer setValueTransformer:cf forName:@"CeilFormatter"];

        DisabledColor *dc = [DisabledColor new];
        [NSValueTransformer setValueTransformer:dc forName:@"DisabledColor"];

        [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"GuetzliEnabled" options:0 context:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)defaults
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (!notified && [defaults boolForKey:@"GuetzliEnabled"]) {
        notified = YES;
        [self warnGuetzliSlowness];

        if ([defaults integerForKey:@"JpegOptimMaxQuality"] < 85) {
            [defaults setInteger:85 forKey:@"JpegOptimMaxQuality"];
        }
    }
}

-(void)warnGuetzliSlowness {
    NSAlert *alert = [NSAlert new];
    alert.alertStyle = NSAlertStyleWarning;
    alert.messageText = NSLocalizedString(@"Guetzli is very slow", "alert box");
    alert.informativeText = NSLocalizedString(@"It can take up to 30 minutes per image. Your system may be unresponsive while Guetzli is running.", "alert box");
    [alert beginSheetModalForWindow:[self window] completionHandler:nil];
}

- (IBAction)showLossySettings:(id)sender {
    [self showWindow:sender];
    [self.tabs selectTabViewItemAtIndex:1];
}

- (IBAction)showHelp:(id)sender {
    NSInteger tag = [sender tag];

    [[self window] setHidesOnDeactivate:NO];

    NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
    NSString *anchors[] = {@"general", @"jpegoptim", @"optipng", @"optipng", @"pngcrush", @"pngout"};
    NSString *anchor = @"main";

    if (tag >= 1 && tag <= 6) {
        anchor = anchors[tag-1];
    }
    [[NSHelpManager sharedHelpManager] openHelpAnchor:anchor inBook:locBookName];
}

// This doesn't belong here :(
-(BOOL)svgSupported {
    NSString *nodePath = @"/usr/local/bin/node";
    return [[NSFileManager defaultManager] isExecutableFileAtPath:nodePath];
}
@end
