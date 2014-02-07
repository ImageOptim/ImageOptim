//
//  Worker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "Worker.h"
#import "File.h"
#import "log.h"

@implementation Worker

@synthesize file, nextOperation;

-(id)settingsIdentifier {
    return @(0);
}

-(id)initWithFile:(File *)aFile {
    if (self = [self init]) {
        self.file = aFile;
    }
    return self;
}

-(BOOL)isRelatedTo:(File *)f {
    return (f == file);
}

-(BOOL)canSkip {

    if (![self isIdempotent]) return NO;

    NSDictionary *resultsBySettings;
    @synchronized(file) {
        resultsBySettings = [file.workersPreviousResults objectForKey:[self className]];
    }
    if (!resultsBySettings) return NO;

    NSNumber *previousResult = [resultsBySettings objectForKey:[self settingsIdentifier]];
    if (!previousResult) return NO;

    return file.byteSizeOptimized == [previousResult integerValue];
}

-(void)markResultForSkipping {
    @synchronized(file) {
        NSMutableDictionary *resultsBySettings = [file.workersPreviousResults objectForKey:[self className]];
        if (!resultsBySettings) {
            resultsBySettings = [NSMutableDictionary new];
            [file.workersPreviousResults setObject:resultsBySettings forKey:[self className]];
        }
        [resultsBySettings setObject:@(file.byteSizeOptimized) forKey:[self settingsIdentifier]];
    }
}

-(void)main {

    NSString *name = [[self className] stringByReplacingOccurrencesOfString:@"Worker" withString:@""];
    [file setStatus:@"progress" order:4 text:[NSString stringWithFormat:NSLocalizedString(@"Started %@",@"command name, tooltip"),name]];

    @try {
        if (![self isCancelled]) {
            if (![self canSkip]) {
                [self run];
                if (![self isCancelled]) [self markResultForSkipping];
            } else {
                IODebug("Skipping %@, because it already optimized %@", [self className], file.fileName);
            }
        }
    }
    @finally {
        if (![self isCancelled]) {
            [nextOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
        }
        [file setStatus:@"wait" order:2 text:NSLocalizedString(@"Waiting to start more optimizations",@"tooltip")];
    }
}

-(void)run {
}

-(BOOL)isIdempotent {
    return YES;
}

-(BOOL)makesNonOptimizingModifications {
    return NO;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@ %X ready %d, running %d, deleg %@",
            [self className],(unsigned int)[self hash],[self isReady],[self isExecuting],file];
}

@end
