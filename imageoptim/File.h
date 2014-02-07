//
//  File.h
//
//  Created by porneL on 8.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "Workers/Worker.h"

enum IOFileType {
    FILETYPE_PNG=1,
    FILETYPE_JPEG,
    FILETYPE_GIF
};

@interface File : NSObject <NSCopying, QLPreviewItem> {
	NSURL *filePath;
	NSString *displayName;
	
    /** size of file before any optimizations */
	NSUInteger byteSizeOriginal;
    /** expected current size of file on disk, updated before and after optimization */
    NSUInteger byteSizeOnDisk;
    /** current best estimate of what optimized file size will be */
    NSUInteger byteSizeOptimized;

    NSString *bestToolName;
    NSMutableDictionary *bestTools;
	double percentDone;
	
    NSMutableSet *filePathsOptimizedInUse;
	NSURL *filePathOptimized;
		
	NSImage *statusImage;
    NSString *statusText;
    NSInteger statusOrder;
    
    NSMutableArray *workers;
    NSMutableDictionary *workersPreviousResults;

    NSOperationQueue *fileIOQueue;
    
    enum IOFileType fileType;
    BOOL done, optimized, lossyConverted;
}

-(BOOL)isBusy;
-(BOOL)isOptimized;
-(BOOL)isDone;

-(void)enqueueWorkersInCPUQueue:(NSOperationQueue *)queue fileIOQueue:(NSOperationQueue *)fileIOQueue;

-(BOOL)setFilePathOptimized:(NSURL *)f size:(NSUInteger)s toolName:(NSString*)s;

-(id)initWithFilePath:(NSURL *)name;
-(id)copyWithZone:(NSZone *)zone;
-(void)setByteSizeOriginal:(NSUInteger)size;
-(void)setByteSizeOptimized:(NSUInteger)size;
-(BOOL)isOptimized;
-(void)updateStatusOfWorker:(Worker *)currentWorker running:(BOOL)started;

-(BOOL)isLarge;
-(BOOL)isSmall;

-(void)setFilePath:(NSURL *)s;

-(NSString *)fileName;

@property (strong) NSString *statusText, *displayName, *bestToolName;
@property (strong,nonatomic) NSURL *filePath;
@property (strong,readonly) NSURL *filePathOptimized;
@property (strong) NSImage *statusImage;
@property (assign,nonatomic) NSUInteger byteSizeOriginal, byteSizeOptimized;
@property (assign,readonly) NSInteger statusOrder;
@property (strong,readonly) NSMutableDictionary *workersPreviousResults;
@property (assign) enum IOFileType fileType;

@property (assign) double percentDone;

-(void)setStatus:(NSString *)name order:(NSInteger)order text:(NSString*)text;
-(void)cleanup;

+(NSInteger)fileByteSize:(NSURL *)afile;


-(void)doEnqueueWorkersInCPUQueue:(NSOperationQueue *)queue;
@end
