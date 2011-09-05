//
//  File.h
//
//  Created by porneL on 8.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import "Workers/Worker.h"

@interface File : NSObject <NSCopying, WorkerQueueDelegate> {
	NSString *filePath;
	NSString *displayName;

	NSUInteger byteSize;
    NSUInteger byteSizeOptimized;
    NSString *bestToolName;
	double percentDone;

	NSString *filePathOptimized;

	NSImage *statusImage;
    NSString *statusText;
    NSInteger statusOrder;

    NSMutableArray *workers;

	NSUInteger workersActive;
	NSUInteger workersFinished;
	NSUInteger workersTotal;

    NSOperationQueue *fileIOQueue;
    
    BOOL done;
}

-(BOOL)isBusy;
-(BOOL)isOptimized;
-(BOOL)isDone;

-(void)enqueueWorkersInCPUQueue:(NSOperationQueue *)queue fileIOQueue:(NSOperationQueue *)fileIOQueue;

-(void)setFilePathOptimized:(NSString *)f size:(NSUInteger)s toolName:(NSString*)s;

-(id)initWithFilePath:(NSString *)name;
-(id)copyWithZone:(NSZone *)zone;
-(void)setByteSize:(NSUInteger)size;
-(void)setByteSizeOptimized:(NSUInteger)size;
-(BOOL)isOptimized;

-(void)setFilePath:(NSString *)s;

-(NSString *)fileName;

@property (assign) NSUInteger byteSize, byteSizeOptimized;
@property (retain) NSString *statusText, *filePath, *displayName;
@property (retain) NSImage *statusImage;
@property (assign,readonly) NSInteger statusOrder;

@property (assign) double percentDone;

-(void)setStatus:(NSString *)name order:(NSInteger)order text:(NSString*)text;
-(void)cleanup;

+(NSInteger)fileByteSize:(NSString *)afile;


-(void)doEnqueueWorkersInCPUQueue:(NSOperationQueue *)queue;
@end
