//
//  File.m
//
//  Created by porneL on 8.wrz.07.
//

#import "File.h"
#import "ImageOptim.h"
#import "Workers/AdvCompWorker.h"
#import "Workers/PngoutWorker.h"
#import "Workers/OptiPngWorker.h"
#import "Workers/PngCrushWorker.h"
#import "Workers/ZopfliWorker.h"
#import "Workers/JpegoptimWorker.h"
#import "Workers/JpegtranWorker.h"
#import "Workers/GifsicleWorker.h"
#import <sys/xattr.h>
//#import "Dupe.h"

@implementation File

enum {
    FILETYPE_PNG=1,
    FILETYPE_JPEG,
    FILETYPE_GIF
};

@synthesize byteSize, byteSizeOptimized, filePath, displayName, statusText, statusOrder, statusImage, percentDone, bestToolName;

-(id)initWithFilePath:(NSString *)name;
{
	if (self = [self init])
	{	
		[self setFilePath:name];
		[self setStatus:@"wait" order:0 text:NSLocalizedString(@"New file",@"newly added to the queue")];
	}
	return self;	
}

-(BOOL)isLarge {
    if (fileType == FILETYPE_PNG) {
        return byteSize > 250*1024;
    }
    return byteSize > 1*1024*1024;
}

-(BOOL)isSmall {
    if (fileType == FILETYPE_PNG) {
        return byteSize < 2048;
    }
    return byteSize < 10*1024;
}

-(NSString *)fileName
{	
	if (displayName) return displayName;
	if (filePath) return filePath;
	return nil;
}

-(void)setFilePath:(NSString *)s
{
	if (filePath != s)
	{
		filePath = [s copy];
		
        self.displayName = [[NSFileManager defaultManager] displayNameAtPath:filePath];		
	}
}

- (id)copyWithZone:(NSZone *)zone
{
	File *f = [[File allocWithZone:zone] init];
	[f setByteSize:byteSize];
	[f setByteSizeOptimized:byteSizeOptimized];
	[f setFilePath:filePath];
	return f;
}

-(void)setByteSize:(NSUInteger)size
{
    @synchronized(self) 
    {        
        if (!byteSize && size > 10)
        {
            byteSize = size;
            if (!byteSizeOptimized || byteSizeOptimized > byteSize) [self setByteSizeOptimized:size];		
        }
    }
}

-(double)percentOptimized
{
	if (!byteSizeOptimized) return 0.0;
	double p = 100.0 - 100.0* (double)byteSizeOptimized/(double)byteSize;
	if (p<0) return 0.0;
	return p;
}

-(void)setPercentOptimized:(double)unused
{
	// just for KVO
}

-(BOOL)isOptimized
{
	return byteSizeOptimized < byteSize && (!runAgainByteSize || byteSizeOptimized < runAgainByteSize);
}

-(BOOL)isDone
{
	return done;
}

-(void)setByteSizeOptimized:(NSUInteger)size
{
    @synchronized(self) 
    {        
        if ((!byteSizeOptimized || size < byteSizeOptimized) && size > 30)
        {
            byteSizeOptimized = size;
            [self setPercentOptimized:0.0]; //just for KVO
        }
    }
}

-(void)removeOldFilePathOptimized
{
	if (filePathOptimized)
	{
        if ([filePathOptimized length])
        {
            [[NSFileManager defaultManager] removeItemAtPath:filePathOptimized error:nil];
        }
        filePathOptimized = nil;
	}
}

-(void)setFilePathOptimized:(NSString *)path size:(NSUInteger)size toolName:(NSString*)toolname
{
    @synchronized(self) 
    {        
        NSLog(@"File %@ optimized with %@ from %u to %u in %@",filePath?filePath:filePathOptimized,toolname,(unsigned int)byteSizeOptimized,(unsigned int)size,path);
        if (size < byteSizeOptimized)
        {
            self.bestToolName = [toolname stringByReplacingOccurrencesOfString:@"Worker" withString:@""];
            assert(![filePathOptimized isEqualToString:path]);
            [self removeOldFilePathOptimized];
            filePathOptimized = path;
            [self setByteSizeOptimized:size];
        }
    }
}

-(BOOL)removeExtendedAttr
{
    BOOL retVal = YES;
    
    // can add or remove keys as appropriate, or pass in as a param
    NSMutableDictionary *extAttrToRemove = [NSMutableDictionary dictionaryWithDictionary:
                                            @{
                                             @"com.apple.FinderInfo"  : [NSNumber numberWithInt:0],
                                             @"com.apple.ResourceFork": [NSNumber numberWithInt:0],
                                             @"com.apple.quarantine"  : [NSNumber numberWithInt:0]
                                            }
                                 ];
    // need a copy to enumerate
    NSDictionary *extAttrToRemoveCopy = [NSDictionary dictionaryWithDictionary:extAttrToRemove];
    
    const char *fileSystemPath = [filePath fileSystemRepresentation];
    
    size_t size = 0;
    
    ssize_t buf;
    
    // call with NULL for the char *namebuf param first
    // in this case the method returns the size of the attributes buffer
    buf = listxattr(fileSystemPath, NULL,  size, 0x0000);
    
    // so now we know the size
    size = (size_t)buf;
    
    char nameBuf[size];
    
    memset(&nameBuf, 0, sizeof(nameBuf));
    
    // get the list of xattrs
    buf = listxattr(fileSystemPath, nameBuf, size, 0x0000);
    
    // loop throough and see if they match any in our extAttrToRemove dict
    for (int i=0; i<size; i++) {        
        for (NSString *tmpStr in extAttrToRemoveCopy){
            if(strcmp(&nameBuf[i], [tmpStr UTF8String])  == 0){
                // if present set value to 1
                [extAttrToRemove setObject:[NSNumber numberWithInt:1] forKey:tmpStr];
            }
        }
    }
    
    NSLog(@"extAttrToRemove - set new atts = %@", extAttrToRemove);
    
    // loop through the extAttrToRemove dict
    for(NSString *tmpAtt in extAttrToRemove){
        // if value is 1 then remove
        if([[extAttrToRemove objectForKey:tmpAtt] isEqualToNumber:[NSNumber numberWithInt:1]]){
            if(removexattr(fileSystemPath, [tmpAtt UTF8String], 0x0000) == 0){
                NSLog(@"SUCCESS - set new atts.");
            }
            else{
                NSLog(@"Failed to set new atts. errno = %d", errno);
                retVal = NO;
            }
        }
    }
    
    return retVal;
}

-(BOOL)trashFileAtPath:(NSString*)path error:(NSError**)err
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *url = [NSURL fileURLWithPath:path];

    if ([fm respondsToSelector:@selector(trashItemAtURL:resultingItemURL:error:)]) { // 10.8
        return [fm trashItemAtURL:url resultingItemURL:nil error:err];
    } else {
        OSStatus status = 0;

        FSRef ref;
        status = FSPathMakeRefWithOptions((const UInt8 *)[path fileSystemRepresentation],
                                          kFSPathMakeRefDoNotFollowLeafSymlink,
                                          &ref, NULL);
        if (status != 0) {
            return NO;
        }

        status = FSMoveObjectToTrashSync(&ref, NULL, kFSFileOperationDefaultOptions);
        return status == 0;
    }
}

-(BOOL)saveResult
{
	if (!filePathOptimized)
	{
		NSLog(@"WTF? save without filePathOptimized? for %@", filePath);
		return NO;
	}
	
	@try
	{
		NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
		BOOL preserve = [defs boolForKey:@"PreservePermissions"];
		NSFileManager *fm = [NSFileManager defaultManager];
		
        NSError *error = nil;
        NSString *moveFromPath = filePathOptimized;

        if (![fm isWritableFileAtPath:[filePath stringByDeletingLastPathComponent]]) {
            NSLog(@"The file %@ is in non-writeable directory", filePath);
            return NO;
        }

        if (preserve)
        {
            NSString *writeToPath = [[[filePath stringByDeletingPathExtension] stringByAppendingString:@"~imageoptim"]
                                    stringByAppendingPathExtension:[filePath pathExtension]];

            if ([fm fileExistsAtPath:writeToPath]) {
                [self trashFileAtPath:writeToPath error:nil]; // ignore error, as copy will fail if file still exists
            }

            // move destination to temporary location that will be overwritten
            if (![fm moveItemAtPath:filePath toPath:writeToPath error:&error]) {
                NSLog(@"Can't move to %@ %@", writeToPath, error);
                return NO;
            }

            // copy original data for trashing under original file name
            if (![fm copyItemAtPath:writeToPath toPath:filePath error:&error]) {
                NSLog(@"Can't write to %@ %@", filePath, error);
                return NO;
            }

            [self removeExtendedAttr]; // clears filePath

            NSData *data = [NSData dataWithContentsOfFile:filePathOptimized];
            if (!data) {
                NSLog(@"Unable to read %@", filePathOptimized);
                return NO;
            }

            if ([data length] != byteSizeOptimized) {
                NSLog(@"Temp file size %u does not match expected %u in %@ for %@",(unsigned int)[data length],(unsigned int)byteSizeOptimized,filePathOptimized,filePath);
                return NO;
            }

            if ([data length] < 30) {
                NSLog(@"File %@ is suspiciously small, could be truncated", filePathOptimized);
                return NO;
            }

            // overwrite old file that is under temporary name (so only content is replaced, not file metadata)
			NSFileHandle *writehandle = [NSFileHandle fileHandleForWritingAtPath:writeToPath];
            if (!writehandle) {
                NSLog(@"Unable to open %@ for writing. Check file permissions.", filePath);
                return NO;
            }

            [writehandle writeData:data]; // this throws on failure
            [writehandle truncateFileAtOffset:[data length]];
            [writehandle closeFile];

            moveFromPath = writeToPath;
        }

        if (![self trashFileAtPath:filePath error:&error]) {
            NSLog(@"Can't trash %@ %@", filePath, error);
            return NO;
        }

        if (![fm moveItemAtPath:moveFromPath toPath:filePath error:&error]) {
            NSLog(@"Failed to move from %@ to %@; %@",moveFromPath, filePath, error);
            return NO;
        }

        if (!preserve) {
            [self removeExtendedAttr]; // clears filePath
        }

        filePathOptimized = nil;
	}
	@catch(NSException *e)
	{
		NSLog(@"Exception thrown %@ while saving %@",e, filePath);
		return NO;
	}
	
	return YES;
}

-(void)workerHasStarted:(Worker *)worker
{
	@synchronized(self)
    {
		workersActive++;
        NSString *name = [[worker className] stringByReplacingOccurrencesOfString:@"Worker" withString:@""];
        [self setStatus:@"progress" order:4 text:[NSString stringWithFormat:NSLocalizedString(@"Started %@",@"command name"),name]];
    }
}

-(void)saveResultAndUpdateStatus {
    BOOL saved = [self saveResult];
    [self removeOldFilePathOptimized];
    if (saved) {
        done = YES;
        [self setStatus:@"ok" order:7 text:[NSString stringWithFormat:NSLocalizedString(@"Optimized successfully with %@",@"tooltip"),bestToolName]];
    } else {
        [self setStatus:@"err" order:9 text:NSLocalizedString(@"Optimized file could not be saved",@"tooltip")];				
    }
}

-(void)workerHasFinished:(Worker *)worker
{
	@synchronized(self) 
    {
        workersActive--;
        workersFinished++;
       
        if (!workersActive)
        {
            if (!byteSize || !byteSizeOptimized)
            {
                NSLog(@"worker %@ finished, but result file has 0 size",worker);
                [self setStatus:@"err" order:8 text:NSLocalizedString(@"Size of optimized file is 0",@"tooltip")];
            }
            else if (workersFinished == workersTotal)
            {
                if ([self isOptimized])
                {
                    NSOperation *saveOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(saveResultAndUpdateStatus) object:nil];
                    [workers addObject:saveOp];
                    [fileIOQueue addOperation:saveOp];                    
                }
                else
                {
                    done = YES;
                    [self setStatus:@"noopt" order:5 text:NSLocalizedString(@"File cannot be optimized any further",@"tooltip")];
                    NSOperation *cleanup = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(removeOldFilePathOptimized) object:nil];
                    [fileIOQueue addOperation:cleanup];
                }
            }
            else
            {
                [self setStatus:@"wait" order:2 text:NSLocalizedString(@"Waiting to start more optimizations",@"tooltip")];
            }
        }
    }	    
}

//-(void)checkDupe:(NSData *)data {
//    Dupe *d = [[Dupe alloc] initWithData:data];
//    @synchronized(self) {
//        dupe = d;        
//    }
//    if ([Dupe isDupe:dupe])
//    {
//        [self cleanup];
//        [self setStatus:@"noopt" text:@"File was already optimized by ImageOptim"];
//    }
//    
//}


-(int)fileType:(NSData *)data
{
	const unsigned char pngheader[] = {0x89,0x50,0x4e,0x47,0x0d,0x0a};
    const unsigned char jpegheader[] = {0xff,0xd8,0xff};
    const unsigned char gifheader[] = {0x47,0x49,0x46,0x38};
    char filedata[6];

    [data getBytes:filedata length:sizeof(filedata)];
    
	if (0==memcmp(filedata, pngheader, sizeof(pngheader)))
	{
		return FILETYPE_PNG;
	}
    else if (0==memcmp(filedata, jpegheader, sizeof(jpegheader)))
    {
        return FILETYPE_JPEG;
    }
    else if (0==memcmp(filedata, gifheader, sizeof(gifheader)))
    {
        return FILETYPE_GIF;
    }
	return 0;
}

-(void)enqueueWorkersInCPUQueue:(NSOperationQueue *)queue fileIOQueue:(NSOperationQueue *)aFileIOQueue
{
    @synchronized(self)
    {
        workersActive++; // isBusy must say yes!

        fileIOQueue = aFileIOQueue; // will be used for saving
        workers = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    [self setStatus:@"wait" order:0 text:NSLocalizedString(@"Waiting in queue",@"tooltip")];
    
    NSOperation *actualEnqueue = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(doEnqueueWorkersInCPUQueue:) object:queue];
    if (queue.operationCount < queue.maxConcurrentOperationCount) {
        actualEnqueue.queuePriority = NSOperationQueuePriorityHigh;
    }

    [workers addObject:actualEnqueue];
    [fileIOQueue addOperation:actualEnqueue];        
}

typedef struct {NSString *key; Class class; void (^block)(Worker*);} worker_list_t;

-(void)doEnqueueWorkersInCPUQueue:(NSOperationQueue *)queue 
{  
    [self setStatus:@"progress" order:3 text:NSLocalizedString(@"Inspecting file",@"tooltip")];        
	
    NSData *fileData = [NSData dataWithContentsOfMappedFile:filePath];
    NSUInteger length = [fileData length];
    if (!fileData || !length)
    {
        [self setStatus:@"err" order:8 text:NSLocalizedString(@"Can't map file into memory",@"tooltip")]; 
        return;
    }

    fileType = [self fileType:fileData];

    BOOL hasBeenRunBefore;
    BOOL isQueueBig = [queue operationCount] > 10 && [queue operationCount] > [queue maxConcurrentOperationCount]*2;

    @synchronized(self)
    {
        workersActive--;

        filePathOptimized = nil;
        hasBeenRunBefore = (byteSize && byteSizeOptimized); // it's been set before, so it's now ran again

        if (hasBeenRunBefore && byteSize >= byteSizeOptimized) {
            if (byteSizeOptimized != length) { // file has changed
                runAgainByteSize = 0;
                byteSizeOptimized=0;
                [self setByteSize:length];
            } else {
                runAgainByteSize = length;
            }
        } else {
            [self setByteSize:length];
        }
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm isWritableFileAtPath:filePath]) {
        [self setStatus:@"err" order:9 text:NSLocalizedString(@"Optimized file could not be saved",@"tooltip")];
        return;
    }

	NSMutableArray *runFirst = [NSMutableArray new];
	NSMutableArray *runLater = [NSMutableArray new];

	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    
    worker_list_t *worker_list;
    int worker_list_length=0;

	if (fileType == FILETYPE_PNG)
	{
        worker_list = (worker_list_t[]){
            {@"PngCrushEnabled", [PngCrushWorker class]},
            {@"ZopfliEnabled", [ZopfliWorker class], ^(Worker *w){
                ((ZopfliWorker*)w).alternativeStrategy = hasBeenRunBefore;
            }},
            {@"OptiPngEnabled", [OptiPngWorker class]},
            {@"PngOutEnabled", [PngoutWorker class]},
            {@"AdvPngEnabled", [AdvCompWorker class]},
        };
        worker_list_length = 5;
	}
	else if (fileType == FILETYPE_JPEG)
    {
        worker_list = (worker_list_t[]){
            {@"JpegOptimEnabled", [JpegoptimWorker class]},
            {@"JpegTranEnabled", [JpegtranWorker class]},
        };
        worker_list_length = 2;
    }
	else if (fileType == FILETYPE_GIF)
    {
        if ([defs boolForKey:@"GifsicleEnabled"])
        {
            GifsicleWorker *w = [[GifsicleWorker alloc] initWithFile:self];
            w.interlace = NO;
            [runLater addObject:w];
            
            w = [[GifsicleWorker alloc] initWithFile:self];
            w.interlace = YES;
            [runLater addObject:w];
        }
    } else {
        [self setStatus:@"err" order:8 text:NSLocalizedString(@"File is neither PNG, GIF nor JPEG",@"tooltip")];
        [self cleanup];
        return;
    }
    
    for(int i=0; i < worker_list_length; i++) {
        if ([defs boolForKey:worker_list[i].key]) {
            Worker *w = [worker_list[i].class alloc];
            w = [w initWithFile:self];
            if (worker_list[i].block) worker_list[i].block(w);

            // generally optimizers that have side effects should always be run first, one at a time
            // unfortunately that makes whole process single-core serial when there are very few files
            // so for small queues rely on nextOperation to give some order when possible
            if ([w makesNonOptimizingModifications]) {
                if (isQueueBig || [self isSmall]) {
                    [runFirst addObject:w];
                } else {
                    [w setQueuePriority:NSOperationQueuePriorityHigh];
                    [runLater addObject:w];
                }
            } else {
                [runLater addObject:w];
            }
        }
    }

//    NSOperation *checkDupe = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(checkDupe:) object:fileData];
//    // largeish files are best to skip
//    if (length > 10000) [checkDupe setQueuePriority:NSOperationQueuePriorityHigh];
//    else if (length < 3000) [checkDupe setQueuePriority:NSOperationQueuePriorityLow];
//    [workers addObject:checkDupe];
//    [fileIOQueue addOperation:checkDupe];
    
	
	workersTotal += [runFirst count] + [runLater count];

	Worker *previousWorker = nil;
	for(Worker *w in runFirst) {
        if (previousWorker) {
            [w addDependency:previousWorker];
            previousWorker.nextOperation = w;
        } else if ([self isSmall]) {
            [w setQueuePriority: NSOperationQueuePriorityVeryLow];
        } else if (![self isLarge]) {
            [w setQueuePriority: NSOperationQueuePriorityLow];
        }
		[queue addOperation:w];
		previousWorker = w;
	}
	
	Worker *runFirstDependency = previousWorker;
	for(Worker *w in runLater) {
        if (runFirstDependency) {
            [w addDependency:runFirstDependency];
        }
        if (previousWorker) {
            previousWorker.nextOperation = w;
        }
		[queue addOperation:w];
        previousWorker = w;
	}	
	
    [workers addObjectsFromArray:runFirst];
    [workers addObjectsFromArray:runLater];
    
	if (!workersTotal) {
		[self setStatus:@"err" order:8 text:NSLocalizedString(@"All neccessary tools have been disabled in Preferences",@"tooltip")];
        [self cleanup];
	} else {
        [self setStatus:@"wait" order:1 text:NSLocalizedString(@"Waiting to be optimized",@"tooltip")];
    }
}

-(void)cleanup
{
    @synchronized(self)
    {
        [workers makeObjectsPerformSelector:@selector(cancel)];
        [workers removeAllObjects];
        [self removeOldFilePathOptimized];
    }
}

-(BOOL)isBusy
{
    BOOL isit;
    @synchronized(self)
    {
        isit = workersActive || workersTotal != workersFinished;        
    }
    return isit;
}

-(void)setStatus:(NSString *)imageName order:(NSInteger)order text:(NSString *)text
{
    void (^cb)() = ^{
        if (statusText == text) return;
        statusOrder = order;
        self.statusText = text;
        self.statusImage = [statusImages objectForKey:imageName];
    };
    if (statusText != nil) {
        dispatch_async(dispatch_get_main_queue(), cb);
    } else {
        cb();
    }
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"%@ %ld/%ld (workers active %ld, finished %ld, total %ld)", self.filePath,(long)self.byteSize,(long)self.byteSizeOptimized, (long)workersActive, (long)workersFinished, (long)workersTotal];
}

+(NSInteger)fileByteSize:(NSString *)afile
{
	NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:afile error:nil];
	if (attr) return [[attr objectForKey:NSFileSize] integerValue];
    NSLog(@"Could not stat %@",afile);
	return 0;
}

@end
