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
#import "log.h"

@implementation File

enum {
    FILETYPE_PNG=1,
    FILETYPE_JPEG,
    FILETYPE_GIF
};

@synthesize workersPreviousResults, byteSizeOriginal, byteSizeOptimized, filePath, displayName, statusText, statusOrder, statusImage, percentDone, bestToolName;

-(id)initWithFilePath:(NSString *)name;
{
    if (self = [self init])
    {
        workersPreviousResults = [NSMutableDictionary new];
        [self setFilePath:name];
        [self setStatus:@"wait" order:0 text:NSLocalizedString(@"New file",@"newly added to the queue")];
    }
    return self;
}

-(BOOL)isLarge {
    if (fileType == FILETYPE_PNG) {
        return byteSizeOriginal > 250*1024;
    }
    return byteSizeOriginal > 1*1024*1024;
}

-(BOOL)isSmall {
    if (fileType == FILETYPE_PNG) {
        return byteSizeOriginal < 2048;
    }
    return byteSizeOriginal < 10*1024;
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
    [f setByteSizeOriginal:byteSizeOriginal];
    [f setByteSizeOptimized:byteSizeOptimized];
    [f setFilePath:filePath];
    return f;
}

-(void)setByteSizeOriginal:(NSUInteger)size
{
    byteSizeOriginal = size;
    byteSizeOnDisk = size;
    [self setByteSizeOptimized:size];
}

-(double)percentOptimized
{
    if (!byteSizeOptimized) return 0.0;
    double p = 100.0 - 100.0* (double)byteSizeOptimized/(double)byteSizeOriginal;
    if (p<0) return 0.0;
    return p;
}

-(void)setPercentOptimized:(double)unused
{
    // just for KVO
}

-(BOOL)isOptimized
{
    return byteSizeOptimized < byteSizeOriginal && (optimized || byteSizeOptimized < byteSizeOnDisk);
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
        [[NSFileManager defaultManager] removeItemAtPath:filePathOptimized error:nil];
        filePathOptimized = nil;
    }
}

-(BOOL)setFilePathOptimized:(NSString *)tempPath size:(NSUInteger)size toolName:(NSString*)toolname
{
    @synchronized(self)
    {
        IODebug("File %@ optimized with %@ from %u to %u in %@",filePath?filePath:filePathOptimized,toolname,(unsigned int)byteSizeOptimized,(unsigned int)size,tempPath);
        if (size < byteSizeOptimized)
        {
            self.bestToolName = [toolname stringByReplacingOccurrencesOfString:@"Worker" withString:@""];
            assert(![filePathOptimized isEqualToString:tempPath]);
            [self removeOldFilePathOptimized];
            filePathOptimized = tempPath;
            [self setByteSizeOptimized:size];
            return YES;
        }
    }
    return NO;
}

-(BOOL)removeExtendedAttrAtPath:(NSString *)path
{
    NSDictionary *extAttrToRemove = @{ @"com.apple.FinderInfo"  : @1,
                                       @"com.apple.ResourceFork": @1,
                                       @"com.apple.quarantine"  : @1
                                      };

    const char *fileSystemPath = [path fileSystemRepresentation];

    // call with NULL for the char *namebuf param first
    // in this case the method returns the size of the attributes buffer
    ssize_t size = listxattr(fileSystemPath, NULL,  0, 0);

    if (size <= 0) {
        return YES; // no attributes to remove
    }

    char nameBuf[size];
    memset(nameBuf, 0, size);

    size = listxattr(fileSystemPath, nameBuf, size, 0);
    if (size <= 0) {
        return NO; // failed to read promised attrs
    }

    int i=0;
    while (i < size) {
        char *utf8name = &nameBuf[i];
        i += strlen(utf8name)+1; // attrs are 0-terminated one after another

        NSString *name = [NSString stringWithUTF8String:utf8name];
        if ([extAttrToRemove objectForKey:name]) {
            if (removexattr(fileSystemPath, utf8name, 0) == 0) {
                IODebug("Removed %s from %s", utf8name, fileSystemPath);
            } else {
                IOWarn("Can't remove %s from %s", utf8name, fileSystemPath);
                return NO;
            }
        }
    }

    return YES;
}

-(BOOL)trashFileAtPath:(NSString*)path error:(NSError**)err
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *url = [NSURL fileURLWithPath:path];

    if ([fm respondsToSelector:@selector(trashItemAtURL:resultingItemURL:error:)]) { // 10.8
        if ([fm trashItemAtURL:url resultingItemURL:nil error:err]) {
            return YES;
        }
        if (!err || [*err domain] != NSCocoaErrorDomain || [*err code] != 3328) {
            return NO;
        }
        IOWarn("Recovering trashing error %@", *err);
        // error = 3328 means volume doesn't have trash
        // to recover, copy file to temp and then trash
        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[path lastPathComponent]];
        if ([fm moveItemAtPath:path toPath:tempPath error:err]) {
            if ([fm trashItemAtURL:[NSURL fileURLWithPath:tempPath] resultingItemURL:nil error:err]) {
                return YES;
            }
            // oops, move it back
            [fm moveItemAtPath:tempPath toPath:path error:nil];
        }
        return NO;
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
        IOWarn("WTF? save without filePathOptimized? for %@", filePath);
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
            IOWarn("The file %@ is in non-writeable directory", filePath);
            return NO;
        }

        if (preserve)
        {
            NSString *writeToPath = [[[filePath stringByDeletingPathExtension] stringByAppendingString:@"~imageoptim"]
                                     stringByAppendingPathExtension:[filePath pathExtension]];

            if ([fm fileExistsAtPath:writeToPath]) {
                if (![self trashFileAtPath:writeToPath error:&error]) {
                    IOWarn("%@", error);
                    error = nil;
                    if (![fm removeItemAtPath:writeToPath error:&error]) {
                        IOWarn("%@", error);
                        return NO;
                    }
                }
            }

            // move destination to temporary location that will be overwritten
            if (![fm moveItemAtPath:filePath toPath:writeToPath error:&error]) {
                IOWarn("Can't move to %@ %@", writeToPath, error);
                return NO;
            }

            // copy original data for trashing under original file name
            if (![fm copyItemAtPath:writeToPath toPath:filePath error:&error]) {
                IOWarn("Can't write to %@ %@", filePath, error);
                return NO;
            }

            NSData *data = [NSData dataWithContentsOfFile:filePathOptimized];
            if (!data) {
                IOWarn("Unable to read %@", filePathOptimized);
                return NO;
            }

            if ([data length] != byteSizeOptimized) {
                IOWarn("Temp file size %u does not match expected %u in %@ for %@",(unsigned int)[data length],(unsigned int)byteSizeOptimized,filePathOptimized,filePath);
                return NO;
            }

            if ([data length] < 30) {
                IOWarn("File %@ is suspiciously small, could be truncated", filePathOptimized);
                return NO;
            }

            // overwrite old file that is under temporary name (so only content is replaced, not file metadata)
            NSFileHandle *writehandle = [NSFileHandle fileHandleForWritingAtPath:writeToPath];
            if (!writehandle) {
                IOWarn("Unable to open %@ for writing. Check file permissions.", filePath);
                return NO;
            }

            [writehandle writeData:data]; // this throws on failure
            [writehandle truncateFileAtOffset:[data length]];
            [writehandle closeFile];

            moveFromPath = writeToPath;
        }

        if (![self trashFileAtPath:filePath error:&error]) {
            IOWarn("Can't trash %@ %@", filePath, error);
            NSString *backupPath = [[[filePath stringByDeletingPathExtension] stringByAppendingString:@"~bak"]
                                    stringByAppendingPathExtension:[filePath pathExtension]];
            if (![fm moveItemAtPath:filePath toPath:backupPath error:&error]) {
                IOWarn("Can't move to %@ %@", backupPath, error);
                return NO;
            }
        }

        if (![fm moveItemAtPath:moveFromPath toPath:filePath error:&error]) {
            IOWarn("Failed to move from %@ to %@; %@",moveFromPath, filePath, error);
            return NO;
        }

        byteSizeOnDisk = byteSizeOptimized;

        [self removeExtendedAttrAtPath:filePath];
    }
    @catch (NSException *e)
    {
        IOWarn("Exception thrown %@ while saving %@",e, filePath);
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
        [self setStatus:@"progress" order:4 text:[NSString stringWithFormat:NSLocalizedString(@"Started %@",@"command name, tooltip"),name]];
    }
}

-(void)saveResultAndUpdateStatus {
    BOOL saved = [self saveResult];
    [self removeOldFilePathOptimized];

    if (saved) {
        done = YES;
        optimized = YES;
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
            if (!byteSizeOriginal || !byteSizeOptimized)
            {
                IODebug("worker %@ finished, but result file has 0 size",worker);
                [self setStatus:@"err" order:8 text:NSLocalizedString(@"Optimized file could not be saved",@"tooltip")];
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
                    if (filePathOptimized) {
                        NSOperation *cleanup = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(removeOldFilePathOptimized) object:nil];
                        [fileIOQueue addOperation:cleanup];
                    }
                }
            }
            else
            {
                [self setStatus:@"wait" order:2 text:NSLocalizedString(@"Waiting to start more optimizations",@"tooltip")];
            }
        }
    }
}

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
        done = NO;
        optimized = NO;
        workersActive++; // isBusy must say yes!

        fileIOQueue = aFileIOQueue; // will be used for saving
        workers = [[NSMutableArray alloc] initWithCapacity:10];
    }

    [self setStatus:@"wait" order:0 text:NSLocalizedString(@"Waiting to be optimized",@"tooltip")];

    NSOperation *actualEnqueue = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(doEnqueueWorkersInCPUQueue:) object:queue];
    if (queue.operationCount < queue.maxConcurrentOperationCount) {
        actualEnqueue.queuePriority = NSOperationQueuePriorityHigh;
    }

    [workers addObject:actualEnqueue];
    [fileIOQueue addOperation:actualEnqueue];
}

-(void)doEnqueueWorkersInCPUQueue:(NSOperationQueue *)queue
{
    [self setStatus:@"progress" order:3 text:NSLocalizedString(@"Inspecting file",@"tooltip")];

    NSData *fileData = [NSData dataWithContentsOfMappedFile:filePath];
    NSUInteger length = [fileData length];
    if (!fileData || !length)
    {
        [self setStatus:@"err" order:8 text:NSLocalizedString(@"Can't map file into memory",@"tooltip, generic loading error")];
        return;
    }

    fileType = [self fileType:fileData];

    BOOL hasBeenRunBefore = (byteSizeOnDisk && length == byteSizeOnDisk);
    BOOL isQueueBig = [queue operationCount] > 10 && [queue operationCount] > [queue maxConcurrentOperationCount]*2;

    @synchronized(self)
    {
        workersActive--;

        // if file hasn't changed since last optimization, keep previous byteSizeOriginal, etc.
        if (!byteSizeOnDisk || length != byteSizeOnDisk) {
            byteSizeOptimized = 0;
            [self setByteSizeOriginal:length];
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

    NSArray *worker_list = nil;

    if (fileType == FILETYPE_PNG)
    {
        worker_list = @[
                          @ {@"key":@"PngCrushEnabled", @"class":[PngCrushWorker class]},
                          @ {@"key":@"OptiPngEnabled", @"class":[OptiPngWorker class]},
        @ {@"key":@"ZopfliEnabled", @"class":[ZopfliWorker class], @"block": ^(Worker *w) {
            ((ZopfliWorker*)w).alternativeStrategy = hasBeenRunBefore;
            }},
        @ {@"key":@"PngOutEnabled", @"class":[PngoutWorker class]},
        @ {@"key":@"AdvPngEnabled", @"class":[AdvCompWorker class]},
                      ];
    }
    else if (fileType == FILETYPE_JPEG)
    {
        worker_list = @[
                          @ {@"key":@"JpegOptimEnabled", @"class":[JpegoptimWorker class]},
                          @ {@"key":@"JpegTranEnabled", @"class":[JpegtranWorker class]},
                      ];
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

    for (NSDictionary *wl in worker_list) {
        if ([defs boolForKey:wl[@"key"]]) {

            Worker *w = [wl[@"class"] alloc];
            w = [w initWithFile:self];
            if (wl[@"block"]) {
                void (^block)(Worker *) = wl[@"block"];
                block(w);
            }

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

    workersTotal += [runFirst count] + [runLater count];

    Worker *previousWorker = nil;
    for (Worker *w in runFirst) {
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
    for (Worker *w in runLater) {
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
        done = YES;
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
    if (statusOrder == order && statusText == text) return;
    statusOrder = order;
    self.statusText = text;
    self.statusImage = [NSImage imageNamed:imageName];
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"%@ %ld/%ld (workers active %ld, finished %ld, total %ld)", self.filePath,(long)self.byteSizeOriginal,(long)self.byteSizeOptimized, (long)workersActive, (long)workersFinished, (long)workersTotal];
}

+(NSInteger)fileByteSize:(NSString *)afile
{
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:afile error:nil];
    if (attr) return [[attr objectForKey:NSFileSize] integerValue];
    IOWarn("Could not stat %@",afile);
    return 0;
}

#pragma mark QL

-(NSURL *) previewItemURL {
    return [NSURL fileURLWithPath:filePath];
}

-(NSString *) previewItemTitle {
    return displayName;
}

@end
