//
//  JobProxy.m
//
//  Cocoa is very crashy when using bindings that may be updated from non-main thread,

#import "Backend/Job.h"
#import "Backend/File.h"
#import "JobProxy.h"

@interface JobProxy () {
    NSMutableDictionary *props;
}
@end

@implementation JobProxy

-(instancetype)initWithJob:(Job *)aJob {
    if (self = [self init]) {
        job = aJob;
        props = [NSMutableDictionary new];

        for(NSString *prop in [JobProxy propertiesToProxy]) {
            id val = [job valueForKey:prop];
            [props setObject:val ? val : [NSNull null] forKey:prop];
            [job addObserver: self
                  forKeyPath: prop
                     options: NSKeyValueObservingOptionPrior | NSKeyValueObservingOptionNew
                     context: NULL];
        }
    }
    return self;
}

-(Job *)job {
    return job;
}

-(BOOL)revert {
    return [job revert];
}

-(BOOL)stop {
    return [job stop];
}

-(void)cleanup {
    [job cleanup];
}

-(NSURL *) previewItemURL {
    return [job previewItemURL];
}

-(NSString *) previewItemTitle {
    return [job previewItemTitle];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL aSelector = [invocation selector];

    if ([job respondsToSelector:aSelector])
        [invocation invokeWithTarget:job];
    else
        [super forwardInvocation:invocation];
}

-(BOOL)canRevert {
    return [[props objectForKey:@"canRevert"] boolValue];
}

-(BOOL)isDone {
    return [[props objectForKey:@"isDone"] boolValue];
}

-(BOOL)isFailed {
    return [[props objectForKey:@"isFailed"] boolValue];
}

-(BOOL)isBusy {
    return [[props objectForKey:@"isBusy"] boolValue];
}

-(BOOL)isStoppable {
    return [[props objectForKey:@"isStoppable"] boolValue];
}

-(BOOL)isOptimized {
    return [[props objectForKey:@"isOptimized"] boolValue];
}

-(NSURL *)filePath {
    return [job filePath];
}

-(NSString *)fileName {
    return [job fileName];
}

static id nullToNil(id maybeNull) {
    if (maybeNull == [NSNull null]) return nil;
    return maybeNull;
}

-(NSString *)statusText {
    return nullToNil([props objectForKey:@"statusText"]);
}

-(NSString *)bestToolName {
    return nullToNil([props objectForKey:@"bestToolName"]);
}

-(NSString *)displayName {
    return [job displayName];
}

-(NSString *)statusImageName {
    return nullToNil([props objectForKey:@"statusImageName"]);
}

-(NSNumber *)byteSizeOptimized {
    return nullToNil([props objectForKey:@"byteSizeOptimized"]);
}

-(NSNumber *)byteSizeOriginal {
    return nullToNil([props objectForKey:@"byteSizeOriginal"]);
}

-(File *)savedOutput {
    return nullToNil([props objectForKey:@"savedOutput"]);
}

-(File *)savedOutputOrInput {
    return job.savedOutput ? job.savedOutput : job.unoptimizedInput;
}

-(File *)percentOptimized {
    return nullToNil([props objectForKey:@"percentOptimized"]);
}

-(NSString *)description {
    return [NSString stringWithFormat:@"Proxy for {%@}", job];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    return ![[JobProxy propertiesToProxy] containsObject:theKey];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    BOOL isPrior = [[change valueForKey:@"notificationIsPrior"] boolValue];
    NSLog(@"observed prior=%d main=%d  %@ %@", (int)isPrior, (int)[NSThread isMainThread], keyPath, change);
    BOOL isPercentRelated = [keyPath isEqualToString:@"byteSizeOptimized"] ||
    [keyPath isEqualToString:@"byteSizeOriginal"] ||
    [keyPath isEqualToString:@"savedOutput"] ||
    [keyPath isEqualToString:@"isDone"];
    void (^cb)(void) = ^{
        if (isPrior) {
            // hoping Cocoa will not do anything silly on the main thread while observing unchanged value
            [self willChangeValueForKey:keyPath];
            if (isPercentRelated) {
                [self willChangeValueForKey:@"percentOptimized"];
            }
        } else {
            id new = change[@"new"];
            [self->props setObject:new forKey:keyPath];
            if (isPercentRelated) {
                [self didChangeValueForKey:@"percentOptimized"];
            }
            NSLog(@"Did change %@ to %@", keyPath, new);
            [self didChangeValueForKey:keyPath];
        }
    };

    // ensure didChangeValueForKey is always on the main thread, as otherwise Cocoa bindings are very crashy
    if ([NSThread isMainThread]) {
        cb();
    } else {
        dispatch_async(dispatch_get_main_queue(), cb);
    }
}

-(void)dealloc {
    for(NSString *prop in [JobProxy propertiesToProxy]) {
        [job removeObserver:self forKeyPath: prop];
    }
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[JobProxy allocWithZone:zone] initWithJob:job];
}

+(NSArray<NSString *> *)propertiesToProxy {
    return @[
        @"bestToolName",
        @"byteSizeOptimized",
        @"byteSizeOriginal",
        @"canRevert",
        @"isBusy",
        @"isDone",
        @"isFailed",
        @"isOptimized",
        @"isStoppable",
        @"percentOptimized",
        @"savedOutput",
        @"statusImageName",
        @"statusOrder",
        @"statusText",
    ];
}

@end
