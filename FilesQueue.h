//
//  FilesQueue.h
//  ImageOptim
//
//  Created by porneL on 23.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class File;
@class WorkerQueue;

@interface FilesQueue : NSObject {
	NSTableView *tableView;
	NSArrayController *filesController;
	BOOL isEnabled;
	
	WorkerQueue *workerQueue;
	WorkerQueue *dirWorkerQueue;	
	
	NSRecursiveLock *filesControllerLock;
	
	NSProgressIndicator *progressBar;
}

-(id)initWithTableView:(NSTableView*)a progressBar:(NSProgressIndicator *)p andController:(NSArrayController*)b;
-(void)addFilesFromPaths:(NSArray *)paths;
-(void)addFilePath:(NSString*)s dirs:(BOOL)a;
-(void)addFilesFromPaths:(NSArray *)paths;
-(void)setEnabled:(BOOL)y;

-(void)runAdded;

-(IBAction)delete:(id)sender;

-(void)workersHaveFinished:(WorkerQueue *)q;

-(void)updateProgressbar;
@end
