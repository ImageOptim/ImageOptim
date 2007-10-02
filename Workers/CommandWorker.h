//
//  Worker.h
//  ImageOptim
//
//  Created by porneL on 23.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Worker.h"
#import "File.h";

@interface CommandWorker : Worker {
	File *file;
}
-(id)initWithFile:(File *)aFile;

-(BOOL)parseLine:(NSString *)line;
-(void)parseLinesFromHandle:(NSFileHandle *)commandHandle;

-(NSTask *)taskWithPath:(NSString*)path arguments:(NSArray *)arguments;


-(long)readNumberAfter:(NSString *)str inLine:(NSString *)line;

-(void)launchTask:(NSTask *)task;

-(NSString *)tempPath:(NSString*)baseName;

-(NSString *)executablePathForKey:(NSString *)prefsName bundleName:(NSString *)resourceName;

@end
