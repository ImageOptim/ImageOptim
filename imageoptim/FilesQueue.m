
#import "FilesQueue.h"
#import "File.h"
#import "DirWorker.h"

@interface FilesQueue ()
    @property (strong) NSUserDefaults *defaults;
@end

@implementation FilesQueue {
    NSOperationQueue *cpuQueue;
    NSOperationQueue *fileIOQueue;
    NSOperationQueue *dirWorkerQueue;
}

- (instancetype)initWithCPUs:(NSInteger)cpus dirs:(NSInteger)dirs files:(NSInteger)fileops defaults:(NSUserDefaults*)defaults {
    self = [super init];
    if (self) {
        self.defaults = defaults;

        cpuQueue = [NSOperationQueue new];
        [cpuQueue setMaxConcurrentOperationCount:cpus?cpus:NSOperationQueueDefaultMaxConcurrentOperationCount];

        dirWorkerQueue = [NSOperationQueue new];
        [dirWorkerQueue setMaxConcurrentOperationCount:dirs];

        fileIOQueue = [NSOperationQueue new];
        [fileIOQueue setMaxConcurrentOperationCount:fileops?fileops:2];
    }
    return self;
}

-(void)addFile:(File*)f {
    [self willChangeValueForKey:@"isBusy"];
    [f enqueueWorkersInCPUQueue:cpuQueue fileIOQueue:fileIOQueue defaults:self.defaults];
    [self didChangeValueForKey:@"isBusy"];
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
    [self willChangeValueForKey:@"isBusy"];
    [self didChangeValueForKey:@"isBusy"];
}

@end