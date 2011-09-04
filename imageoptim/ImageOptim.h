/* ImageOptim */
#import <Quartz/Quartz.h>


@class FilesQueue;
@class PrefsController;

@interface ImageOptim : NSObject <QLPreviewPanelDataSource, QLPreviewPanelDelegate>
{
	IBOutlet NSTableView *tableView;
	IBOutlet NSArrayController *filesController;

	FilesQueue *filesQueue;
	PrefsController *prefsController;

	IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSTextField *statusBarLabel;
    IBOutlet NSTextView *credits;

    NSIndexSet* selectedIndexes;
	QLPreviewPanel* previewPanel;
}

- (IBAction)showPrefs:(id)sender;
- (IBAction)startAgain:(id)sender;

-(IBAction)quickLookAction:(id)sender;
-(IBAction)openPngOutHomepage:(id)sender;
-(IBAction)openPngOutDownload:(id)sender;

-(IBAction)browseForFiles:(id)sender;

+ (void)initialize;

+(int)numberOfCPUs;

@property (copy) NSIndexSet* selectedIndexes;

@property (readonly) FilesQueue *filesQueue;
@end
