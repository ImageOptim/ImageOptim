//
//  FilesQueue.h
//
//  Created by porneL on 23.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@class File;
extern NSString *const kFilesQueueFinished;

@interface FilesQueue : NSArrayController <NSTableViewDelegate,NSTableViewDataSource> {
	NSTableView *tableView;
	BOOL isEnabled, isBusy;
	NSInteger nextInsertRow;
	NSOperationQueue *cpuQueue;
    NSOperationQueue *fileIOQueue;
	NSOperationQueue *dirWorkerQueue;	
	
    NSHashTable *seenPathHashes;
    
    NSLock *queueWaitingLock;
}

-(void)configureWithTableView:(NSTableView*)a;

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation;
-(void)addPathsBelowSelection:(NSArray *)paths;
-(BOOL)addPaths:(NSArray *)paths;
-(BOOL)addPaths:(NSArray *)paths filesOnly:(BOOL)t;

-(void) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)indexSet
										toIndex:(NSUInteger)insertIndex;
- (NSUInteger)rowsAboveRow:(NSUInteger)row inIndexSet:(NSIndexSet *)indexSet;
- (NSUInteger)numberOfRowsInTableView:(NSTableView *)tableview;

-(void)startAgainOptimized:(BOOL)optimized;
-(BOOL)canStartAgainOptimized:(BOOL)optimized;
-(void)clearComplete;
-(BOOL)canClearComplete;
-(void)cleanup;
-(void)setRow:(NSInteger)row;
-(void)openRowInFinder:(NSInteger)row;

-(NSArray *)fileTypes;

@property (unsafe_unretained, readonly, nonatomic) NSNumber *queueCount;
@property (readonly) BOOL isBusy;

@end
