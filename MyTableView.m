#import "MyTableView.h"
#import "FilesQueue.h"

@implementation MyTableView

- (IBAction)delete:(id)sender
{
	[[self delegate] delete:sender];
}

-(void)awakeFromNib
{
    [self setDoubleAction:@selector(openInFinder)];
}

-(void)openInFinder
{
    int row = [self clickedRow];
    if (row < 0) return;
    
    FilesQueue *fc = [self delegate];
    [fc openRowInFinder:row];
}
@end
