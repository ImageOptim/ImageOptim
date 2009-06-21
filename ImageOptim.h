/* ImageOptim */

#import <Cocoa/Cocoa.h>
@class FilesQueue;
@class PrefsController;

@interface ImageOptim : NSObject
{
	NSTableView *tableView;
	//IBOutlet NSMutableArray *files;
	NSArrayController *filesController;
	
	FilesQueue *filesQueue;
	NSApplication *application;
	PrefsController *prefsController;
	
	NSProgressIndicator *progressBar;
	
	NSArray *fileTypes;
}

- (IBAction)showPrefs:(id)sender;
- (IBAction)startAgain:(id)sender;

- (void)windowWillClose:(NSNotification *)aNotification;

-(IBAction)openPngOutHomepage:(id)sender;
-(IBAction)openPngOutDownload:(id)sender;

-(IBAction)browseForFiles:(id)sender;


+ (void)initialize;

+(int)numberOfCPUs;

@property (retain) IBOutlet NSTableView *tableView;
@property (retain) IBOutlet NSArrayController *filesController;
@property (retain,readonly) FilesQueue *filesQueue;
@property (retain) IBOutlet NSApplication *application;
@property (retain,readonly) PrefsController *prefsController;
@property (retain) IBOutlet NSProgressIndicator *progressBar;
@property (retain,readonly) NSArray *fileTypes;
@end
