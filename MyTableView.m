#import "MyTableView.h"
#import "FilesQueue.h"

@implementation MyTableView

- (IBAction)delete:(id)sender
{
	[(FilesQueue*)[self delegate] delete:sender];
}

- (void)keyDown:(NSEvent *)theEvent {
   
    if (![theEvent isARepeat] && [theEvent keyCode] == 49/*space*/ && [self numberOfSelectedRows])
    {
        [(FilesQueue*)[self delegate] quickLook];
    }
    else
    {
        [super keyDown:theEvent];        
    }
}

-(void)awakeFromNib
{
    [self setDoubleAction:@selector(openInFinder)];
}

-(void)openInFinder
{
    NSInteger row = [self clickedRow];
    if (row < 0) return;
    
    FilesQueue *fc = (FilesQueue *)[self delegate];
    assert([fc isKindOfClass:[FilesQueue class]]);
    [fc openRowInFinder:row];
}
@end
