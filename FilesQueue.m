//
//  FilesQueue.m
//  ImageOptim
//
//  Created by porneL on 23.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
#import "File.h"
#import "FilesQueue.h"
#import "PngoutWorker.h"

@implementation FilesQueue

-(id)initWithTableView:(NSTableView*)inTableView andController:(NSArrayController*)inController
{
	filesController = inController;
	tableView = inTableView;	
	workers = [NSMutableArray new];
	workerQueue = [[WorkerQueue alloc] init];
	
	[tableView setDelegate:self];
	[tableView setDataSource:self];
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,NSStringPboardType,nil]];
	
	[self setEnabled:YES];
	return self;
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
	[workers addObject:w];
	[w release];
	
	[w runAsync];
}

-(void)addFilePath:(NSString *)path
{	
	File *f = [[File alloc] initWithFilePath:path];
	[self addFile:f];
	[f release];
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
