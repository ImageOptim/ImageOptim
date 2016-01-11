
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

@synthesize isBusy;

- (instancetype)initWithCPUs:(NSInteger)cpus dirs:(NSInteger)dirs files:(NSInteger)fileops defaults:(NSUserDefaults*)defaults {
    self = [super init];
    if (self) {
        self.defaults = defaults;
        BOOL lowPriority = [defaults boolForKey:@"RunLowPriority"];

        cpuQueue = [NSOperationQueue new];
        cpuQueue.name = @"cpuQueue";
        cpuQueue.maxConcurrentOperationCount = cpus?cpus:NSOperationQueueDefaultMaxConcurrentOperationCount;

        dirWorkerQueue = [NSOperationQueue new];
        dirWorkerQueue.name = @"dirWorkerQueue";
        dirWorkerQueue.maxConcurrentOperationCount = dirs;

        fileIOQueue = [NSOperationQueue new];
        fileIOQueue.name = @"fileIOQueue";
        fileIOQueue.maxConcurrentOperationCount = fileops?fileops:2;

        if ([cpuQueue respondsToSelector:@selector(setQualityOfService:)]) {
            cpuQueue.qualityOfService = lowPriority ? NSQualityOfServiceUtility : NSQualityOfServiceUserInitiated;
            fileIOQueue.qualityOfService = lowPriority ? NSQualityOfServiceUtility : NSQualityOfServiceUserInitiated;
            dirWorkerQueue.qualityOfService = NSQualityOfServiceUserInitiated;
        }

        [cpuQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
        [dirWorkerQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
        [fileIOQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
    }
    return self;
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"operationCount"]) {
        NSOperationQueue *queue = object;
        NSUInteger newCount = queue.operationCount;
        BOOL wasBusy = self.isBusy;
        if (!wasBusy && newCount) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.isBusy = YES;
            });
        } else if (wasBusy && !newCount) {
            BOOL goingBusy = cpuQueue.operationCount > 0 || dirWorkerQueue.operationCount > 0 || fileIOQueue.operationCount > 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.isBusy = goingBusy;
            });
        }
    }
}


-(void)addFile:(File*)f {
    [f enqueueWorkersInCPUQueue:cpuQueue fileIOQueue:fileIOQueue defaults:self.defaults];
}

-(void)addDirWorker:(DirWorker *)d {
    [dirWorkerQueue addOperation:d];
}

-(NSNumber *)queueCount {
    return @(cpuQueue.operationCount + dirWorkerQueue.operationCount + fileIOQueue.operationCount);
}

-(void)cleanup {
    [dirWorkerQueue cancelAllOperations];
    [fileIOQueue cancelAllOperations];
    [cpuQueue cancelAllOperations];
}

-(void)wait {
    // any queue may be re-filled while waiting for another queue. This is wonky :(
    do {
        [dirWorkerQueue waitUntilAllOperationsAreFinished];
        [fileIOQueue waitUntilAllOperationsAreFinished];
        [cpuQueue waitUntilAllOperationsAreFinished];
    }
    while (dirWorkerQueue.operationCount > 0 || fileIOQueue.operationCount > 0 || cpuQueue.operationCount > 0);
}

@end
