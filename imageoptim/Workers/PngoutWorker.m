//
//  PngoutWorker.m
//  ImageOptim
//
//  Created by porneL on 29.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PngoutWorker.h"
#import "../File.h"
#import "../log.h"

@implementation PngoutWorker

-(id)init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        level = 3-[defaults integerForKey:@"PngOutLevel"];
        removechunks = [defaults boolForKey:@"PngOutRemoveChunks"];
        interruptIfTakesTooLong = [defaults boolForKey:@"PngOutInterruptIfTakesTooLong"];
    }
    return self;
}

-(NSInteger)settingsIdentifier {
    return level*4 + removechunks*2 + interruptIfTakesTooLong;
}

-(BOOL)runWithTempPath:(NSURL *)temp {
    // uses stdout for file to force progress output to unbufferred stderr
    NSMutableArray *args = [NSMutableArray arrayWithObjects: @"-v",/*@"--",*/file.filePathOptimized.path,@"-",nil];

    [args insertObject:@"-r" atIndex:0];

    int actualLevel = (int)level;
    if ([file isLarge] && level < 2) {
        actualLevel++; // use faster setting for large files
    }

    if (actualLevel) { // s0 is default
        [args insertObject:[NSString stringWithFormat:@"-s%d",actualLevel] atIndex:0];
    }

    if (!removechunks) { // -k0 (remove) is default
        [args insertObject:@"-k1" atIndex:0];
    }

    if (![self taskForKey:@"PngOut" bundleName:@"pngout" arguments:args]) {
        return NO;
    }

    NSError *err = nil;
    [[NSData new] writeToURL:temp atomically:NO];
    NSFileHandle *fileOutputHandle = [NSFileHandle fileHandleForWritingToURL:temp error:&err];

    if (!fileOutputHandle) {
        IOWarn("Can't create %@ %@",temp.path, err);
        return NO;
    }

    NSPipe *commandPipe = [NSPipe pipe];
    NSFileHandle *commandHandle = [commandPipe fileHandleForReading];

    [task setStandardOutput: fileOutputHandle];
    [task setStandardError: commandPipe];

    double timelimit = 10.0 + [file byteSizeOriginal]/1024.0;
    if (timelimit > 60.0) timelimit = 60.0;

    if (interruptIfTakesTooLong) [task performSelector:@selector(interrupt) withObject:nil afterDelay:timelimit];
    [self launchTask];

    [self parseLinesFromHandle:commandHandle];

    if (interruptIfTakesTooLong) [NSObject cancelPreviousPerformRequestsWithTarget:task selector:@selector(interrupt) object:nil];

    [task waitUntilExit];
    [commandHandle closeFile];
    [fileOutputHandle closeFile];

    int status = [task terminationStatus]; // status = 2 early exit
    if (status && (status != 2 || !fileSizeOptimized)) {
        return NO;
    }

    if (fileSizeOptimized) {
        return [file setFilePathOptimized:temp size:fileSizeOptimized toolName:@"PNGOUT"];
    }
    return NO;
}

-(BOOL)makesNonOptimizingModifications {
    return removechunks;
}

-(BOOL)parseLine:(NSString *)line {
    // run PNGOUT killing timer
    [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];

    NSScanner *scan = [NSScanner scannerWithString:line];

    if ([line length] > 4 && [[line substringToIndex:4] isEqual:@"Out:"]) {
        [scan setScanLocation:4];
        int byteSize=0;
        if ([scan scanInt:&byteSize] && byteSize) {
            fileSizeOptimized = byteSize;
        }
    } else if ([line length] >= 3 && [line characterAtIndex:2] == '%') {
    } else if ([line length] >= 4 && [[line substringToIndex:4] isEqual:@"Took"]) {
        return YES;
    }
    return NO;
}

@end
