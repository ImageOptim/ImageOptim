//
//  File.m
//
//  Created by porneL on 8.wrz.07.
//

#import "File.h"
#import "ImageOptimController.h"
#import "Workers/Save.h"
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
#include "ResultsDb.h"
#include <CommonCrypto/CommonDigest.h>

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

@interface File ()
@property (assign) BOOL isDone;
@property (assign) BOOL isFailed;
@end

@implementation File {
    BOOL preservePermissions;
}

@synthesize workersPreviousResults, byteSizeOriginal, byteSizeOptimized, filePath, displayName, statusText, statusOrder, statusImageName, percentDone, bestToolName, isFailed=failed, isDone=done;

-(instancetype)initWithFilePath:(nonnull NSURL *)aPath resultsDatabase:(nullable ResultsDb *)aDb
{
    if (self = [self init]) {
        workersPreviousResults = [NSMutableDictionary new];
        bestTools = [NSMutableDictionary new];
        filePathsOptimizedInUse = [NSMutableSet new];
        filePath = aPath;
        db = aDb;
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

-(nonnull NSString *)fileName {
    if (displayName) return displayName;
    return [filePath lastPathComponent];
}

-(NSURL*)filePathOptimized {
    @synchronized(self) {
        NSURL *path = filePathOptimized;
        if (path) {
            [filePathsOptimizedInUse addObject:path];
            return path;
        }
        return filePath;
    }
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[File allocWithZone:zone] initWithFilePath:filePath resultsDatabase:db];
}

-(void)resetToOriginalByteSize:(NSUInteger)size {
    [bestTools removeAllObjects];
    self.bestToolName = nil;
    lossyConverted = NO;
    byteSizeOptimized = 0;
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

-(void)setByteSizeOptimized:(NSUInteger)size {
    @synchronized(self) {
        if ((!byteSizeOptimized || size < byteSizeOptimized) && size > 30) {
            [self willChangeValueForKey:@"percentOptimized"];
            byteSizeOptimized = size;
            [self didChangeValueForKey:@"percentOptimized"];
        }
    }
}

-(void)removeOldFilePathOptimized:(NSURL *)path {
    if (!path) {
        return;
    }
    @synchronized(self) {
        if ([filePathsOptimizedInUse containsObject:path]) {
            return;
        }
    }
    [[NSFileManager defaultManager] removeItemAtURL:path error:nil];
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
    NSURL *oldPath = nil;
    BOOL changed = NO;
    @synchronized(self) {
        if (size && size < byteSizeOptimized) {
            assert(![filePathOptimized.path isEqualToString:tempPath.path]);
            oldPath = filePathOptimized;
            filePathOptimized = tempPath;
            NSUInteger oldSize = byteSizeOptimized;
            [self setByteSizeOptimized:size];
            [self performSelectorOnMainThread:@selector(updateBestToolName:) withObject:[[ToolStats alloc] initWithName:toolname oldSize:oldSize newSize:size] waitUntilDone:NO];
            changed = YES;
        }
    }
    [self removeOldFilePathOptimized:oldPath];
    return changed;
}

-(BOOL)removeExtendedAttrAtURL:(NSURL *)path
{
    NSDictionary *extAttrToRemove = @{ @"com.apple.FinderInfo"  : @1,
                                       @"com.apple.ResourceFork": @1,
                                       @"com.apple.quarantine"  : @1,
                                       @"com.apple.metadata:kMDItemWhereFroms": @1,
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

        NSString *name = @(utf8name);
        if (extAttrToRemove[name]) {
            if (removexattr(fileSystemPath, utf8name, 0) == 0) {
                IODebug("Removed %s from %@", utf8name, path.path);
            } else {
                IOWarn("Can't remove %s from %@", utf8name, path.path);
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

    if (returning) *returning = nil;
    return NO;
}

-(BOOL)canRevert {
    return revertPath && self.isDone && !stopping;
}

-(BOOL)revert {
    if (![self canRevert]) {
        return NO;
    }
    [self cleanup];

    if (byteSizeOriginal != [File fileByteSize:revertPath]) {
        IOWarn(@"Revert path '%@' has wrong size, %ld expected", revertPath, (long)byteSizeOriginal);
        return NO;
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err = nil;
    NSURL *newFilePath = nil;
    if (![fm replaceItemAtURL:filePath withItemAtURL:revertPath backupItemName:nil options:0 resultingItemURL:&newFilePath error:&err]) {
        IOWarn(@"Can't revert: %@ due to %@", revertPath, err);
        return NO;
    }

    revertPath = nil;
    if (newFilePath) {
        filePath = [newFilePath copy];
    }
    [self resetToOriginalByteSize:byteSizeOriginal];
    [self setStatus:@"noopt" order:6 text:NSLocalizedString(@"Reverted to original",@"tooltip")];
    return YES;
}

-(BOOL)saveResult {
    assert(filePathOptimized);
    @try {

        NSFileManager *fm = [NSFileManager defaultManager];

        NSError *error = nil;
        NSURL *moveFromPath = filePathOptimized;
        NSURL *enclosingDir = [filePath URLByDeletingLastPathComponent];

        if (![fm isWritableFileAtPath:enclosingDir.path]) {
            IOWarn("The file %@ is in non-writeable directory %@", filePath.path, enclosingDir.path);
            return NO;
        }

        if (preservePermissions) {
            NSString *writeToFilename = [[NSString stringWithFormat:@".%@~imageoptim", [filePath.lastPathComponent stringByDeletingPathExtension]] stringByAppendingPathExtension:filePath.pathExtension];
            NSURL *writeToURL = [enclosingDir URLByAppendingPathComponent:writeToFilename];
            NSString *writeToPath = writeToURL.path;

            if ([fm fileExistsAtPath:writeToPath]) {
                if ([self trashFileAtURL:writeToURL resultingItemURL:nil error:&error]) {
                } else {
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

        NSURL *revertPathTmp;
        if ([self trashFileAtURL:filePath resultingItemURL:&revertPathTmp error:&error]) {
            revertPath = revertPathTmp;
        } else {
            IOWarn("Can't trash %@ %@", filePath.path, error);
            NSURL *backupPath = [NSURL fileURLWithPath:[[[filePath lastPathComponent] stringByAppendingString:@"~bak"] stringByAppendingPathExtension:[filePath pathExtension]]];

            [fm removeItemAtURL:backupPath error:nil];
            if ([fm moveItemAtURL:filePath toURL:backupPath error:&error]) {
                revertPath = backupPath;
            } else {
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

-(void)setNooptStatus {
    [self setStatus:@"noopt" order:5 text:NSLocalizedString(@"File cannot be optimized any further",@"tooltip")];
}

-(void)saveResultAndUpdateStatus {
    assert([self isBusy]);
    self.isDone = YES;
    if ([self isOptimized] && filePathOptimized && byteSizeOriginal && byteSizeOptimized) {
        BOOL saved = [self saveResult];
        if (saved) {
            optimized = YES;
            [self setStatus:@"ok" order:7 text:[NSString stringWithFormat:NSLocalizedString(@"Optimized successfully with %@",@"tooltip"),bestToolName]];
        } else {
            [self setError:NSLocalizedString(@"Optimized file could not be saved",@"tooltip")];
        }
    } else {
        [self setNooptStatus];
        if (!stopping && !self.isFailed) {
            [db setUnoptimizableFileHash:inputFileHash size:byteSizeOnDisk];
        }
    }
    [self cleanup];
}

-(nullable NSString *)mimeType {
    return fileType == FILETYPE_PNG ? @"image/png" : (fileType == FILETYPE_JPEG ? @"image/jpeg" : (fileType == FILETYPE_GIF ? @"image/gif" : nil));
}

-(int)fileType:(nonnull NSData *)data {
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

-(void)enqueueWorkersInCPUQueue:(nonnull NSOperationQueue *)queue fileIOQueue:(nonnull NSOperationQueue *)aFileIOQueue defaults:(nonnull NSUserDefaults*)defaults {

    [self willChangeValueForKey:@"isBusy"];
    NSOperation *actualEnqueue = [NSBlockOperation blockOperationWithBlock:^{
        @synchronized(self) {
            [self doEnqueueWorkersInCPUQueue:queue defaults:defaults];
        }
    }];
    @synchronized(self) {
        self.isDone = NO;
        self.isFailed = NO;
        stopping = NO;
        optimized = NO;
        fileIOQueue = aFileIOQueue; // will be used for saving
        workers = [[NSMutableArray alloc] initWithCapacity:10];
        preservePermissions = [defaults boolForKey:@"PreservePermissions"];

        BOOL isQueueUnderUtilized = queue.operationCount < queue.maxConcurrentOperationCount;
        if (isQueueUnderUtilized) {
            actualEnqueue.queuePriority = NSOperationQueuePriorityVeryHigh;
        }

        [workers addObject:actualEnqueue];
        [fileIOQueue addOperation:actualEnqueue];
    }
    [self didChangeValueForKey:@"isBusy"];
}

-(void)setSettingsHash:(NSArray*)allWorkers {
    CC_MD5_CTX md5ctx = {};
    CC_MD5_Init(&md5ctx);
    CC_MD5_Update(&md5ctx, "3", 1); // to update when programs change
    for (Worker *w in allWorkers) {
        NSInteger tmp = [w settingsIdentifier];
        CC_MD5_Update(&md5ctx, &tmp, sizeof(tmp));
    }
    CC_MD5_Final((unsigned char *)settingsHash, &md5ctx);
}

-(void)doEnqueueWorkersInCPUQueue:(nonnull NSOperationQueue *)queue defaults:(nonnull NSUserDefaults*)defs {
    [self setStatus:@"progress" order:3 text:NSLocalizedString(@"Inspecting file",@"tooltip")];

    NSError *err = nil;
    NSData *fileData = [NSData dataWithContentsOfURL:filePath options:NSDataReadingMappedIfSafe error:&err];
    NSUInteger length = [fileData length];
    if (!fileData || !length) {
        IOWarn(@"Can't open the file %@ %@", filePath.path, err);
        [self setError:NSLocalizedString(@"Can't open the file",@"tooltip, generic loading error")];
        return;
    }

    fileType = [self fileType:fileData];

    BOOL hasBeenRunBefore = (byteSizeOnDisk && length == byteSizeOnDisk);

    @synchronized(self) {
        // if file hasn't changed since last optimization, keep previous byteSizeOriginal, etc.
        if (!byteSizeOnDisk || length != byteSizeOnDisk) {
            [self resetToOriginalByteSize:length];
        }
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm isWritableFileAtPath:filePath.path]) {
        [self setError:NSLocalizedString(@"Optimized file could not be saved",@"tooltip")];
        return;
    }

    NSMutableArray *runFirst = [NSMutableArray new];
    NSMutableArray *runLater = [NSMutableArray new];

    NSMutableArray *worker_list = [NSMutableArray new];
    NSInteger level = [defs integerForKey:@"AdvPngLevel"]; // AdvPNG setting is reused for all tools now
    BOOL lossyEnabled = [defs boolForKey:@"LossyEnabled"];
    if (lossyEnabled) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            [defs setBool:YES forKey:@"LossyUsed"];
        });
    }

    if (fileType == FILETYPE_PNG) {
        if (hasBeenRunBefore) {
            level++;
        }

        if (lossyEnabled) {
            NSInteger pngQuality = [defs integerForKey:@"PngMinQuality"];
            if (!lossyConverted && pngQuality < 100 && pngQuality > 30) {
                Worker *w = [[PngquantWorker alloc] initWithLevel:level minQuality:pngQuality file:self];
                [runFirst addObject:w];
                lossyConverted = YES;
            }
        }
        
        BOOL pngcrushEnabled = [defs boolForKey:@"PngCrushEnabled"];
        BOOL optipngEnabled = [defs boolForKey:@"OptiPngEnabled"];
        BOOL pngoutEnabled = [defs boolForKey:@"PngOutEnabled"];
        BOOL zopfliEnabled = [defs boolForKey:@"ZopfliEnabled"];
        BOOL advpngEnabled = [defs boolForKey:@"AdvPngEnabled"];
        
        if (level < 4 && zopfliEnabled) {
            pngoutEnabled = NO;
        }
        
        if (level < 2 && optipngEnabled) {
            pngcrushEnabled = NO;
        }
        
        if (pngcrushEnabled) [worker_list addObject:[[PngCrushWorker alloc] initWithLevel:level defaults:defs file:self]];
        if (optipngEnabled) [worker_list addObject:[[OptiPngWorker alloc] initWithLevel:level file:self]];
        if (pngoutEnabled) [worker_list addObject:[[PngoutWorker alloc] initWithLevel:level defaults:defs file:self]];
        if (advpngEnabled) [worker_list addObject:[[AdvCompWorker alloc] initWithLevel:level file:self]];
        if (zopfliEnabled) {
            ZopfliWorker *zw = [[ZopfliWorker alloc]initWithLevel:level defaults:defs file:self];
            zw.alternativeStrategy = hasBeenRunBefore;
            [worker_list addObject:zw];
        }
    } else if (fileType == FILETYPE_JPEG) {
        if ([defs boolForKey:@"JpegOptimEnabled"]) [worker_list addObject:[[JpegoptimWorker alloc] initWithDefaults:defs file:self]];
        if ([defs boolForKey:@"JpegTranEnabled"]) [worker_list addObject:[[JpegtranWorker alloc] initWithDefaults:defs file:self]];
    } else if (fileType == FILETYPE_GIF) {
        if ([defs boolForKey:@"GifsicleEnabled"]) {
            NSInteger gifQuality = [defs integerForKey:@"GifQuality"];
            if (lossyEnabled && !lossyConverted && gifQuality < 100 && gifQuality > 30) {
                Worker *w = [[GifsicleWorker alloc] initWithInterlace:NO quality:gifQuality file:self];
                [runFirst addObject:w];
                lossyConverted = YES;
            } else {
                [worker_list addObject:[[GifsicleWorker alloc] initWithInterlace:NO quality:100 file:self]];
                if (level > 1) {
                    [worker_list addObject:[[GifsicleWorker alloc] initWithInterlace:YES quality:100 file:self]];
                }
            }
        }
    } else {
        [self setError:NSLocalizedString(@"File is neither PNG, GIF nor JPEG",@"tooltip")];
        [self cleanup];
        return;
    }

    BOOL isQueueUnderUtilized = queue.operationCount < queue.maxConcurrentOperationCount;

    for (Worker *w in worker_list) {

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

    // Create a hash that includes all optimization settings to invalidate file caches on settings changes
    [self setSettingsHash:[runFirst arrayByAddingObjectsFromArray:runLater]];

    // Can't check only file size, because then hash won't be available on save! if ([db hasResultWithFileSize:byteSizeOnDisk]) {

    CC_MD5_CTX md5ctx = {}, *md5ctxp = &md5ctx;
    CC_MD5_Init(md5ctxp);
    CC_MD5_Update(md5ctxp, settingsHash, 16);
    CC_MD5_Update(md5ctxp, [fileData bytes], (CC_LONG)[fileData length]);
    CC_MD5_Final((unsigned char*)inputFileHash, md5ctxp);
    if ([db getResultWithHash:inputFileHash]) { // FIXME: check for lossy
        self.isDone = YES;
        NSLog(@"Skipping %@, because it has been optimized before", filePath.path);
        [self setNooptStatus];
        [self cleanup];
        return;
    }

    NSOperation *saveOp = [[Save alloc] initWithTarget:self selector:@selector(saveResultAndUpdateStatus) object:nil];

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
        self.isDone = YES;
        [self setError:NSLocalizedString(@"All neccessary tools have been disabled in Preferences",@"tooltip")];
        [self cleanup];
    } else {
        [self updateStatusOfWorker:nil running:NO];
        [workers addObject:saveOp];
        [fileIOQueue addOperation:saveOp];
    }
}

-(void)cleanup {
    NSURL *oldPath;
    NSMutableSet *paths;
    @synchronized(self) {
        stopping = NO;
        [workers makeObjectsPerformSelector:@selector(cancel)];
        [workers removeAllObjects];
        oldPath = filePathOptimized;
        filePathOptimized = nil;
        paths = filePathsOptimizedInUse;
        filePathsOptimizedInUse = [NSMutableSet new];
    }

    [self removeOldFilePathOptimized:oldPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    for(NSString *path in paths) {
        [fm removeItemAtPath:path error:nil];
    }
}

-(BOOL)isBusy {
    return [workers count] > 0;
}

-(BOOL)stop {
    if (![self isStoppable]) {
        return NO;
    }
    @synchronized(self) {
        if (!self.isDone) {
            stopping = YES;
            for(Worker *w in workers) {
                if (![w isKindOfClass:[Save class]]) {
                    [w cancel];
                }
            }
        }
    }
    return YES;
}

-(BOOL)isStoppable {
    return stopping || (!self.isDone && [self isBusy]);
}

-(void)updateStatusOfWorker:(nullable Worker *)currentWorker running:(BOOL)started {
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

-(void)setError:(nonnull NSString *)text {
    self.isFailed = YES;
    [self setStatus:@"err" order:9 text:text];
}

-(void)setStatus:(nonnull NSString *)imageName order:(NSInteger)order text:(nonnull NSString *)text {
    void (^setter)() = ^(void){

        // Keep failed status visible instead of replacing with progress/noopt/etc
        if (self.isFailed && ![imageName isEqualToString:@"ok"] && ![imageName isEqualToString:@"err"]) {
            return;
        }

        statusOrder = order;
        self.statusText = text;
        self.statusImageName = imageName;
    };
    if (order) {
        dispatch_async(dispatch_get_main_queue(), setter);
    } else {
        setter(); // order=0 is from constructor, can be done synchronously
    }
}

-(nonnull NSString *)description {
    return [NSString stringWithFormat:@"%@ %ld/%ld (workers %ld)", self.filePath,(long)self.byteSizeOriginal,(long)self.byteSizeOptimized, [workers count]];
}

+(NSInteger)fileByteSize:(NSURL *)afile {
    NSNumber *value = nil;
    NSError *err = nil;
    if ([afile getResourceValue:&value forKey:NSURLFileSizeKey error:&err] && value) {
        return [value integerValue];
    }
    IOWarn("Could not stat %@: %@", afile.path, err);
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
