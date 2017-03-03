//
//  PrefsController.h
//
//  Created by porneL on 24.wrz.07.
//

#import <Cocoa/Cocoa.h>
@class ImageOptimController;

@interface PrefsController : NSWindowController {
}
@property IBOutlet NSTabView *tabs;
@property (readonly) BOOL svgSupported;

- (IBAction)showHelp:(id)sender;
- (IBAction)showLossySettings:(id)sender;
@end

