//
//  Worker.h
//
//  Created by porneL on 23.wrz.07.
//

#import "Worker.h"
#import <Cocoa/Cocoa.h>

@class Job, File;

@interface CommandWorker : Worker {
    NSTask *task;
}

- (BOOL)parseLine:(NSString *)line;
- (void)parseLinesFromHandle:(NSFileHandle *)commandHandle;

// initialises field task with path and arguments
- (void)taskWithPath:(NSString *)path arguments:(NSArray *)arguments;

- (long)readNumberAfter:(NSString *)str inLine:(NSString *)line;

- (void)launchTask;
- (BOOL)waitUntilTaskExit;

// gets the path of the executable
- (NSString *)executablePathForKey:(NSString *)prefsName bundleName:(NSString *)resourceName;

- (BOOL)taskForKey:(NSString *)key bundleName:(NSString *)resourceName arguments:(NSArray *)args;

- (BOOL)optimizeFile:(File *)file toTempPath:(NSURL *)temp;
- (NSString *)pathForExecutableName:(NSString *)resourceName;

- (NSInteger)timelimitForLevel:(NSInteger)level;
@end
