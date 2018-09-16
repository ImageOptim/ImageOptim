
#import "JobQueue.h"
#import "Job.h"
#import "DirScanner.h"

@interface JobQueue ()
@property (strong) NSUserDefaults *defaults;
@end

@implementation JobQueue {
    NSOperationQueue *cpuQueue;
    NSOperationQueue *fileIOQueue;
    NSOperationQueue *dirWorkerQueue;
    dispatch_queue_t serialQueue;

    dispatch_source_t operationCountUpdateQueue;
}

@synthesize isBusy;

- (instancetype)initWithCPUs:(NSInteger)cpus dirs:(NSInteger)dirs files:(NSInteger)fileops defaults:(NSUserDefaults *)defaults {
    self = [super init];
    if (self) {
        self.defaults = defaults;
        BOOL lowPriority = [defaults boolForKey:@"RunLowPriority"];

        serialQueue = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);

        cpuQueue = [NSOperationQueue new];
        cpuQueue.name = @"cpuQueue";
        cpuQueue.maxConcurrentOperationCount = cpus ? cpus : NSOperationQueueDefaultMaxConcurrentOperationCount;

        dirWorkerQueue = [NSOperationQueue new];
        dirWorkerQueue.name = @"dirWorkerQueue";
        dirWorkerQueue.maxConcurrentOperationCount = dirs;

        fileIOQueue = [NSOperationQueue new];
        fileIOQueue.name = @"fileIOQueue";
        fileIOQueue.maxConcurrentOperationCount = fileops ? fileops : 2;

        if ([cpuQueue respondsToSelector:@selector(setQualityOfService:)]) {
            cpuQueue.qualityOfService = lowPriority ? NSQualityOfServiceUtility : NSQualityOfServiceUserInitiated;
            fileIOQueue.qualityOfService = lowPriority ? NSQualityOfServiceUtility : NSQualityOfServiceUserInitiated;
            dirWorkerQueue.qualityOfService = NSQualityOfServiceUserInitiated;
        }

        [cpuQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
        [dirWorkerQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
        [fileIOQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];

        operationCountUpdateQueue = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_OR, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_event_handler(operationCountUpdateQueue, ^{
            self.isBusy = self->cpuQueue.operationCount > 0 || self->dirWorkerQueue.operationCount > 0 || self->fileIOQueue.operationCount > 0;
        });
        dispatch_resume(operationCountUpdateQueue);
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    dispatch_source_merge_data(operationCountUpdateQueue, 1);
}

- (void)addJob:(Job *)f {
    [f enqueueWorkersInCPUQueue:cpuQueue fileIOQueue:fileIOQueue serialQueue:serialQueue defaults:self.defaults];
}

- (void)addDirScanner:(DirScanner *)d {
    [dirWorkerQueue addOperation:d];
}

- (NSNumber *)queueCount {
    return @(cpuQueue.operationCount + dirWorkerQueue.operationCount + fileIOQueue.operationCount);
}

- (void)cleanup {
    [dirWorkerQueue cancelAllOperations];
    [fileIOQueue cancelAllOperations];
    [cpuQueue cancelAllOperations];
}

- (void)wait {
    // any queue may be re-filled while waiting for another queue. This is wonky :(
    do {
        [dirWorkerQueue waitUntilAllOperationsAreFinished];
        [fileIOQueue waitUntilAllOperationsAreFinished];
        [cpuQueue waitUntilAllOperationsAreFinished];
    }
    while (dirWorkerQueue.operationCount > 0 || fileIOQueue.operationCount > 0 || cpuQueue.operationCount > 0);
}

@end
