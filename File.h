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
	
	NSLock *lock;
	
	WorkerQueue *serialQueue;
}

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

@end
