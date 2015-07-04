//
//  File.h
//
//  Created by porneL on 8.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "Workers/Worker.h"

@class ResultsDb;

enum IOFileType {
    FILETYPE_PNG=1,
    FILETYPE_JPEG,
    FILETYPE_GIF
};

@interface File : NSObject <NSCopying, QLPreviewItem> {
	NSURL *filePath, *revertPath;
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
		
	NSString *statusImageName;
    NSString *statusText;
    NSInteger statusOrder;
    
    NSMutableArray *workers;
    NSMutableDictionary *workersPreviousResults;

    NSOperationQueue *fileIOQueue;
    ResultsDb *db;
    uint32_t settingsHash[4];
    uint32_t inputFileHash[4];
    
    enum IOFileType fileType;
    BOOL done, optimized, stopping;
}

-(BOOL)isBusy;
-(BOOL)isStoppable;
-(BOOL)isOptimized;

-(BOOL)stop;
-(BOOL)revert;
@property (readonly) BOOL canRevert;
@property (readonly) BOOL isDone;

-(void)enqueueWorkersInCPUQueue:(nonnull NSOperationQueue *)queue fileIOQueue:(nonnull NSOperationQueue *)fileIOQueue defaults:(nonnull NSUserDefaults*)defaults;

-(BOOL)setFilePathOptimized:(nonnull NSURL *)f size:(NSUInteger)s toolName:(nonnull NSString *)s;

-(nullable instancetype)initWithFilePath:(nonnull NSURL *)aPath resultsDatabase:(nullable ResultsDb *)aDb;
-(nonnull id)copyWithZone:(nullable NSZone *)zone;
-(void)resetToOriginalByteSize:(NSUInteger)size;
-(void)setByteSizeOptimized:(NSUInteger)size;
-(void)updateStatusOfWorker:(nullable Worker *)currentWorker running:(BOOL)started;

-(BOOL)isLarge;
-(BOOL)isSmall;

-(void)setFilePath:(nonnull NSURL *)s;

@property (readonly, copy) NSString *__nonnull fileName;
@property (readonly, copy) NSString *__nullable mimeType;

@property (strong) NSString *__nullable statusText, *__nonnull displayName, *__nullable bestToolName;
@property (strong,nonatomic) NSURL *__nonnull filePath;
@property (strong,readonly) NSURL *__nonnull filePathOptimized;
@property (strong) NSString *__nonnull statusImageName;
@property (assign,nonatomic) NSUInteger byteSizeOriginal, byteSizeOptimized;
@property (assign,readonly) NSInteger statusOrder;
@property (strong,readonly) NSMutableDictionary *__nonnull workersPreviousResults;

@property (assign) double percentDone;

-(void)setStatus:(nonnull NSString *)name order:(NSInteger)order text:(nonnull NSString *)text;
-(void)cleanup;

+(NSInteger)fileByteSize:(nonnull NSURL *)afile;


-(void)doEnqueueWorkersInCPUQueue:(nonnull NSOperationQueue *)queue defaults:(nonnull NSUserDefaults*)defaults;
@end
