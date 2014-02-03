/* MyTableView */

#import <Cocoa/Cocoa.h>

@class RevealButtonCell;

@interface MyTableView : NSTableView
{
    NSInteger iMouseRow, iMouseCol;
    RevealButtonCell *iMouseCell;
}
- (IBAction)delete:(id)sender;
- (IBAction)copyAsDataURI:(id)sender;

-(IBAction)openInFinder:(id)sender;
@end
