//
//  PrefsController.m
//
//  Created by porneL on 24.wrz.07.
//

#import "PrefsController.h"
#import "ImageOptim.h"
#import "Transformers.h"

@implementation PrefsController

-(id)init {
    if ((self = [super initWithWindowNibName:@"PrefsController"])) {
        CeilFormatter *cf = [CeilFormatter new];
        [NSValueTransformer setValueTransformer:cf forName:@"CeilFormatter"];

        DisabledColor *dc = [DisabledColor new];
        [NSValueTransformer setValueTransformer:dc forName:@"DisabledColor"];
    }
    return self;
}

-(IBAction)showHelp:(id)sender {
    NSInteger tag = [sender tag];

    [[self window] setHidesOnDeactivate:NO];

    NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
    NSString *anchors[] = {@"general", @"jpegoptim", @"advpng", @"optipng", @"pngcrush", @"pngout"};
    NSString *anchor = @"main";

    if (tag >= 1 && tag <= 6) {
        anchor = anchors[tag-1];
    }
    [[NSHelpManager sharedHelpManager] openHelpAnchor:anchor inBook:locBookName];
}
@end
