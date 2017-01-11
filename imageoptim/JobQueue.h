
#import <Foundation/Foundation.h>

@class Job, DirWorker;

NS_ASSUME_NONNULL_BEGIN
@interface JobQueue : NSObject

-(void)addJob:(Job*)f;
-(void)addDirWorker:(DirWorker*)d;
-(void)wait;
-(void)cleanup;
-(NSNumber *)queueCount;
@property (assign, atomic) BOOL isBusy;

- (nullable instancetype)initWithCPUs:(NSInteger)cpus dirs:(NSInteger)dirs files:(NSInteger)fileops defaults:(NSUserDefaults*)defaults;
@end
NS_ASSUME_NONNULL_END
