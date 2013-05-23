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
-(IBAction)browseForFiles:(id)sender;

+ (void)initialize;
+(void)regDefs;
+(int)numberOfCPUs;

@property (copy,nonatomic) NSIndexSet* selectedIndexes;

@property (readonly) FilesQueue *filesQueue;
@end
