//
//  PrefsController.h
//
//  Created by porneL on 24.wrz.07.
//

#import <Cocoa/Cocoa.h>
@class ImageOptim;

@interface PrefsController : NSWindowController {
	ImageOptim *owner;
	
	NSSlider *tasksSlider;
	NSArrayController *chunksController;

	int maxNumberOfTasks;
	int recommendedNumberOfTasks;
	int criticalNumberOfTasks;
}

-(void)windowDidLoad;

-(IBAction)browseForExecutable:(id)sender;
-(void)showWindow:(id)sender;
-(IBAction)addGammaChunks:(id)sender;
-(IBAction)showHelp:(id)sender;
@property (retain) IBOutlet NSSlider *tasksSlider;
@property (retain) IBOutlet NSArrayController *chunksController;
@property (readonly) int maxNumberOfTasks;
@property (readonly) int recommendedNumberOfTasks;
@property (readonly) int criticalNumberOfTasks;
@end
