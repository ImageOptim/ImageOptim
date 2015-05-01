
#import <Foundation/Foundation.h>

@class File, DirWorker;

@interface FilesQueue : NSObject

-(void)addFile:(File*)f;
-(void)addDirWorker:(DirWorker*)d;
-(void)wait;
-(void)cleanup;
-(BOOL)isBusy;
-(NSNumber *)queueCount;

- (instancetype)initWithCPUs:(NSInteger)cpus dirs:(NSInteger)dirs files:(NSInteger)fileops defaults:(NSUserDefaults*)defaults;
@end