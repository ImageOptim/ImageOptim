//
//  File.h
//  ImageOptim
//
//  Created by porneL on 8.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Worker.h"
@class WorkerQueue;

@interface File : Worker <NSCopying> {
	NSString *filePath;
	NSString *displayName;
	
	long byteSize;
	long byteSizeOptimized;	
	float percentDone;
	
	NSString *filePathOptimized;
	
	NSLock *lock;
	
	NSMutableArray *localWorkerQueue;
	WorkerQueue *queue;
}

-(void)setFilePathOptimized:(NSString *)f size:(long)s;

-(id)initInQueue:(WorkerQueue *)q withFilePath:(NSString *)name;
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


-(BOOL)enqueueWorkers;
@end
