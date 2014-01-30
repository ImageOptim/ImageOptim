//
//  File.m
//
//  Created by porneL on 8.wrz.07.
//

#import "File.h"
#import "ImageOptimController.h"
#import "Workers/AdvCompWorker.h"
#import "Workers/PngquantWorker.h"
#import "Workers/PngoutWorker.h"
#import "Workers/OptiPngWorker.h"
#import "Workers/PngCrushWorker.h"
#import "Workers/ZopfliWorker.h"
#import "Workers/JpegoptimWorker.h"
#import "Workers/JpegtranWorker.h"
#import "Workers/GifsicleWorker.h"
#import <sys/xattr.h>
#import "log.h"

@interface ToolStats : NSObject {
    @public
    NSString *name;
    NSUInteger fileSize;
    double ratio;
}
@end

@implementation ToolStats
- (instancetype)initWithName:(NSString*)aName oldSize:(NSUInteger)oldSize newSize:(NSUInteger)size {
    if ((self = [super init])) {
        name = aName;
        fileSize = size;
        ratio = (double)oldSize/(double)size;
    }
    return self;
}
@end

@implementation File

@synthesize workersPreviousResults, byteSizeOriginal, byteSizeOptimized, filePath, displayName, statusText, statusOrder, statusImage, percentDone, bestToolName, fileType;

-(id)initWithFilePath:(NSURL *)aPath;
{
    if (self = [self init]) {
        workersPreviousResults = [NSMutableDictionary new];
        bestTools = [NSMutableDictionary new];
        filePathsOptimizedInUse = [NSMutableSet new];
        filePath = aPath;
        self.displayName = [[NSFileManager defaultManager] displayNameAtPath:filePath.path];
        [self setStatus:@"wait" order:0 text:NSLocalizedString(@"Waiting to be optimized",@"tooltip")];
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

-(NSString *)fileName {
    if (displayName) return displayName;
    if (filePath) return [filePath lastPathComponent];
    return nil;
}

-(NSURL*)filePathOptimized {
    NSURL *path = filePathOptimized;
    if (path) {
        [filePathsOptimizedInUse addObject:path];
        return path;
    }
    return filePath;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[File allocWithZone:zone] initWithFilePath:filePath];
}

-(void)setByteSizeOriginal:(NSUInteger)size {
    byteSizeOriginal = size;
    byteSizeOnDisk = size;
    [self setByteSizeOptimized:size];
}

-(double)percentOptimized {
    if (!byteSizeOptimized) return 0.0;
    double p = 100.0 - 100.0* (double)byteSizeOptimized/(double)byteSizeOriginal;
    if (p<0) return 0.0;
    return p;
}

-(BOOL)isOptimized {
    return byteSizeOptimized < byteSizeOriginal && (optimized || byteSizeOptimized < byteSizeOnDisk);
}

-(BOOL)isDone {
    return done;
}

-(void)setByteSizeOptimized:(NSUInteger)size {
    @synchronized(self) {
        if ((!byteSizeOptimized || size < byteSizeOptimized) && size > 30) {
            [self willChangeValueForKey:@"percentOptimized"];
            byteSizeOptimized = size;
            [self didChangeValueForKey:@"percentOptimized"];
        }
    }
}

-(void)removeOldFilePathOptimized {
    NSURL *path = filePathOptimized;
    if (path) {
        filePathOptimized = nil;
        if (![filePathsOptimizedInUse containsObject:path]) {
            [[NSFileManager defaultManager] removeItemAtURL:path error:nil];
        }
    }
}

-(void)updateBestToolName:(ToolStats*)newTool {
    bestTools[newTool->name] = newTool;

    NSString *smallestFileToolName = nil; NSUInteger smallestFile = byteSizeOriginal;
    NSString *bestRatioToolName = nil; float bestRatio = 0;
    for (NSString *name in bestTools) {
        ToolStats *t = bestTools[name];
        if (t->ratio > bestRatio) {bestRatioToolName = name; bestRatio = t->ratio;}
        if (t->fileSize < smallestFile) {smallestFileToolName = name; smallestFile = t->fileSize;}
    }
    NSString *newBestToolName;
    if (smallestFileToolName && bestRatioToolName && ![bestRatioToolName isEqualToString:smallestFileToolName]) {
        newBestToolName = [NSString stringWithFormat:NSLocalizedString(@"%@+%@","toolname+toolname in Best Tool column"), bestRatioToolName, smallestFileToolName];
    } else {
        newBestToolName = smallestFileToolName ? smallestFileToolName : bestRatioToolName;
    }
    if (![newBestToolName isEqualToString:self.bestToolName]) {
        self.bestToolName = newBestToolName;
    }
}

-(BOOL)setFilePathOptimized:(NSURL *)tempPath size:(NSUInteger)size toolName:(NSString *)toolname {
    IODebug("File %@ optimized with %@ from %u to %u in %@",[filePath?filePath:filePathOptimized path],toolname,(unsigned int)byteSizeOptimized,(unsigned int)size,tempPath);
    @synchronized(self) {
        if (size && size < byteSizeOptimized) {
            assert(![filePathOptimized.path isEqualToString:tempPath.path]);
            [self removeOldFilePathOptimized];
            filePathOptimized = tempPath;
            NSUInteger oldSize = byteSizeOptimized;
            [self setByteSizeOptimized:size];

            [self performSelectorOnMainThread:@selector(updateBestToolName:) withObject:[[ToolStats alloc] initWithName:toolname oldSize:oldSize newSize:size] waitUntilDone:NO];
            return YES;
        }
    }
    return NO;
}

-(BOOL)removeExtendedAttrAtURL:(NSURL *)path
{
    NSDictionary *extAttrToRemove = @{ @"com.apple.FinderInfo"  : @1,
                                       @"com.apple.ResourceFork": @1,
                                       @"com.apple.quarantine"  : @1
                                      };

    const char *fileSystemPath = [path.path fileSystemRepresentation];

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

-(BOOL)trashFileAtURL:(NSURL *)path resultingItemURL:(NSURL**)returning error:(NSError **)err {
    NSFileManager *fm = [NSFileManager defaultManager];

    if ([fm respondsToSelector:@selector(trashItemAtURL:resultingItemURL:error:)]) { // 10.8
        if ([fm trashItemAtURL:path resultingItemURL:returning error:err]) {
            return YES;
        }
        IOWarn("Recovering trashing error %@", *err); // may fail on network drives
    }

    NSURL *trashedPath = [[[NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES] URLByAppendingPathComponent:@".Trash"] URLByAppendingPathComponent:[path lastPathComponent]];
    [fm removeItemAtURL:trashedPath error:nil];

    if ([fm moveItemAtURL:path toURL:trashedPath error:err]) {
        if (returning) *returning = trashedPath;
        return YES;
    }

    IOWarn("Recovering trashing error %@", *err);

    FSRef ref;
    if (0 != FSPathMakeRefWithOptions((const UInt8 *)[path.path fileSystemRepresentation],
                                      kFSPathMakeRefDoNotFollowLeafSymlink,
                                      &ref, NULL)) {
        return NO;
    }

    if (0 != FSMoveObjectToTrashSync(&ref, NULL, kFSFileOperationDefaultOptions)) {
        return NO;
    }

    if (returning) *returning = nil;
    return YES;
}

-(BOOL)saveResult {
    assert(filePathOptimized);
    @try {
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        BOOL preserve = [defs boolForKey:@"PreservePermissions"];
        NSFileManager *fm = [NSFileManager defaultManager];

        NSError *error = nil;
        NSURL *moveFromPath = filePathOptimized;
        NSURL *enclosingDir = [filePath URLByDeletingLastPathComponent];

        if (![fm isWritableFileAtPath:enclosingDir.path]) {
            IOWarn("The file %@ is in non-writeable directory %@", filePath.path, enclosingDir.path);
            return NO;
        }

        if (preserve) {
            NSString *writeToFilename = [[NSString stringWithFormat:@".%@~imageoptim", [filePath.lastPathComponent stringByDeletingPathExtension]] stringByAppendingPathExtension:filePath.pathExtension];
            NSURL *writeToURL = [enclosingDir URLByAppendingPathComponent:writeToFilename];
            NSString *writeToPath = writeToURL.path;

            if ([fm fileExistsAtPath:writeToPath]) {
                if (![self trashFileAtURL:writeToURL resultingItemURL:nil error:&error]) {
                    IOWarn("%@", error);
                    error = nil;
                    if (![fm removeItemAtURL:writeToURL error:&error]) {
                        IOWarn("%@", error);
                        return NO;
                    }
                }
            }


            // move destination to temporary location that will be overwritten
            if (![fm moveItemAtURL:filePath toURL:writeToURL error:&error]) {
                IOWarn("Can't move to %@ %@", writeToPath, error);
                return NO;
            }

            // copy original data for trashing under original file name
            if (![fm copyItemAtURL:writeToURL toURL:filePath error:&error]) {
                IOWarn("Can't write to %@ %@", filePath.path, error);
                return NO;
            }

            NSData *data = [NSData dataWithContentsOfURL:filePathOptimized];
            if (!data) {
                IOWarn("Unable to read %@", filePathOptimized.path);
                return NO;
            }

            if ([data length] != byteSizeOptimized) {
                IOWarn("Temp file size %u does not match expected %u in %@ for %@",(unsigned int)[data length],(unsigned int)byteSizeOptimized,filePathOptimized.path,filePath.path);
                return NO;
            }

            if ([data length] < 30) {
                IOWarn("File %@ is suspiciously small, could be truncated", filePathOptimized.path);
                return NO;
            }

            // overwrite old file that is under temporary name (so only content is replaced, not file metadata)
            NSFileHandle *writehandle = [NSFileHandle fileHandleForWritingToURL:writeToURL error:nil];
            if (!writehandle) {
                IOWarn("Unable to open %@ for writing. Check file permissions.", filePath.path);
                return NO;
            }

            [writehandle writeData:data]; // this throws on failure
            [writehandle truncateFileAtOffset:[data length]];
            [writehandle closeFile];

            moveFromPath = writeToURL;
        }

        if (![self trashFileAtURL:filePath resultingItemURL:nil error:&error]) {
            IOWarn("Can't trash %@ %@", filePath.path, error);
            NSURL *backupPath = [NSURL fileURLWithPath:[[[filePath lastPathComponent] stringByAppendingString:@"~bak"] stringByAppendingPathExtension:[filePath pathExtension]]];

            [fm removeItemAtURL:backupPath error:nil];
            if (![fm moveItemAtURL:filePath toURL:backupPath error:&error]) {
                IOWarn("Can't move to %@ %@", backupPath, error);
                return NO;
            }
        }

        if (![fm moveItemAtURL:moveFromPath toURL:filePath error:&error]) {
            IOWarn("Failed to move from %@ to %@; %@", moveFromPath.path, filePath.path, error);
            return NO;
        }

        byteSizeOnDisk = byteSizeOptimized;

        [self removeExtendedAttrAtURL:filePath];
    }
    @catch (NSException *e) {
        IOWarn("Exception thrown %@ while saving %@", e, filePath.path);
        return NO;
    }

    return YES;
}

-(void)saveResultAndUpdateStatus {
    assert([self isBusy]);
    done = YES;
    if ([self isOptimized] && filePathOptimized && byteSizeOriginal && byteSizeOptimized) {
        BOOL saved = [self saveResult];
        if (saved) {
            optimized = YES;
            [self setStatus:@"ok" order:7 text:[NSString stringWithFormat:NSLocalizedString(@"Optimized successfully with %@",@"tooltip"),bestToolName]];
        } else {
            [self setStatus:@"err" order:9 text:NSLocalizedString(@"Optimized file could not be saved",@"tooltip")];
        }
    } else {
        [self setStatus:@"noopt" order:5 text:NSLocalizedString(@"File cannot be optimized any further",@"tooltip")];
    }
    [self cleanup];
}

-(int)fileType:(NSData *)data {
    const unsigned char pngheader[] = {0x89,0x50,0x4e,0x47,0x0d,0x0a};
    const unsigned char jpegheader[] = {0xff,0xd8,0xff};
    const unsigned char gifheader[] = {0x47,0x49,0x46,0x38};
    char filedata[6];

    [data getBytes:filedata length:sizeof(filedata)];

    if (0==memcmp(filedata, pngheader, sizeof(pngheader))) {
        return FILETYPE_PNG;
    } else if (0==memcmp(filedata, jpegheader, sizeof(jpegheader))) {
        return FILETYPE_JPEG;
    } else if (0==memcmp(filedata, gifheader, sizeof(gifheader))) {
        return FILETYPE_GIF;
    }
    return 0;
}

-(void)enqueueWorkersInCPUQueue:(NSOperationQueue *)queue fileIOQueue:(NSOperationQueue *)aFileIOQueue {

    @synchronized(self) {
        done = NO;
        optimized = NO;
        fileIOQueue = aFileIOQueue; // will be used for saving
        workers = [[NSMutableArray alloc] initWithCapacity:10];

        NSOperation *actualEnqueue = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(doEnqueueWorkersInCPUQueue:) object:queue];
        if (queue.operationCount < queue.maxConcurrentOperationCount) {
            actualEnqueue.queuePriority = NSOperationQueuePriorityVeryHigh;
        }

        [workers addObject:actualEnqueue];
        [fileIOQueue addOperation:actualEnqueue];
    }
}

-(void)doEnqueueWorkersInCPUQueue:(NSOperationQueue *)queue {
    [self setStatus:@"progress" order:3 text:NSLocalizedString(@"Inspecting file",@"tooltip")];

    NSError *err = nil;
    NSData *fileData = [NSData dataWithContentsOfURL:filePath options:NSDataReadingMappedIfSafe error:&err];
    NSUInteger length = [fileData length];
    if (!fileData || !length) {
        IOWarn(@"Can't open the file %@ %@", filePath.path, err);
        [self setStatus:@"err" order:8 text:NSLocalizedString(@"Can't open the file",@"tooltip, generic loading error")];
        return;
    }

    fileType = [self fileType:fileData];

    BOOL hasBeenRunBefore = (byteSizeOnDisk && length == byteSizeOnDisk);

    @synchronized(self) {
        // if file hasn't changed since last optimization, keep previous byteSizeOriginal, etc.
        if (!byteSizeOnDisk || length != byteSizeOnDisk) {
            byteSizeOptimized = 0;
            [self setByteSizeOriginal:length];
        }
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm isWritableFileAtPath:filePath.path]) {
        [self setStatus:@"err" order:9 text:NSLocalizedString(@"Optimized file could not be saved",@"tooltip")];
        return;
    }

    NSMutableArray *runFirst = [NSMutableArray new];
    NSMutableArray *runLater = [NSMutableArray new];

    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

    NSArray *worker_list = nil;

    if (fileType == FILETYPE_PNG) {
        NSInteger pngQuality = [defs integerForKey:@"PngMinQuality"];
        if (pngQuality < 100 && pngQuality > 30) {
            Worker *w = [[PngquantWorker alloc] initWithFile:self minQuality:pngQuality];
            [runFirst addObject:w];
        }

        worker_list = @[
                          @ {@"key":@"PngCrushEnabled", @"class":[PngCrushWorker class]},
                          @ {@"key":@"OptiPngEnabled", @"class":[OptiPngWorker class]},
        @ {@"key":@"ZopfliEnabled", @"class":[ZopfliWorker class], @"block": ^(Worker *w) {
            ((ZopfliWorker *)w).alternativeStrategy = hasBeenRunBefore;
        }
                            },
        @ {@"key":@"PngOutEnabled", @"class":[PngoutWorker class]},
        @ {@"key":@"AdvPngEnabled", @"class":[AdvCompWorker class]},
                      ];
    } else if (fileType == FILETYPE_JPEG) {
        worker_list = @[
                          @ {@"key":@"JpegOptimEnabled", @"class":[JpegoptimWorker class]},
                          @ {@"key":@"JpegTranEnabled", @"class":[JpegtranWorker class]},
                      ];
    } else if (fileType == FILETYPE_GIF) {
        if ([defs boolForKey:@"GifsicleEnabled"]) {
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

    BOOL isQueueUnderUtilized = [queue operationCount] <= [queue maxConcurrentOperationCount];

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
                if (!isQueueUnderUtilized || [self isSmall]) {
                    [runFirst addObject:w];
                } else {
                    [w setQueuePriority:[runLater count] ? NSOperationQueuePriorityHigh : NSOperationQueuePriorityVeryHigh];
                    [runLater addObject:w];
                }
            } else {
                [runLater addObject:w];
            }
        }
    }

    NSOperation *saveOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(saveResultAndUpdateStatus) object:nil];

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
        [saveOp addDependency:w];
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
        [saveOp addDependency:w];
        [queue addOperation:w];
        previousWorker = w;
    }

    [workers addObjectsFromArray:runFirst];
    [workers addObjectsFromArray:runLater];

    if (![workers count]) {
        done = YES;
        [self setStatus:@"err" order:8 text:NSLocalizedString(@"All neccessary tools have been disabled in Preferences",@"tooltip")];
        [self cleanup];
    } else {
        [self updateStatusOfWorker:nil running:NO];
        [workers addObject:saveOp];
        [fileIOQueue addOperation:saveOp];
    }
}

-(void)cleanup {
    @synchronized(self) {
        [workers makeObjectsPerformSelector:@selector(cancel)];
        [workers removeAllObjects];
        [self removeOldFilePathOptimized];
        NSFileManager *fm = [NSFileManager defaultManager];
        for(NSString *path in filePathsOptimizedInUse) {
            [fm removeItemAtPath:path error:nil];
        }
        [filePathsOptimizedInUse removeAllObjects];
    }
}

-(BOOL)isBusy {
    BOOL isit;
    @synchronized(self) {
        isit = [workers count] > 0;
    }
    return isit;
}

-(void)updateStatusOfWorker:(Worker *)currentWorker running:(BOOL)started {
    NSOperation *running = nil;

    @synchronized(self) {
        if (currentWorker && started) {
            running = currentWorker;
        } else {
            // technically I should pause all queues before that loop, but I'm going to allow some false "wait" icons instead
            for(NSOperation *op in workers) {
                // worker sets started:NO when it's ending, but isExecuting still shows true for it
                // Worker class is limited to user-visible workers (there are other for enqueuing, saving, etc.)
                if (op != currentWorker && [op isExecuting] && [op isKindOfClass:[Worker class]]) {
                    running = op;
                    break;
                }
            }
        }
    }

    if (running) {
        NSString *name = [[running className] stringByReplacingOccurrencesOfString:@"Worker" withString:@""];
        [self setStatus:@"progress" order:4 text:[NSString stringWithFormat:NSLocalizedString(@"Started %@",@"command name, tooltip"), name]];
    } else {
        [self setStatus:@"wait" order:1 text:NSLocalizedString(@"Waiting to be optimized",@"tooltip")];
    }
}

-(void)setStatus:(NSString *)imageName order:(NSInteger)order text:(NSString *)text {
    void (^setter)() = ^(void){
        statusOrder = order;
        self.statusText = text;
        self.statusImage = [NSImage imageNamed:imageName];
    };
    if (order) {
        dispatch_async(dispatch_get_main_queue(), setter);
    } else {
        setter(); // order=0 is from constructor, can be done synchronously
    }
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@ %ld/%ld (workers %ld)", self.filePath,(long)self.byteSizeOriginal,(long)self.byteSizeOptimized, [workers count]];
}

+(NSInteger)fileByteSize:(NSURL *)afile {
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:afile.path error:nil];
    if (attr) return [[attr objectForKey:NSFileSize] integerValue];
    IOWarn("Could not stat %@",afile.path);
    return 0;
}

#pragma mark QL

-(NSURL *) previewItemURL {
    return self.filePathOptimized;
}

-(NSString *) previewItemTitle {
    return displayName;
}

@end
