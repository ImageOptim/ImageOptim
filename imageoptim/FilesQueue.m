//
//  FilesQueue.m
//
//  Created by porneL on 23.wrz.07.
//
#import "File.h"
#import "FilesQueue.h"

#import "Workers/DirWorker.h"

@interface FilesQueue ()

-(NSArray*)extensions;
-(BOOL)isAnyQueueBusy;
-(void)updateProgressbar;
-(NSArray*)selectedFilePaths;
-(void)deleteObjects:(NSArray*)objects;
@end


@implementation FilesQueue

-(id)initWithTableView:(NSTableView*)inTableView progressBar:(NSProgressIndicator *)inBar andController:(NSArrayController*)inController
{
    if (self = [super init]) {
	progressBar = inBar;
	filesController = inController;
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

	[tableView setDelegate:self];
	[tableView setDataSource:self];
	[tableView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];

    isEnabled = YES;
    }
    return self;
}

-(NSNumber *)queueCount
{
    return [NSNumber numberWithInteger:cpuQueue.operationCount + dirWorkerQueue.operationCount + fileIOQueue.operationCount];
}

-(BOOL)isAnyQueueBusy
{
    return cpuQueue.operationCount > 0 || dirWorkerQueue.operationCount > 0 || fileIOQueue.operationCount > 0;
}

-(void)waitForQueuesToFinish {

    if ([queueWaitingLock tryLock])
    {
        @try{
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
    [self performSelectorOnMainThread:@selector(updateProgressbar) withObject:nil waitUntilDone:NO];
}

-(void)waitInBackgroundForQueuesToFinish {
    if ([queueWaitingLock tryLock]) // if it's locked, there's thread waiting for finish
    {
        [queueWaitingLock unlock]; // can't lock/unlock across threads, so new lock will have to be made
        [self performSelectorInBackground:@selector(waitForQueuesToFinish) withObject:nil];
    }
}

-(void)setRow:(NSInteger)row
{
	nextInsertRow=row;
}

-(void)cleanup {
    isEnabled = NO;
    [dirWorkerQueue cancelAllOperations];
    [fileIOQueue cancelAllOperations];
    [cpuQueue cancelAllOperations];

    NSArray *content = [filesController content];
    [content makeObjectsPerformSelector:@selector(cleanup)];
}

- (NSDragOperation)tableView:(NSTableView *)atableView
                validateDrop:(id <NSDraggingInfo>)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)operation
{
	if (!isEnabled) return NSDragOperationNone;

    NSDragOperation dragOp = ([info draggingSource] == tableView) ? NSDragOperationMove : NSDragOperationCopy;
	@synchronized (filesController) {
        nextInsertRow=row;
        [atableView setDropRow:row dropOperation:NSTableViewDropAbove];
    }
    return dragOp;
}

-(void)pasteObjectsFrom:(NSPasteboard *)pboard {
	NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];
	[self performSelectorInBackground:@selector(addPaths:) withObject:paths];
}

- (BOOL)tableView:(NSTableView *)tv
		writeRows:(NSArray*)rows
	 toPasteboard:(NSPasteboard*)pboard
{
	if (!isEnabled) return NO;
	NSArray *filePathlist=[self selectedFilePaths];
	NSArray *typesArray=[NSArray arrayWithObject:NSFilenamesPboardType];

	if ([filePathlist count]>0)
	{
		[pboard declareTypes:typesArray owner:self];
		if([pboard setPropertyList:filePathlist forType:NSFilenamesPboardType])
		return YES;

	}
	return NO;
}

-(BOOL)copyObjects
{
		if (!isEnabled) return NO;
		NSPasteboard *pboard=[NSPasteboard generalPasteboard];
		NSArray *filePathlist=[self selectedFilePaths];

		NSArray *typesArray=[NSArray arrayWithObject:NSFilenamesPboardType];

		if ([filePathlist count]>0)
		{
			[pboard declareTypes:typesArray owner:self];
			if([pboard setPropertyList:filePathlist forType:NSFilenamesPboardType])
				return YES;

		}
	return NO;
}

-(NSArray*)selectedFilePaths
{
	NSArray *selectedFiles=[filesController selectedObjects];
	NSEnumerator *fileEnum=[selectedFiles objectEnumerator];
	NSMutableArray *filePathlist=[NSMutableArray array];

	id afile;
	while (afile=[fileEnum nextObject]) {
		[filePathlist addObject:[afile valueForKey:@"filePath"]];
	}
	return filePathlist;
}


-(void)cutObjects
	{
	if ([self copyObjects]){
		[self deleteObjects:[filesController selectedObjects]];
		[[tableView undoManager] setActionName:NSLocalizedString(@"Cut",@"undo command name")];
	}
}


-(IBAction)delete:(id)sender
{
    NSArray *files = nil;
	@synchronized (filesController) {
        if ([filesController canRemove]) {
            files = [filesController selectedObjects];
            [self deleteObjects:files];
        }
    }
}

-(void)addObjects:(NSArray*)objects
{
	NSUndoManager *undo=[tableView undoManager];
	[undo registerUndoWithTarget:self selector:@selector(deleteObjects:) object:objects];
	[filesController addObjects:objects];
}

-(void)deleteObjects:(NSArray*)objects
{
	NSUndoManager *undo=[tableView undoManager];
	[undo registerUndoWithTarget:self selector:@selector(addObjects:) object:objects];
	[filesController removeObjects:objects];

    [objects makeObjectsPerformSelector:@selector(cleanup)];
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation
{
    NSArray *objs = [filesController arrangedObjects];
    if (row < (signed)[objs count])
    {
        File *f = [objs objectAtIndex:row];
        return [f statusText];
    }
    return nil;
}

-(void)openRowInFinder:(NSInteger)row withPreview:(BOOL)preview {
    NSArray *files = [filesController arrangedObjects];
    if (row < [files count]) {
        File *f = [files objectAtIndex:row];
		if (preview) [[NSWorkspace sharedWorkspace] openFile:[f filePath]];
        else [[NSWorkspace sharedWorkspace] selectFile:[f filePath] inFileViewerRootedAtPath:@""];
    }    
}

// Better in NSArrayController class
- (NSUInteger)rowsAboveRow:(NSUInteger)row inIndexSet:(NSIndexSet *)indexSet
{
    NSUInteger currentIndex = [indexSet firstIndex];
    NSUInteger i = 0;
    while (currentIndex != NSNotFound)
    {
		if (currentIndex < row) { i++; }
		currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
    return i;
}
- (NSUInteger)numberOfRowsInTableView:(NSTableView *)tableview
{
	return [[filesController arrangedObjects] count];
}

-(void) moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)indexSet
										toIndex:(NSUInteger)insertIndex
{

    NSArray		*objects = [filesController arrangedObjects];
	NSUInteger	idx = [indexSet lastIndex];

    NSUInteger	aboveInsertIndexCount = 0;
    id			object;
    NSUInteger	removeIndex;

    while (NSNotFound != idx)
	{
		if (idx >= insertIndex) {
			removeIndex = idx + aboveInsertIndexCount;
			aboveInsertIndexCount += 1;
		}
		else
		{
			removeIndex = idx;
			insertIndex -= 1;
		}
		object = [objects objectAtIndex:removeIndex];
		[filesController removeObjectAtArrangedObjectIndex:removeIndex];
		[filesController insertObject:object atArrangedObjectIndex:insertIndex];

		idx = [indexSet indexLessThanIndex:idx];
    }
}


- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{

	NSPasteboard *pboard = [info draggingPasteboard];
	NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];

	if ([info draggingSource] == tableView){

		NSIndexSet  *indexSet = [filesController selectionIndexes];//[self indexSetFromRows:paths];

		[self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];
		NSUInteger rowsAbove = [self rowsAboveRow:row inIndexSet:indexSet];

		NSRange range = NSMakeRange(row - rowsAbove, [indexSet count]);
		indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
		[filesController setSelectionIndexes:indexSet];
		return YES;

	}else [self performSelectorInBackground:@selector(addPaths:) withObject:paths];

	[[aTableView window] makeKeyAndOrderFront:aTableView];

	return YES;
}

/** filesControllerLock must be locked before using this
	That's a dumb linear search. Would be nice to replace NSArray with NSSet or NSHashTable.
 */
-(File *)findFileByPath:(NSString *)path
{
    if (![seenPathHashes containsObject:path])
    {
        return nil;
    }

    for(File *f in [filesController content])
	{
		if ([path isEqualToString:[f filePath]])
		{
			return f;
		}
	}
	return nil;
}

-(void)addFileObjects:(NSArray *)files
{
	[[tableView undoManager] registerUndoWithTarget:self selector:@selector(deleteObjects:) object:files];
	[[tableView undoManager] setActionName:NSLocalizedString(@"Add",@"undo command name")];

    @synchronized (filesController) {
        if (nextInsertRow < 0 || nextInsertRow >= [[filesController arrangedObjects] count]) {
            [filesController addObjects:files];
        } else {
            NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(nextInsertRow, [files count])];
            [filesController insertObjects:files atArrangedObjectIndexes:set];
            nextInsertRow += [files count];
        }
    }

    [self updateProgressbar];
}

-(void)addPaths:(NSArray*)paths
{
    [self addPaths:paths filesOnly:NO];
}

/** filesOnly indicates that paths do not contain any directories */
-(void)addPaths:(NSArray*)paths filesOnly:(BOOL)filesOnly
{
    if (!isEnabled) {
        return;
    }

	NSMutableArray *toAdd = [NSMutableArray arrayWithCapacity:[paths count]];

    BOOL isDir = NO;
    NSFileManager *fm = filesOnly ? nil : [NSFileManager defaultManager];

    for(NSString *path in paths) {
        if (fm) {
            if (![fm fileExistsAtPath:path isDirectory:&isDir]) {
                NSLog(@"%@ doesn't exist", path);
                continue;
            }
        }

        if (!isDir) {
            File *f = [self findFileByPath:path];
            if (f) {
                if (![f isBusy]) [f enqueueWorkersInCPUQueue:cpuQueue fileIOQueue:fileIOQueue];
            }
            else {
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
}

-(BOOL)canClearComplete {
	for(File *f in [filesController arrangedObjects]) {
        if (f.isDone) return YES;
    }
    return NO;
}

-(void)clearComplete
{
    NSUInteger i=0;
    NSMutableIndexSet *set = [NSMutableIndexSet new];

    @synchronized (filesController) {
        for(File *f in [filesController arrangedObjects]) {
            if (f.isDone) [set addIndex:i];
            i++;
        }
        if ([set count]) {
            [filesController removeObjectsAtArrangedObjectIndexes:set];
        }
    }
    [self setRow:-1];
    [tableView setNeedsDisplay:YES];
}

-(BOOL)canStartAgainOptimized:(BOOL)optimized {
    NSArray *array = [filesController selectedObjects];
    if (![array count]) array = [filesController content];

    for(File *f in array) {
        if (!f.isBusy && (!optimized || f.isOptimized)) return YES;
    }
    return NO;
}

-(void)startAgainOptimized:(BOOL)optimized
{
    BOOL anyStarted = NO;
	@synchronized (filesController) {
        NSArray *files = [filesController selectedObjects];
        NSInteger selectionCount = [files count];

        // UI doesn't give a way to deselect all, so here's a substitute
        // when selecting "again" on file that doesn't need it, deselect
        if (1 == selectionCount) {
            File *file = [files objectAtIndex:0];
            if (file.isBusy || !file.isOptimized) {
                files = [files copy];
                [filesController setSelectedObjects:@[]];
            }
        }
        else if (!selectionCount) {
            files = [filesController content];
        }

        for(File *f in files) {
            if (!f.isBusy && (!optimized || f.isOptimized)) {
                [f enqueueWorkersInCPUQueue:cpuQueue fileIOQueue:fileIOQueue];
                anyStarted = YES;
            }
        }
    }

	if (!anyStarted) NSBeep();

	[self updateProgressbar];
}

-(void)updateProgressbar
{
	if (![self isAnyQueueBusy])
	{
		[progressBar stopAnimation:nil];
		[NSApp requestUserAttention:NSInformationalRequest];
	}
	else
	{
		[progressBar startAnimation:nil];
        [self waitInBackgroundForQueuesToFinish];
	}
}

-(void) quickLook
{
	if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
		[[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
	} else {
		[[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
	}
}


#define PNG_ENABLED 1
#define JPEG_ENABLED 2
#define GIF_ENABLED 4

-(int)typesEnabled {
    int types = 0;
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

    if ([defs boolForKey:@"PngCrushEnabled"] || [defs boolForKey:@"PngOutEnabled"] ||
        [defs boolForKey:@"OptiPngEnabled"] || [defs boolForKey:@"AdvPngEnabled"] || [defs boolForKey:@"ZopfliEnabled"])
    {
        types |= PNG_ENABLED;
    }

    if ([defs boolForKey:@"JpegOptimEnabled"] || [defs boolForKey:@"JpegTranEnabled"])
    {
        types |= JPEG_ENABLED;
    }

    if ([defs boolForKey:@"GifsicleEnabled"])
    {
        types |= GIF_ENABLED;
    }

    if (!types) types = PNG_ENABLED; // will show error in the list
    return types;
}


-(NSArray*)extensions {

    int types = [self typesEnabled];
    NSMutableArray *extensions = [NSMutableArray array];

    if (types & PNG_ENABLED)
    {
        [extensions addObject:@"png"]; [extensions addObject:@"PNG"];
    }
    if (types & JPEG_ENABLED)
    {
        [extensions addObjectsFromArray:[NSArray arrayWithObjects:@"jpg",@"JPG",@"jpeg",@"JPEG",nil]];
    }
    if (types & GIF_ENABLED)
    {
        [extensions addObject:@"gif"]; [extensions addObject:@"GIF"];
    }

    return extensions;
}


-(NSArray *)fileTypes {
    int types = [self typesEnabled];

    NSMutableArray *fileTypes = [NSMutableArray array];

    if (types & PNG_ENABLED)
    {
        [fileTypes addObjectsFromArray:[NSArray arrayWithObjects:@"png",@"PNG",NSFileTypeForHFSTypeCode( 'PNGf' ),@"public.png",@"image/png",nil]];
    }
    if (types & JPEG_ENABLED)
    {
        [fileTypes addObjectsFromArray:[NSArray arrayWithObjects:@"jpg",@"jpeg",@"JPG",@"JPEG",NSFileTypeForHFSTypeCode( 'JPEG' ),@"public.jpeg",@"image/jpeg",nil]];
    }
    if (types & GIF_ENABLED)
    {
        [fileTypes addObjectsFromArray:[NSArray arrayWithObjects:@"gif",@"GIF",NSFileTypeForHFSTypeCode( 'GIFf' ),@"public.gif",@"image/gif",nil]];
    }
	return fileTypes;
}

@end
