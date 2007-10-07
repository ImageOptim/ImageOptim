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
	
	IBOutlet NSSlider *tasksSlider;
	IBOutlet NSArrayController *chunksController;

	int maxNumberOfTasks;
	int recommendedNumberOfTasks;
	int criticalNumberOfTasks;
}

-(void)windowDidLoad;


-(void)showWindow:(id)sender;
-(IBAction)addGammaChunks:(id)sender;
-(IBAction)showHelp:(id)sender;
@end
