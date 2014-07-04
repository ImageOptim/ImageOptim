//
//  DirWorker.h
//
//  Created by porneL on 30.wrz.07.
//

#import <Cocoa/Cocoa.h>

@class FilesQueue;

@interface DirWorker : NSOperation {
	FilesQueue *filesQueue;
	NSURL *path;
    NSArray *extensions;
}

-(instancetype)initWithPath:(NSURL *)path filesQueue:(FilesQueue *)q extensions:(NSArray*)e;

@property (copy) NSURL *path;
@end
