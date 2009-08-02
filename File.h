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
	
	unsigned long byteSize;
    unsigned long byteSizeOptimized;	
	double percentDone;
	
	NSString *filePathOptimized;	
		
	NSImage *statusImage;
    NSString *statusText;
    
    NSMutableArray *workers;
    
	unsigned int workersActive;
	unsigned int workersFinished;
	unsigned int workersTotal;
    
    NSOperationQueue *fileIOQueue;
}

-(BOOL)isBusy;

-(void)enqueueWorkersInCPUQueue:(NSOperationQueue *)queue fileIOQueue:(NSOperationQueue *)fileIOQueue;

-(void)setFilePathOptimized:(NSString *)f size:(unsigned long)s;

-(id)initWithFilePath:(NSString *)name;
-(id)copyWithZone:(NSZone *)zone;
-(void)setByteSize:(unsigned long)size;
-(void)setByteSizeOptimized:(unsigned long)size;
-(BOOL)isOptimized;

-(void)setFilePath:(NSString *)s;

-(NSString *)fileName;

@property (assign) unsigned long byteSize, byteSizeOptimized;
@property (retain) NSString *statusText, *filePath, *displayName;
@property (retain) NSImage *statusImage;

@property (assign) double percentDone;

-(void)setStatus:(NSString *)name text:(NSString*)text;
-(void)cleanup;

+(long)fileByteSize:(NSString *)afile;


-(void)doEnqueueWorkersInCPUQueue:(NSOperationQueue *)queue;
@end
