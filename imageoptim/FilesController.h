//
//  FilesController.h
//
//  Created by porneL on 23.wrz.07.
//

@import Cocoa;

@class File, ResultsDb, JobProxy;
extern NSString *const kJobQueueFinished;

@interface FilesController : NSArrayController<NSTableViewDelegate, NSTableViewDataSource>

- (void)configureWithTableView:(NSTableView *)a;

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation;
- (void)addURLsBelowSelection:(NSArray<NSURL *> *)paths;
- (BOOL)addURLs:(NSArray<NSURL *> *)paths;
- (BOOL)addPaths:(NSArray<NSString *> *)paths;
- (BOOL)addURLs:(NSArray<NSURL *> *)paths filesOnly:(BOOL)t;

- (void)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet *)indexSet
                                        toIndex:(NSUInteger)insertIndex;
- (NSUInteger)rowsAboveRow:(NSUInteger)row inIndexSet:(NSIndexSet *)indexSet;
- (NSUInteger)numberOfRowsInTableView:(NSTableView *)tableview;

- (void)startAgainOptimized:(BOOL)optimized;
- (BOOL)canStartAgainOptimized:(BOOL)optimized;
- (void)clearComplete;
@property (readonly) BOOL canClearComplete;
- (void)revert;
@property (readonly) BOOL canRevert;
- (void)cleanup;
- (void)setRow:(NSInteger)row;

- (void)stopSelected;
- (void)updateStoppableState;
- (NSNumber *)queueCount;

@property (readonly, copy) NSArray *fileTypes;
@property (readonly) BOOL isBusy, isStoppable;

@end
