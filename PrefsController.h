//
//  PrefsController.h
//
//  Created by porneL on 24.wrz.07.
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

-(IBAction)browseForExecutable:(id)sender;
-(void)showWindow:(id)sender;
-(IBAction)addGammaChunks:(id)sender;
-(IBAction)showHelp:(id)sender;
@end
