
#import <Foundation/Foundation.h>

@class File, DirWorker;

@interface FilesQueue : NSObject

-(void)addFile:(nonnull File*)f;
-(void)addDirWorker:(nonnull DirWorker*)d;
-(void)wait;
-(void)cleanup;
-(nonnull NSNumber *)queueCount;
@property (assign, atomic) BOOL isBusy;

- (nullable instancetype)initWithCPUs:(NSInteger)cpus dirs:(NSInteger)dirs files:(NSInteger)fileops defaults:(nonnull NSUserDefaults*)defaults;
@end