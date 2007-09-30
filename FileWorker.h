//
//  Worker.h
//  ImageOptim
//
//  Created by porneL on 23.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Worker.h"
@class File;

@interface FileWorker : Worker {
	File *file;
}
-(id)initWithFile:(File *)aFile inQueue:(WorkerQueue *)aQueue;

-(BOOL)parseLine:(NSString *)line;
-(void)parseLinesFromHandle:(NSFileHandle *)commandHandle;

-(NSTask *)taskWithPath:(NSString*)path arguments:(NSArray *)arguments;
-(void)saveFileData:(NSData *)data;



@end
