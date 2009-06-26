//
//  FilesQueue.h
//
//  Created by porneL on 23.wrz.07.
//

#import <Cocoa/Cocoa.h>
@class File;

@interface FilesQueue : NSObject {
	NSTableView *tableView;
	NSArrayController *filesController;
	BOOL isEnabled;
	
	NSOperationQueue *workerQueue;
	NSOperationQueue *dirWorkerQueue;	
	
	NSRecursiveLock *filesControllerLock;
	
    NSHashTable *seenPathHashes;
    
	NSProgressIndicator *progressBar;
}

-(id)initWithTableView:(NSTableView*)a progressBar:(NSProgressIndicator *)p andController:(NSArrayController*)b;
- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation;
-(void)addFilesFromPaths:(NSArray *)paths;
-(void)addPath:(NSString*)s dirs:(BOOL)a;
-(void)addFilesFromPaths:(NSArray *)paths;
-(void)setEnabled:(BOOL)y;

-(void)runAdded;
-(void)startAgain;

-(IBAction)delete:(id)sender;

-(void)workersHaveFinished;

-(void)updateProgressbar;

-(void)openRowInFinder:(int)row;
@end
