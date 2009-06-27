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
	
	NSOperationQueue *cpuQueue;
    NSOperationQueue *fileIOQueue;
	NSOperationQueue *dirWorkerQueue;	
	
	NSRecursiveLock *filesControllerLock;
	
    NSHashTable *seenPathHashes;
    
	NSProgressIndicator *progressBar;
    
    NSLock *queueWaitingLock;
    
    NSTask *currentQLManageTask;
}

-(id)initWithTableView:(NSTableView*)a progressBar:(NSProgressIndicator *)p andController:(NSArrayController*)b;
- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation;
-(void)addPaths:(NSArray *)paths;
-(void)addPath:(NSString*)s dirs:(BOOL)a;
-(void)addPaths:(NSArray *)paths;
-(void)addFilePaths:(NSArray *)paths;
-(void)setEnabled:(BOOL)y;

-(void)runAdded;
-(void)startAgain;

-(IBAction)delete:(id)sender;
-(void)quickLook;

-(void)updateProgressbar;
-(void)cleanup;

-(void)openRowInFinder:(int)row;
@end
