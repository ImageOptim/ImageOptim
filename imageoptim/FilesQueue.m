
#import "FilesQueue.h"
#import "File.h"
#import "DirWorker.h"

@implementation FilesQueue {
    NSOperationQueue *cpuQueue;
    NSOperationQueue *fileIOQueue;
    NSOperationQueue *dirWorkerQueue;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

        cpuQueue = [NSOperationQueue new];
        [cpuQueue setMaxConcurrentOperationCount:[defs integerForKey:@"RunConcurrentFiles"]];

        dirWorkerQueue = [NSOperationQueue new];
        [dirWorkerQueue setMaxConcurrentOperationCount:[defs integerForKey:@"RunConcurrentDirscans"]];

        fileIOQueue = [NSOperationQueue new];
        NSUInteger fileops = [defs integerForKey:@"RunConcurrentFileops"];
        [fileIOQueue setMaxConcurrentOperationCount:fileops?fileops:2];
    }
    return self;
}

-(void)addFile:(File*)f {
    [f enqueueWorkersInCPUQueue:cpuQueue fileIOQueue:fileIOQueue];
}

-(void)addDirWorker:(DirWorker *)d {
    [dirWorkerQueue addOperation:d];
}

-(NSNumber *)queueCount {
    return @(cpuQueue.operationCount + dirWorkerQueue.operationCount + fileIOQueue.operationCount);
}

-(BOOL)isBusy {
    return cpuQueue.operationCount > 0 || dirWorkerQueue.operationCount > 0 || fileIOQueue.operationCount > 0;
}

-(void)cleanup {
    [dirWorkerQueue cancelAllOperations];
    [fileIOQueue cancelAllOperations];
    [cpuQueue cancelAllOperations];
}

-(void)wait {
    do { // any queue may be re-filled while waiting for another queue, so double-check is necessary
        [dirWorkerQueue waitUntilAllOperationsAreFinished];
        [fileIOQueue waitUntilAllOperationsAreFinished];
        [cpuQueue waitUntilAllOperationsAreFinished];
    } while ([self isBusy]);

}

@end