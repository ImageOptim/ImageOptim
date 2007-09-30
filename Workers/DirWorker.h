//
//  DirWorker.h
//  ImageOptim
//
//  Created by porneL on 30.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Worker.h"
@class FilesQueue;

@interface DirWorker : Worker {
	FilesQueue *filesQueue;
	NSString *path;
}

-(id)initWithPath:(NSString *)path filesQueue:(FilesQueue *)q;

@end
