#import "MyTableView.h"

@implementation MyTableView

- (IBAction)delete:(id)sender
{
	[[self delegate] delete:sender];
}

@end
