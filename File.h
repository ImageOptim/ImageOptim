//
//  File.h
//  ImageOptim
//
//  Created by porneL on 8.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WorkerQueue.h"

@interface File : NSObject <NSCopying, WorkerQueueDelegate> {
	NSString *filePath;
	NSString *displayName;
	
	long byteSize;
	long byteSizeOptimized;	
	float percentDone;
	
	NSString *filePathOptimized;
	
	NSRecursiveLock *lock;
	
	WorkerQueue *serialQueue;
	
	NSImage *statusImage;
	int workersActive;
	int workersFinished;
	int workersTotal;
	
	BOOL isBusy;
}

-(BOOL)isBusy;

-(void)enqueueWorkersInQueue:(WorkerQueue *)queue;

-(void)setFilePathOptimized:(NSString *)f size:(long)s;

-(id)initWithFilePath:(NSString *)name;
-(id)copyWithZone:(NSZone *)zone;
-(void)setByteSize:(long)size;
-(void)setByteSizeOptimized:(long)size;
-(BOOL)isOptimized;

-(void)setFilePath:(NSString *)s;

-(NSString *)fileName;
-(NSString *)filePath;
-(long)byteSize;
-(long)byteSizeOptimized;
-(float)percentDone;
-(void)setPercentDone:(float)d;

-(void)setStatus:(NSString *)name;
-(NSImage *)statusImage;
-(void)setStatusImage:(NSImage *)i;
@end
