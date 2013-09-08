//
//  File.h
//
//  Created by porneL on 8.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "Workers/Worker.h"

@interface File : NSObject <NSCopying, WorkerQueueDelegate, QLPreviewItem> {
	NSString *filePath;
	NSString *displayName;
	
    /** size of file before any optimizations */
	NSUInteger byteSizeOriginal;
    /** expected current size of file on disk, updated before and after optimization */
    NSUInteger byteSizeOnDisk;
    /** current best estimate of what optimized file size will be */
    NSUInteger byteSizeOptimized;

    NSString *bestToolName;
	double percentDone;
	
	NSString *filePathOptimized;	
		
	NSImage *statusImage;
    NSString *statusText;
    NSInteger statusOrder;
    
    NSMutableArray *workers;
    NSMutableDictionary *workersPreviousResults;
    
	NSUInteger workersActive;
	NSUInteger workersFinished;
	NSUInteger workersTotal;
    
    NSOperationQueue *fileIOQueue;
    
    int fileType;
    BOOL done, optimized;
}

-(BOOL)isBusy;
-(BOOL)isOptimized;
-(BOOL)isDone;

-(void)enqueueWorkersInCPUQueue:(NSOperationQueue *)queue fileIOQueue:(NSOperationQueue *)fileIOQueue;

-(BOOL)setFilePathOptimized:(NSString *)f size:(NSUInteger)s toolName:(NSString*)s;

-(id)initWithFilePath:(NSString *)name;
-(id)copyWithZone:(NSZone *)zone;
-(void)setByteSizeOriginal:(NSUInteger)size;
-(void)setByteSizeOptimized:(NSUInteger)size;
-(BOOL)isOptimized;


-(BOOL)isLarge;
-(BOOL)isSmall;

-(void)setFilePath:(NSString *)s;

-(NSString *)fileName;

@property (retain) NSString *statusText, *filePath, *displayName, *bestToolName;
@property (retain) NSImage *statusImage;
@property (assign,nonatomic) NSUInteger byteSizeOriginal, byteSizeOptimized;
@property (assign,readonly) NSInteger statusOrder;
@property (retain,readonly) NSMutableDictionary *workersPreviousResults;

@property (assign) double percentDone;

-(void)setStatus:(NSString *)name order:(NSInteger)order text:(NSString*)text;
-(void)cleanup;

+(NSInteger)fileByteSize:(NSString *)afile;


-(void)doEnqueueWorkersInCPUQueue:(NSOperationQueue *)queue;
@end
