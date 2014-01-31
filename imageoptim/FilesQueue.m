//
//  FilesQueue.m
//
//  Created by porneL on 23.wrz.07.
//
#import "File.h"
#import "FilesQueue.h"
#import "log.h"
#import "Workers/DirWorker.h"
#import "RevealButtonCell.h"

@interface FilesQueue()

-(NSArray *)extensions;
-(BOOL)isAnyQueueBusy;
-(void)updateBusyState;
@end

NSString *const kFilesQueueFinished = @"FilesQueueFinished";
static NSString *kIMDraggedRowIndexesPboardType = @"com.imageoptim.rows";

@implementation FilesQueue

@synthesize isBusy;

-(void)configureWithTableView:(NSTableView *)inTableView {
    tableView = inTableView;
    seenPathHashes = [[NSHashTable alloc] initWithOptions:NSHashTableZeroingWeakMemory capacity:1000];

    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

    cpuQueue = [NSOperationQueue new];
    [cpuQueue setMaxConcurrentOperationCount:[defs integerForKey:@"RunConcurrentTasks"]];

    dirWorkerQueue = [NSOperationQueue new];
    [dirWorkerQueue setMaxConcurrentOperationCount:[defs integerForKey:@"RunConcurrentDirscans"]];

    fileIOQueue = [NSOperationQueue new];
    NSUInteger fileops = [defs integerForKey:@"RunConcurrentFileops"];
    [fileIOQueue setMaxConcurrentOperationCount:fileops?fileops:2];

    queueWaitingLock = [NSLock new];

    [tableView registerForDraggedTypes:@[NSFilenamesPboardType, kIMDraggedRowIndexesPboardType]];

    [self setSelectsInsertedObjects:NO];

    isEnabled = YES;
}

-(NSNumber *)queueCount {
    return [NSNumber numberWithInteger:cpuQueue.operationCount + dirWorkerQueue.operationCount + fileIOQueue.operationCount];
}

-(BOOL)isAnyQueueBusy {
    return cpuQueue.operationCount > 0 || dirWorkerQueue.operationCount > 0 || fileIOQueue.operationCount > 0;
}

-(void)waitForQueuesToFinish {

    if ([queueWaitingLock tryLock]) {
        @try {
            do { // any queue may be re-filled while waiting for another queue, so double-check is necessary
                [dirWorkerQueue waitUntilAllOperationsAreFinished];
                [fileIOQueue waitUntilAllOperationsAreFinished];
                [cpuQueue waitUntilAllOperationsAreFinished];

            } while ([self isAnyQueueBusy]);
        }
        @finally {
            [queueWaitingLock unlock];
        }
    }
    [self performSelectorOnMainThread:@selector(updateBusyState) withObject:nil waitUntilDone:NO];
}


-(void)setRow:(NSInteger)row {
    nextInsertRow=row;
}

-(void)cleanup {
    isEnabled = NO;
    [dirWorkerQueue cancelAllOperations];
    [fileIOQueue cancelAllOperations];
    [cpuQueue cancelAllOperations];

    NSArray *content = [self content];
    [content makeObjectsPerformSelector:@selector(cleanup)];
}

- (NSDragOperation)tableView:(NSTableView *)atableView
    validateDrop:(id <NSDraggingInfo>)info
    proposedRow:(NSInteger)row
    proposedDropOperation:(NSTableViewDropOperation)operation
{
    if (!isEnabled) return NSDragOperationNone;

    NSDragOperation dragOp = ([info draggingSource] == tableView) ? NSDragOperationMove : NSDragOperationCopy;
    [atableView setDropRow:row dropOperation:NSTableViewDropAbove];

    return dragOp;
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    if (!isEnabled) return NO;

    NSArray *filePathlist = [[[self arrangedObjects] objectsAtIndexes:rowIndexes] valueForKey:@"filePath"];

    if ([filePathlist count]) {
        [pboard declareTypes:@[NSFilenamesPboardType, kIMDraggedRowIndexesPboardType] owner:self];
        return [pboard setPropertyList:filePathlist forType:NSFilenamesPboardType] &&
               [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:kIMDraggedRowIndexesPboardType];
    }
    return NO;
}

-(void)removeObjects:(NSArray *)objects {
    [super removeObjects:objects];
    [objects makeObjectsPerformSelector:@selector(cleanup)];
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation {
    NSArray *objs = [self arrangedObjects];
    if (row < (signed)[objs count]) {
        File *f = [objs objectAtIndex:row];

        if ([aCell isKindOfClass:[RevealButtonCell class]]) {
            NSRect infoButtonRect = [((RevealButtonCell *)aCell) infoButtonRectForBounds:*rect];

            BOOL mouseIsInside = NSMouseInRect(mouseLocation, infoButtonRect, [aTableView isFlipped]);
            if (mouseIsInside) {
                return [f filePath];
            }
        }

        return [f statusText];
    }
    return nil;
}

-(void)openRowInFinder:(NSInteger)row {
    NSArray *files = [self arrangedObjects];
    if (row < [files count]) {
        File *f = [files objectAtIndex:row];
        [[NSWorkspace sharedWorkspace] selectFile:[f filePath] inFileViewerRootedAtPath:@""];
    }
}

// Better in NSArrayController class
- (NSUInteger)rowsAboveRow:(NSUInteger)row inIndexSet:(NSIndexSet *)indexSet {
    NSUInteger currentIndex = [indexSet firstIndex];
    NSUInteger i = 0;
    while (currentIndex != NSNotFound) {
        if (currentIndex < row) {
            i++;
        }
        currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
    return i;
}
- (NSUInteger)numberOfRowsInTableView:(NSTableView *)tableview {
    return [[self arrangedObjects] count];
}

-(void) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet *)indexSet
    toIndex:(NSUInteger)insertIndex {

    NSArray     *objects = [self arrangedObjects];
    NSUInteger  idx = [indexSet lastIndex];

    NSUInteger  aboveInsertIndexCount = 0;
    id          object;
    NSUInteger  removeIndex;

    while (NSNotFound != idx) {
        if (idx >= insertIndex) {
            removeIndex = idx + aboveInsertIndexCount;
            aboveInsertIndexCount += 1;
        } else {
            removeIndex = idx;
            insertIndex -= 1;
        }
        object = [objects objectAtIndex:removeIndex];
        [self removeObjectAtArrangedObjectIndex:removeIndex];
        [self insertObject:object atArrangedObjectIndex:insertIndex];

        idx = [indexSet indexLessThanIndex:idx];
    }
}


- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    NSPasteboard *pboard = [info draggingPasteboard];
    NSData *indexesArchived;

    if ([info draggingSource] == aTableView && (indexesArchived = [pboard dataForType:kIMDraggedRowIndexesPboardType])) {
        NSIndexSet *indexSet = [NSKeyedUnarchiver unarchiveObjectWithData:indexesArchived];

        NSIndexSet *selection = [self selectionIndexes];
        BOOL containsSelection = [selection containsIndexes:indexSet];

        [self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];

        if (containsSelection) {
            NSUInteger rowsAbove = [self rowsAboveRow:row inIndexSet:indexSet];

            NSRange range = NSMakeRange(row - rowsAbove, [indexSet count]);
            indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
            [self setSelectionIndexes:indexSet];
        } else if (![selection count]) {
            // non-empty selection seems to be preserved, but if there was no selection
            // then tableview selects a row
            [self setSelectedObjects:@[]];
        }

        return YES;
    } else {
        NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];
        nextInsertRow = row;
        [self performSelectorInBackground:@selector(addPaths:) withObject:paths];
    }

    [[aTableView window] makeKeyAndOrderFront:aTableView];

    return YES;
}

/** selfLock must be locked before using this
    That's a dumb linear search. Would be nice to replace NSArray with NSSet or NSHashTable.
 */
-(File *)findFileByPath:(NSString *)path {
    if (![seenPathHashes containsObject:path]) {
        return nil;
    }

    for (File *f in [self content]) {
        if ([path isEqualToString:[f filePath]]) {
            return f;
        }
    }
    return nil;
}

-(void)addFileObjects:(NSArray *)files {
    [[tableView undoManager] registerUndoWithTarget:self selector:@selector(deleteObjects:) object:files];
    [[tableView undoManager] setActionName:NSLocalizedString(@"Add",@"undo command name")];

    @synchronized(self) {
        if (nextInsertRow < 0 || nextInsertRow >= [[self arrangedObjects] count]) {
            [self addObjects:files];
        } else {
            NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(nextInsertRow, [files count])];
            [self insertObjects:files atArrangedObjectIndexes:set];
            nextInsertRow += [files count];
        }
    }

    [self updateBusyState];
}

-(void)addPathsBelowSelection:(NSArray *)paths {
    nextInsertRow = [self selectionIndex];
    [self performSelectorInBackground:@selector(addPaths:) withObject:paths];
}

-(BOOL)addPaths:(NSArray *)paths {
    return [self addPaths:paths filesOnly:NO];
}

/** filesOnly indicates that paths do not contain any directories */
-(BOOL)addPaths:(NSArray *)paths filesOnly:(BOOL)filesOnly {
    if (!isEnabled) {
        return NO;
    }

    NSMutableArray *toAdd = [NSMutableArray arrayWithCapacity:[paths count]];

    BOOL isDir = NO;
    BOOL allOK = YES;
    NSFileManager *fm = filesOnly ? nil : [NSFileManager defaultManager];

    for (NSString *path in paths) {
        if (fm) {
            if (![fm fileExistsAtPath:path isDirectory:&isDir]) {
                IOWarn("%@ doesn't exist", path);
                allOK = NO;
                continue;
            }
        }

        if (!isDir) {
            File *f = [self findFileByPath:path];
            if (f) {
                if (![f isBusy]) [f enqueueWorkersInCPUQueue:cpuQueue fileIOQueue:fileIOQueue];
            } else {
                [seenPathHashes addObject:path]; // used by findFileByPath
                f = [[File alloc] initWithFilePath:path];
                [toAdd addObject:f];
                [f enqueueWorkersInCPUQueue:cpuQueue fileIOQueue:fileIOQueue];
            }
        } else {
            DirWorker *w = [[DirWorker alloc] initWithPath:path filesQueue:self extensions:[self extensions]];
            [dirWorkerQueue addOperation:w];
        }
    }

    [self performSelectorOnMainThread:@selector(addFileObjects:) withObject:toAdd waitUntilDone:NO];

    return allOK;
}

-(BOOL)canClearComplete {
    for (File *f in [self arrangedObjects]) {
        if (f.isDone) return YES;
    }
    return NO;
}

-(void)clearComplete {
    NSUInteger i=0;
    NSMutableIndexSet *set = [NSMutableIndexSet new];

    @synchronized(self) {
        for (File *f in [self arrangedObjects]) {
            if (f.isDone) [set addIndex:i];
            i++;
        }
        if ([set count]) {
            [self removeObjectsAtArrangedObjectIndexes:set];
        }
    }
    [self setRow:-1];
}

-(BOOL)canStartAgainOptimized:(BOOL)optimized {
    NSArray *array = [self selectedObjects];
    if (![array count]) array = [self content];

    for (File *f in array) {
        if (!f.isBusy && (!optimized || f.isOptimized)) return YES;
    }
    return NO;
}

-(void)startAgainOptimized:(BOOL)optimized {
    BOOL anyStarted = NO;
    @synchronized(self) {
        NSArray *files = [self selectedObjects];
        NSInteger selectionCount = [files count];

        // UI doesn't give a way to deselect all, so here's a substitute
        // when selecting "again" on file that doesn't need it, deselect
        if (1 == selectionCount) {
            File *file = [files objectAtIndex:0];
            if (file.isBusy || !file.isOptimized) {
                files = [files copy];
                [self setSelectedObjects:@[]];
            }
        } else if (!selectionCount) {
            files = [self content];
        }

        for (File *f in files) {
            if (!f.isBusy && (!optimized || f.isOptimized)) {
                [f enqueueWorkersInCPUQueue:cpuQueue fileIOQueue:fileIOQueue];
                anyStarted = YES;
            }
        }
    }

    if (!anyStarted) NSBeep();

    [self updateBusyState];
}

-(void)updateBusyState {
    BOOL currentlyBusy = [self isAnyQueueBusy];

    if (isBusy != currentlyBusy) {
        [self willChangeValueForKey:@"isBusy"];
        isBusy = currentlyBusy;
        [self didChangeValueForKey:@"isBusy"];

        if (isBusy) {
            if ([queueWaitingLock tryLock]) { // if it's locked, there's thread waiting for finish
                [queueWaitingLock unlock]; // can't lock/unlock across threads, so new lock will have to be made
                [self performSelectorInBackground:@selector(waitForQueuesToFinish) withObject:nil];
            }
        }
    }

    if (!currentlyBusy) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kFilesQueueFinished object:self];
    }
}

#define PNG_ENABLED 1
#define JPEG_ENABLED 2
#define GIF_ENABLED 4

-(int)typesEnabled {
    int types = 0;
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

    if ([defs boolForKey:@"PngCrushEnabled"] || [defs boolForKey:@"PngOutEnabled"] ||
            [defs boolForKey:@"OptiPngEnabled"] || [defs boolForKey:@"AdvPngEnabled"] || [defs boolForKey:@"ZopfliEnabled"]) {
        types |= PNG_ENABLED;
    }

    if ([defs boolForKey:@"JpegOptimEnabled"] || [defs boolForKey:@"JpegTranEnabled"]) {
        types |= JPEG_ENABLED;
    }

    if ([defs boolForKey:@"GifsicleEnabled"]) {
        types |= GIF_ENABLED;
    }

    if (!types) types = PNG_ENABLED; // will show error in the list
    return types;
}


-(NSArray *)extensions {

    int types = [self typesEnabled];
    NSMutableArray *extensions = [NSMutableArray array];

    if (types & PNG_ENABLED) {
        [extensions addObject:@"png"];
        [extensions addObject:@"PNG"];
    }
    if (types & JPEG_ENABLED) {
        [extensions addObjectsFromArray:[NSArray arrayWithObjects:@"jpg",@"JPG",@"jpeg",@"JPEG",nil]];
    }
    if (types & GIF_ENABLED) {
        [extensions addObject:@"gif"];
        [extensions addObject:@"GIF"];
    }

    return extensions;
}


-(NSArray *)fileTypes {
    int types = [self typesEnabled];

    NSMutableArray *fileTypes = [NSMutableArray array];

    if (types & PNG_ENABLED) {
        [fileTypes addObjectsFromArray:[NSArray arrayWithObjects:@"png",@"PNG",NSFileTypeForHFSTypeCode('PNGf'),@"public.png",@"image/png",nil]];
    }
    if (types & JPEG_ENABLED) {
        [fileTypes addObjectsFromArray:[NSArray arrayWithObjects:@"jpg",@"jpeg",@"JPG",@"JPEG",NSFileTypeForHFSTypeCode('JPEG'),@"public.jpeg",@"image/jpeg",nil]];
    }
    if (types & GIF_ENABLED) {
        [fileTypes addObjectsFromArray:[NSArray arrayWithObjects:@"gif",@"GIF",NSFileTypeForHFSTypeCode('GIFf'),@"public.gif",@"image/gif",nil]];
    }
    return fileTypes;
}

@end
