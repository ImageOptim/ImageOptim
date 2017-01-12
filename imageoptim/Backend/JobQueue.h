
#import <Foundation/Foundation.h>

@class Job, DirScanner;

NS_ASSUME_NONNULL_BEGIN
@interface JobQueue : NSObject

-(void)addJob:(Job*)f;
-(void)addDirScanner:(DirScanner *)d;
-(void)wait;
-(void)cleanup;
-(NSNumber *)queueCount;
@property (assign, atomic) BOOL isBusy;

- (nullable instancetype)initWithCPUs:(NSInteger)cpus dirs:(NSInteger)dirs files:(NSInteger)fileops defaults:(NSUserDefaults*)defaults;
@end
NS_ASSUME_NONNULL_END
