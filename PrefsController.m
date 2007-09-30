//
//  PrefsController.m
//  ImageOptim
//
//  Created by porneL on 24.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PrefsController.h"
#import "ImageOptim.h"

@implementation PrefsController

-(id)init
{
	self = [super initWithWindowNibName:@"PrefsController"];
	NSLog(@"init prefs %@",self);
	return self;
}

-(void)showWindow:(id)sender
{
	NSLog(@"window show?");
	owner = sender;
	[super showWindow:sender];
	[[self window] makeKeyAndOrderFront:self];
}
@end
