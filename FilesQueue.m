//
//  FilesQueue.m
//
//  Created by porneL on 23.wrz.07.
//
#import "File.h"
#import "FilesQueue.h"

#import "DirWorker.h"

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
    
    
    //[NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(updateProgressbar) userInfo:nil repeats:YES];
    
	return self;
}


-(void)waitForQueuesToFinish {   
    
    if ([queueWaitingLock tryLock])
    {
        @try{            
            [cpuQueue waitUntilAllOperationsAreFinished];
            [dirWorkerQueue waitUntilAllOperationsAreFinished];            
            [fileIOQueue waitUntilAllOperationsAreFinished];
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
                 proposedRow:(int)row 
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
    
    [self runAdded];
	[filesControllerLock unlock];
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation
{
    //NSLog(@"Tooltip for col %@ in row %d",aTableColumn,row);
    NSArray *objs = [filesController arrangedObjects];
    if (row < [objs count])
    {
        File *f = [objs objectAtIndex:row];
        return [f statusText];
    }
    return nil;
}

-(void)openRowInFinder:(int)row
{    
    NSArray *objs = [filesController arrangedObjects];
    if (row < [objs count])
    {
        File *f = [objs objectAtIndex:row];
        [[NSWorkspace sharedWorkspace] selectFile:[f filePath] inFileViewerRootedAtPath: @""];
    }    
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard *pboard = [info draggingPasteboard];
	NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];
	
//	NSLog(@"Dropping files %@",paths);
	[self addPaths:paths];

	[[aTableView window] makeKeyAndOrderFront:aTableView];
	
//	NSLog(@"Finished adding drop");	
	return YES;
}

-(void)addDir:(NSString *)path
{
    @try {            
        if (!isEnabled) return;

        DirWorker *w = [[DirWorker alloc] initWithPath:path filesQueue:self];
        [dirWorkerQueue addOperation:w];
        ;            
        [self waitInBackgroundForQueuesToFinish];
    }
    @catch (NSException *e) {
        NSLog(@"Add dir failed %@",e);
    }
}

/** filesControllerLock must be locked before using this
	That's a dumb linear search. Would be nice to replace NSArray with NSSet or NSHashTable.
 */
-(File *)findFileByPath:(NSString *)path
{
	NSArray *array = [filesController content];
    
    if (![seenPathHashes containsObject:path])
    {
        return nil;
    }
    
    for(File *f in array)
	{
		if ([path isEqualToString:[f filePath]])
		{
			return f;
		}
	}
	return nil;
}

-(void)addFilePath:(NSString*)path {
    if ([path characterAtIndex:[path length]-1] == '~')
    {
        NSBeep();
        return;
    }
    
    [filesControllerLock lock];    
    
    @try {  
        File *f;
        if (f = [self findFileByPath:path])
        {
            if (![f isBusy]) [f enqueueWorkersInCPUQueue:cpuQueue fileIOQueue:fileIOQueue];;
        }
        else
        {
            [seenPathHashes addObject:path];
            f = [[File alloc] initWithFilePath:path];
            [filesController addObject:f];
            [f enqueueWorkersInCPUQueue:cpuQueue fileIOQueue:fileIOQueue];
        }            
    }
    @catch (NSException *e) {
        NSLog(@"add file path failed %@",e);
    }
    @finally {
        [filesControllerLock unlock];
    }
    [self waitInBackgroundForQueuesToFinish];
}

-(void)addPath:(NSString *)path dirs:(BOOL)useDirs
{	
	if (!isEnabled) {
        NSLog(@"Ignored %@",path);
        return;   
    }
	
	BOOL isDir;
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir])
	{		
		if (!isDir)
		{
			[self performSelectorOnMainThread:@selector(addFilePath:) withObject:path waitUntilDone:NO];
		}
		else if (useDirs)
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
	if (![cpuQueue.operations count] && ![dirWorkerQueue.operations count])
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
	}
}

-(void)addFilePaths:(NSArray *)paths 
{
    for(NSString *path in paths)
	{
		[self addFilePath:path];
	}
}
-(void)addPaths:(NSArray *)paths
{
    //NSLog(@"Adding paths %@",paths);
	for(NSString *path in paths)
	{
		[self addPath:path dirs:YES];
	}
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

@end
