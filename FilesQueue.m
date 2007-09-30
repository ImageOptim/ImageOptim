//
//  FilesQueue.m
//  ImageOptim
//
//  Created by porneL on 23.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
#import "File.h"
#import "FilesQueue.h"
#import "WorkerQueue.h"
#import "PngoutWorker.h"
#import "DirWorker.h"
@implementation FilesQueue

-(id)initWithTableView:(NSTableView*)inTableView andController:(NSArrayController*)inController
{
	filesController = [inController retain];
	tableView = [inTableView retain];
	workerQueue = [[WorkerQueue alloc] initWithDefaultsKey:@"RunConcurrentTasks"];
	dirWorkerQueue = [[WorkerQueue alloc] initWithDefaultsKey:@"RunConcurrentDirscans"];	
	
	[tableView setDelegate:self];
	[tableView setDataSource:self];
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,NSStringPboardType,nil]];
	
	[self setEnabled:YES];
	return self;
}

-(void)dealloc
{
	[filesController release];
//	[tableView unregisterDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,NSStringPboardType,nil]];
	[tableView release];
	[workerQueue release];
	[dirWorkerQueue release];
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
	
	[atableView setDropRow:[[filesController arrangedObjects] count] dropOperation:NSTableViewDropAbove];
	return NSDragOperationCopy;
}

-(IBAction)delete:(id)sender
{
	NSLog(@"delete action");
	if ([filesController canRemove])
	{
		[filesController remove:sender];		
	}
	else NSBeep();
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard *pboard = [info draggingPasteboard];
	NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];
	
	[self addFilesFromPaths:paths];
	
	return YES;
}

-(void)addFile:(File *)f
{
	if (![self enabled]) return;
	
	[filesController addObject:f];
	
	PngoutWorker *w = [[PngoutWorker alloc] initWithFile:f inQueue:workerQueue];
	[workerQueue addWorker:w];
	[w release];
}

-(void)addDir:(NSString *)path
{
	if (![self enabled]) return;

	DirWorker *w = [[DirWorker alloc] initWithPath:path filesQueue:self];
	[dirWorkerQueue addWorker:w];
	[w release];
}

-(void)addFilePath:(NSString *)path
{	
	BOOL isDir;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir])
	{
		if (!isDir)
		{
			File *f = [[File alloc] initWithFilePath:path];
			[self addFile:f];
			[f release];					
		}
		else
		{
			[self addDir:path];
		}
	}
}

-(void)addFilesFromPaths:(NSArray *)paths
{
	int i;
	for(i=0; i < [paths count]; i++)
	{
		[self addFilePath:[paths objectAtIndex:i]];
	}	
}

@end
