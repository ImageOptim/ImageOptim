/* ImageOptim */
#import <Quartz/Quartz.h>

extern NSDictionary *statusImages;

@class FilesController;
@class PrefsController;

@interface ImageOptimController : NSObject<NSApplicationDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate> {
    IBOutlet NSTableView *tableView;
    IBOutlet FilesController *__unsafe_unretained filesController;

    PrefsController *prefsController;

    IBOutlet NSTextField *statusBarLabel;
    IBOutlet NSTextView *credits;

    IBOutlet NSTableColumn *fileColumn, *sizeColumn, *originalSizeColumn, *savingsColumn, *bestToolColumn;

    QLPreviewPanel *previewPanel;

    dispatch_source_t statusBarUpdateQueue;
    IBOutlet NSNumberFormatter *savingsFormatter;
}

- (IBAction)showPrefs:(id)sender;
- (IBAction)showLossyPrefs:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)startAgain:(id)sender;
- (IBAction)startAgainOptimized:(id)sender;
- (IBAction)clearComplete:(id)sender;

- (IBAction)quickLookAction:(id)sender;
- (IBAction)openHomepage:(id)sender;
- (IBAction)viewSource:(id)sender;
- (IBAction)openDonationPage:(id)sender;
- (IBAction)browseForFiles:(id)sender;

@property (readonly) int numberOfCPUs;
- (void)loadCreditsHTML:(id)_;

@property (unsafe_unretained, readonly) FilesController *filesController;
@end
