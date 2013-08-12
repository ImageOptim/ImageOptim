/* ImageOptim */
#import <Quartz/Quartz.h>

extern NSDictionary *statusImages;

@class FilesQueue;
@class PrefsController;

@interface ImageOptim : NSObject <NSApplicationDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate>
{
	IBOutlet NSTableView *tableView;
	IBOutlet FilesQueue *filesController;
	
	PrefsController *prefsController;

	IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSTextField *statusBarLabel;
    IBOutlet NSTextView *credits;

    IBOutlet NSTableColumn *sizeColumn, *originalSizeColumn, *savingsColumn, *bestToolColumn;

    NSIndexSet* selectedIndexes;
	QLPreviewPanel* previewPanel;

    dispatch_source_t statusBarUpdateQueue;
    IBOutlet NSNumberFormatter *savingsFormatter;
}

- (IBAction)showPrefs:(id)sender;
- (IBAction)startAgain:(id)sender;
- (IBAction)startAgainOptimized:(id)sender;
- (IBAction)clearComplete:(id)sender;

-(IBAction)quickLookAction:(id)sender;
-(IBAction)openHomepage:(id)sender;
-(IBAction)viewSource:(id)sender;
-(IBAction)openDonationPage:(id)sender;
-(IBAction)browseForFiles:(id)sender;

-(int)numberOfCPUs;
-(void)loadCreditsHTML;

@property (copy,nonatomic) NSIndexSet* selectedIndexes;
@property (readonly) FilesQueue *filesQueue;
@end
