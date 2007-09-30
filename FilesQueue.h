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
}

-(id)initWithTableView:(NSTableView*)a andController:(NSArrayController*)b;
-(void)addFilesFromPaths:(NSArray *)paths;
-(void)addFile:(File *)f;
-(void)addFilePath:(NSString*)s;
-(void)setEnabled:(BOOL)y;
@end
