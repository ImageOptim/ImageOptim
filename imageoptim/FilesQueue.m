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
-(void)setEnabled:(BOOL)y;
-(void)updateProgressbar;

@end


@implementation FilesQueue

-(id)initWithTableView:(NSTableView*)inTableView progressBar:(NSProgressIndicator *)inBar andController:(NSArrayController*)inController
{
	progressBar = [inBar retain];
	filesController = [inController retain];
	tableView = [inTableView retain];
	seenPathHashes = [[NSHashTable alloc] initWithOptions:NSHashTableZeroingWeakMemory capacity:1000];

	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

    cpuQueue = [[NSOperationQueue alloc] init];
    [cpuQueue setMaxConcurrentOperationCount:[defs integerForKey:@"RunConcurrentTasks"]];

	dirWorkerQueue = [[NSOperationQueue alloc] init];
    [dirWorkerQueue setMaxConcurrentOperationCount:[defs integerForKey:@"RunConcurrentDirscans"]];

	fileIOQueue = [[NSOperationQueue alloc] init];
    NSUInteger fileops = [defs integerForKey:@"RunConcurrentFileops"];
    [fileIOQueue setMaxConcurrentOperationCount:fileops?fileops:3];

    queueWaitingLock = [NSLock new];

	[tableView setDelegate:self];
	[tableView setDataSource:self];
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,NSStringPboardType,nil]];

	[self setEnabled:YES];

	return self;
}


-(BOOL)isAnyQueueBusy
{
	if ([dirWorkerQueue respondsToSelector:@selector(operationCount)])
	{
		assert(NSFoundationVersionNumber >= (1.0+kCFCoreFoundationVersionNumber10_5));
		return dirWorkerQueue.operationCount || fileIOQueue.operationCount || cpuQueue.operationCount;
	}
	else
	{
		assert(NSFoundationVersionNumber < (1.0+kCFCoreFoundationVersionNumber10_5));
		return dirWorkerQueue.operations.count || fileIOQueue.operations.count || cpuQueue.operations.count;
	}
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

-(void)setEnabled:(BOOL)y;
{
	isEnabled = y;
	[tableView setEnabled:y];
}

-(BOOL)enabled
{
	return isEnabled;
}

-(void)cleanup {
    isEnabled = NO;
    [dirWorkerQueue cancelAllOperations];
    [fileIOQueue cancelAllOperations];
    [cpuQueue cancelAllOperations];
    for(File *f in [filesController content])
    {
        [f cleanup];
    }
}

- (NSDragOperation)tableView:(NSTableView *)atableView
                validateDrop:(id <NSDraggingInfo>)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)operation
{
	if (!isEnabled) return NSDragOperationNone;

	[filesControllerLock lock];

	[atableView setDropRow:[[filesController arrangedObjects] count] dropOperation:NSTableViewDropAbove];

	[filesControllerLock unlock];
	return NSDragOperationCopy;
}

-(IBAction)delete:(id)sender
{
//	NSLog(@"delete action");

    NSArray *files = nil;
	[filesControllerLock lock];

	if ([filesController canRemove])
	{
        files = [filesController selectedObjects];
		[filesController removeObjects:files];
    }

    if (files)
    {
//        NSLog(@"Removing %@",files);
        for(File *f in files)
        {
            [f cleanup];
        }
    }
    else NSBeep();
	[filesControllerLock unlock];

    [self runAdded];
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation
{
    //NSLog(@"Tooltip for col %@ in row %d",aTableColumn,row);
    NSArray *objs = [filesController arrangedObjects];
    if (row < (signed)[objs count])
    {
        File *f = [objs objectAtIndex:row];
        return [f statusText];
    }
    return nil;
}

-(void)openRowInFinder:(NSInteger)row withPreview:(BOOL)preview {
    NSArray *objs = [filesController arrangedObjects];
    if (row >= 0 && row < [objs count])
    {
        File *f = [objs objectAtIndex:row];
		if (preview) [[NSWorkspace sharedWorkspace] openFile:[f filePath]];
        else [[NSWorkspace sharedWorkspace] selectFile:[f filePath] inFileViewerRootedAtPath:@""];
    }    
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard *pboard = [info draggingPasteboard];
	NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];

//	NSLog(@"Dropping files %@",paths);
	[self performSelectorInBackground:@selector(addPaths:) withObject:paths];

	[[aTableView window] makeKeyAndOrderFront:aTableView];

//	NSLog(@"Finished adding drop");
	return YES;
}

-(void)addDir:(NSString *)path
{
    if (!isEnabled) return;

    @try {
        DirWorker *w = [[DirWorker alloc] initWithPath:path filesQueue:self extensions:[self extensions]];
        [dirWorkerQueue addOperation:w];
    }
    @catch (NSException *e) {
        NSLog(@"Add dir failed %@",e);
    }

    [self runAdded];
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
	for(File *f in files)
	{
		[filesController addObject:f];
		[f enqueueWorkersInCPUQueue:cpuQueue fileIOQueue:fileIOQueue];
	}

    [self runAdded];
}

-(void)addFilePaths:(NSArray*)paths
{
	NSMutableArray *toAdd = [NSMutableArray arrayWithCapacity:[paths count]];
	BOOL beepWhenDone = NO;

	[filesControllerLock lock];
	@try {
		for(NSString *path in paths)
		{
			if ([path characterAtIndex:[path length]-1] == '~') // backup file
			{
				NSLog(@"Refusing to optimize backup file");
				beepWhenDone = YES;
				continue;
			}

			File *f = [self findFileByPath:path];
			if (f)
			{
				if (![f isBusy]) [f enqueueWorkersInCPUQueue:cpuQueue fileIOQueue:fileIOQueue];;
			}
			else
			{
				[seenPathHashes addObject:path]; // used by findFileByPath
				f = [[File alloc] initWithFilePath:path];
				[toAdd addObject:f];
			}
		}

		[self performSelectorOnMainThread:@selector(addFileObjects:) withObject:toAdd waitUntilDone:YES];
	}
	@catch (NSException *e) {
		NSLog(@"add file path failed %@",e);
	}
	@finally {
		[filesControllerLock unlock];
	}

	if (beepWhenDone) NSBeep();
}

-(void)addPath:(NSString *)path
{
	if (!isEnabled) {
        return;
    }

	BOOL isDir;
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir])
	{
		if (!isDir)
		{
			[self performSelectorOnMainThread:@selector(addFilePaths:) withObject:[NSArray arrayWithObject:path] waitUntilDone:NO];
		}
		else
		{
			[self addDir:path];
		}
	}
}

-(void)runAdded
{
	[self updateProgressbar];
    [self waitInBackgroundForQueuesToFinish];
}

-(void)startAgain
{
    BOOL anyStarted = NO;
	[filesControllerLock lock];
    @try {
        NSArray *array = [filesController selectedObjects];
        if (![array count]) array = [filesController content];


        for(File *f in array)
        {
            if (![f isBusy])
            {
                [f enqueueWorkersInCPUQueue:cpuQueue fileIOQueue:fileIOQueue];
                anyStarted = YES;
            }
        }

    }
    @finally {
        [filesControllerLock unlock];
    }

	if (!anyStarted) NSBeep();

	[self runAdded];
}

-(void)updateProgressbar
{
	if (![self isAnyQueueBusy])
	{
        //NSLog(@"Done!");
		[progressBar stopAnimation:nil];
		[[NSApplication sharedApplication] requestUserAttention:NSInformationalRequest];
		[tableView setNeedsDisplay:YES];
	}
	else
	{
//        NSLog(@"There are still operations to do: %@ %@",workerQueue.operations,dirWorkerQueue.operations);
		[progressBar startAnimation:nil];
        [self waitInBackgroundForQueuesToFinish];
	}
}

-(void)addPaths:(NSArray *)paths
{
	for(NSString *path in paths)
	{
		[self addPath:path];
	}

    [self runAdded];
}

-(void) quickLook {

    NSMutableArray *args;

    if (currentQLManageTask && [currentQLManageTask isRunning])
    {
        [currentQLManageTask interrupt];
        currentQLManageTask = nil;
        return;
    }

    [filesControllerLock lock];
    @try {
        NSArray *files = [filesController selectedObjects];
        args = [NSMutableArray arrayWithCapacity:2+[files count]];
        [args addObject:@"-p"];
        [args addObject:@"--"];
        for(File *f in files)
        {
            [args addObject:f.filePath];
        }
    }
    @finally {
        [filesControllerLock unlock];
    }

    @try {
        NSTask *qltask = [[NSTask alloc] init];
        [qltask setLaunchPath:@"/usr/bin/qlmanage"];
        [qltask setStandardError:[NSFileHandle fileHandleWithNullDevice]];
        [qltask setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
        [qltask setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
        [qltask setArguments:args];
        [qltask launch];

        currentQLManageTask = qltask;
    }
    @catch(NSException *e) {
        NSLog(@"Can't run quicklook %@",e);
    }
}


#define PNG_ENABLED 1
#define JPEG_ENABLED 2
#define GIF_ENABLED 4

-(int)typesEnabled {
    int types = 0;
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

    if ([defs boolForKey:@"PngCrush.Enabled"] || [defs boolForKey:@"PngOut.Enabled"] ||
        [defs boolForKey:@"OptiPng.Enabled"] || [defs boolForKey:@"AdvPng.Enabled"])
    {
        types |= PNG_ENABLED;
    }

    if ([defs boolForKey:@"JpegOptim.Enabled"] || [defs boolForKey:@"JpegTran.Enabled"])
    {
        types |= JPEG_ENABLED;
    }

    if ([defs boolForKey:@"Gifsicle.Enabled"])
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
