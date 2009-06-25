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
	
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
	workerQueue = [[NSOperationQueue alloc] init];
    [workerQueue setMaxConcurrentOperationCount:[defs integerForKey:@"RunConcurrentTasks"]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(workersHaveFinished) name:@"WorkersMayHaveFinished" object:nil];
	
	dirWorkerQueue = [[NSOperationQueue alloc] init];
    [dirWorkerQueue setMaxConcurrentOperationCount:[defs integerForKey:@"RunConcurrentDirscans"]];	
	
	[tableView setDelegate:self];
	[tableView setDataSource:self];
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,NSStringPboardType,nil]];
    
	[self setEnabled:YES];	
    
    //[NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(updateProgressbar) userInfo:nil repeats:YES];
    
	return self;
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
	if (![self enabled]) return;

	DirWorker *w = [[DirWorker alloc] initWithPath:path filesQueue:self];
	[dirWorkerQueue addOperation:w];
	[w autorelease];
}

/** filesControllerLock must be locked before using this
	That's a dumb linear search. Would be nice to replace NSArray with NSSet or NSHashTable.
 */
-(File *)findFileByPath:(NSString *)path
{
	NSArray *array = [filesController content];
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
            f = [[File alloc] initWithFilePath:path];
            [filesController performSelectorOnMainThread:@selector(addObject:) withObject:f waitUntilDone:NO];
            [f enqueueWorkersInQueue:workerQueue];
            [f autorelease];					
        }            
    }
    @finally {
        [filesControllerLock unlock];
    }
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
			[self addFilePath:path];
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

-(void)workersHaveFinishedMainThread
{
    [self updateProgressbar];
    [self performSelector:@selector(updateProgressbar) withObject:nil afterDelay:1.0]; // FIXME: fudge to avoid race conditions
}

-(void)workersHaveFinished
{
    [self performSelectorOnMainThread:@selector(workersHaveFinishedMainThread) withObject:nil waitUntilDone:NO];
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
