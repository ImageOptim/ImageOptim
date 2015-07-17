//
//  PrefsController.m
//
//  Created by porneL on 24.wrz.07.
//

#import "PrefsController.h"
#import "ImageOptimController.h"
#import "Transformers.h"

@implementation PrefsController

-(instancetype)init {
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
    NSString *anchors[] = {@"general", @"jpegoptim", @"optipng", @"optipng", @"pngcrush", @"pngout"};
    NSString *anchor = @"main";

    if (tag >= 1 && tag <= 6) {
        anchor = anchors[tag-1];
    }
    [[NSHelpManager sharedHelpManager] openHelpAnchor:anchor inBook:locBookName];
}
@end
