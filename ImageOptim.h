/* ImageOptim */

#import <Cocoa/Cocoa.h>
@class FilesQueue;
@class PrefsController;

@interface ImageOptim : NSObject
{
	IBOutlet NSTableView *tableView;
	//IBOutlet NSMutableArray *files;
	IBOutlet NSArrayController *filesController;
	
	FilesQueue *filesQueue;
	IBOutlet NSApplication *application;
	PrefsController *prefsController;
	
	IBOutlet NSProgressIndicator *progressBar;
	
	NSArray *fileTypes;
}

- (IBAction)showPrefs:(id)sender;
- (void)windowWillClose:(NSNotification *)aNotification;

-(IBAction)openPngOutHomepage:(id)sender;
-(IBAction)openPngOutDownload:(id)sender;

-(IBAction)browseForFiles:(id)sender;

+ (void)initialize;

+(int)numberOfCPUs;

@end
