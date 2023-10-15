//
//  PrefsController.h
//
//  Created by porneL on 24.wrz.07.
//

@import Cocoa;
@class ImageOptimController;

@interface PrefsController : NSWindowController {
    BOOL notified;
}
@property IBOutlet NSTabView *tabs;
@property (readonly) BOOL svgSupported;

- (IBAction)showHelp:(id)sender;
- (IBAction)showLossySettings:(id)sender;
@end
