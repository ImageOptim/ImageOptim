//
//  File.h
//
//  Created by porneL on 8.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import "Worker.h"

@interface File : NSObject <NSCopying, WorkerQueueDelegate> {
	NSString *filePath;
	NSString *displayName;
	
	long byteSize;
	long byteSizeOptimized;	
	double percentDone;
	
	NSString *filePathOptimized;	
		
	NSImage *statusImage;
    NSString *statusText;
    
    NSMutableArray *workers;
    
	int workersActive;
	int workersFinished;
	int workersTotal;
    
    NSOperationQueue *fileIOQueue;
}

-(BOOL)isBusy;

-(void)enqueueWorkersInCPUQueue:(NSOperationQueue *)queue fileIOQueue:(NSOperationQueue *)fileIOQueue;

-(void)setFilePathOptimized:(NSString *)f size:(long)s;

-(id)initWithFilePath:(NSString *)name;
-(id)copyWithZone:(NSZone *)zone;
-(void)setByteSize:(long)size;
-(void)setByteSizeOptimized:(long)size;
-(BOOL)isOptimized;

-(void)setFilePath:(NSString *)s;

-(NSString *)fileName;

@property (assign) long byteSize, byteSizeOptimized;
@property (retain) NSString *statusText, *filePath, *displayName;
@property (retain) NSImage *statusImage;

@property (assign) double percentDone;

-(void)setStatus:(NSString *)name text:(NSString*)text;
-(void)cleanup;

+(long)fileByteSize:(NSString *)afile;


-(void)doEnqueueWorkersInCPUQueue:(NSOperationQueue *)queue;
@end
