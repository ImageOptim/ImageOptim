//
//  DirWorker.h
//
//  Created by porneL on 30.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import "Worker.h"
@class FilesQueue;

@interface DirWorker : Worker {
	FilesQueue *filesQueue;
	NSString *path;
    NSArray *extensions;
}

-(id)initWithPath:(NSString *)path filesQueue:(FilesQueue *)q extensions:(NSArray*)e;

@property (copy) NSString *path;
@end
