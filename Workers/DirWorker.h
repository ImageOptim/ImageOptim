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
}

-(id)initWithPath:(NSString *)path filesQueue:(FilesQueue *)q;

@property (retain) FilesQueue *filesQueue;
@property (copy) NSString *path;
@end
