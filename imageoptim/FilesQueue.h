
#import <Foundation/Foundation.h>

@class File, DirWorker;

@interface FilesQueue : NSObject

-(void)addFile:(nonnull File*)f;
-(void)addFile:(nonnull File*)f enableLossy:(BOOL)l;
-(void)addDirWorker:(nonnull DirWorker*)d;
-(void)wait;
-(void)cleanup;
-(BOOL)isBusy;
-(nonnull NSNumber *)queueCount;

- (nullable instancetype)initWithCPUs:(NSInteger)cpus dirs:(NSInteger)dirs files:(NSInteger)fileops defaults:(nonnull NSUserDefaults*)defaults;
@end