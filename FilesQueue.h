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
}

-(id)initWithTableView:(NSTableView*)a andController:(NSArrayController*)b;
-(void)addFilesFromPaths:(NSArray *)paths;
-(void)addFilePath:(NSString*)s dirs:(BOOL)a;
-(void)addFilesFromPaths:(NSArray *)paths;
-(void)setEnabled:(BOOL)y;


-(IBAction)delete:(id)sender;

@end
