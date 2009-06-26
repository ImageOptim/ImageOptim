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
	
	workerQueue = [[NSOperationQueue alloc] init];
    [workerQueue setMaxConcurrentOperationCount:[defs integerForKey:@"RunConcurrentTasks"]];
	
	dirWorkerQueue = [[NSOperationQueue alloc] init];
    [dirWorkerQueue setMaxConcurrentOperationCount:[defs integerForKey:@"RunConcurrentDirscans"]];	
	
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
            [workerQueue waitUntilAllOperationsAreFinished];
            [dirWorkerQueue waitUntilAllOperationsAreFinished];            
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

-(void)dealloc
{
	[progressBar release]; progressBar = nil;
	[filesControllerLock release]; filesControllerLock = nil;
	[filesController release]; filesController = nil;
//	[tableView unregisterDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,NSStringPboardType,nil]];
	[tableView release]; tableView = nil;
	[workerQueue release]; workerQueue = nil;
	[dirWorkerQueue release]; dirWorkerQueue = nil;
    [seenPathHashes release]; seenPathHashes = nil;
	[super dealloc];
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

- (NSDragOperation)tableView:(NSTableView *)atableView 
                validateDrop:(id <NSDraggingInfo>)info 
                 proposedRow:(int)row 
       proposedDropOperation:(NSTableViewDropOperation)operation
{
	if (![self enabled]) return NSDragOperationNone;

	[filesControllerLock lock];

	[atableView setDropRow:[[filesController arrangedObjects] count] dropOperation:NSTableViewDropAbove];
	
	[filesControllerLock unlock];
	return NSDragOperationCopy;
}

-(IBAction)delete:(id)sender
{
//	NSLog(@"delete action");
	[filesControllerLock lock];

	if ([filesController canRemove])
	{
		[filesController remove:sender];
		[self runAdded];
	}
	else NSBeep();
	
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
	[self addFilesFromPaths:paths];

	[[aTableView window] makeKeyAndOrderFront:aTableView];
	
//	NSLog(@"Finished adding drop");	
	return YES;
}

-(void)addDir:(NSString *)path
{
    @try {            
        if (![self enabled]) return;

        DirWorker *w = [[DirWorker alloc] initWithPath:path filesQueue:self];
        [dirWorkerQueue addOperation:w];
        [w release];            
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
            if (![f isBusy]) [f enqueueWorkersInQueue:workerQueue];
        }
        else
        {
            [seenPathHashes addObject:path];
            f = [[File alloc] initWithFilePath:path];
            [filesController addObject:f];
            [f enqueueWorkersInQueue:workerQueue];
            [f release];					
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
	if (![self enabled]) {
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
                [f enqueueWorkersInQueue:workerQueue];
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
	if (![workerQueue.operations count] && ![dirWorkerQueue.operations count])
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

-(void)addFilesFromPaths:(NSArray *)paths
{
    //NSLog(@"Adding paths %@",paths);
	for(NSString *path in paths)
	{
		[self addPath:path dirs:YES];
	}
}

@end
