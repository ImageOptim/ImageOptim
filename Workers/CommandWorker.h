//
//  Worker.h
//
//  Created by porneL on 23.wrz.07.
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

-(NSTask *)taskForKey:(NSString *)key bundleName:(NSString *)resourceName arguments:(NSArray *)args;

@end
