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
}

- (IBAction)showPrefs:(id)sender;
- (void)windowWillClose:(NSNotification *)aNotification;
+ (void)initialize;


@end
