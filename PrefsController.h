//
//  PrefsController.h
//  ImageOptim
//
//  Created by porneL on 24.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ImageOptim;

@interface PrefsController : NSWindowController {

	ImageOptim *owner;
}

-(void)showWindow:(id)sender;

@end
