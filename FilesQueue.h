//
//  FilesQueue.h
//
//  Created by porneL on 23.wrz.07.
//

#import <Cocoa/Cocoa.h>
@class File;
@class WorkerQueue;

@interface FilesQueue : NSObject {
	NSTableView *tableView;
	NSArrayController *filesController;
	BOOL isEnabled;
	
	WorkerQueue *workerQueue;
	WorkerQueue *dirWorkerQueue;	
	
	NSRecursiveLock *filesControllerLock;
	
	NSProgressIndicator *progressBar;
}

-(id)initWithTableView:(NSTableView*)a progressBar:(NSProgressIndicator *)p andController:(NSArrayController*)b;
- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation;
-(void)addFilesFromPaths:(NSArray *)paths;
-(void)addFilePath:(NSString*)s dirs:(BOOL)a;
-(void)addFilesFromPaths:(NSArray *)paths;
-(void)setEnabled:(BOOL)y;

-(void)runAdded;
-(void)startAgain;

-(IBAction)delete:(id)sender;

-(void)workersHaveFinished:(WorkerQueue *)q;

-(void)updateProgressbar;

-(void)openRowInFinder:(int)row;
@end
