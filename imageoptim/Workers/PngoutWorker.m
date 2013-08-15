//
//  PngoutWorker.m
//  ImageOptim
//
//  Created by porneL on 29.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PngoutWorker.h"
#import "../File.h"

@implementation PngoutWorker

-(id)init {
    if (self = [super init])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        level = 3-[defaults integerForKey:@"PngOutLevel"];
        removechunks = [defaults boolForKey:@"PngOutRemoveChunks"];
        interruptIfTakesTooLong = [defaults boolForKey:@"PngOutInterruptIfTakesTooLong"];
    }
    return self;
}

-(BOOL)runWithTempPath:(NSString*)temp
{
    // uses stdout for file to force progress output to unbufferred stderr
	NSMutableArray *args = [NSMutableArray arrayWithObjects: @"-v",/*@"--",*/[file filePath],@"-",nil];
	
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
    
	if (![[NSFileManager defaultManager] createFileAtPath:temp contents:[NSData data] attributes:nil])
	{	
		NSLog(@"Cant create %@",temp);
	}
		
	NSFileHandle *fileOutputHandle = [NSFileHandle fileHandleForWritingAtPath:temp];
	
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
    
    [commandHandle readInBackgroundAndNotify];
	
	[task waitUntilExit];
    [commandHandle closeFile];
	[fileOutputHandle closeFile];
	
	if ([task terminationStatus]) return NO;

	if (fileSizeOptimized) {
        return [file setFilePathOptimized:temp size:fileSizeOptimized toolName:@"PNGOUT"];
	}
    return NO;
}

-(BOOL)makesNonOptimizingModifications
{
	return removechunks;
}

-(BOOL)parseLine:(NSString *)line
{
    // run PNGOUT killing timer
    [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];
    
	NSScanner *scan = [NSScanner scannerWithString:line];
	
    if ([line length] > 4 && [[line substringToIndex:4] isEqual:@"Out:"])
	{
		[scan setScanLocation:4];
		int byteSize=0;		
		if ([scan scanInt:&byteSize] && byteSize) 
		{
			fileSizeOptimized = byteSize;
		}
	}
	else if ([line length] >= 3 && [line characterAtIndex:2] == '%')
	{	
//		NSLog(@"%@",line);
	}
	else if ([line length] >= 4 && [[line substringToIndex:4] isEqual:@"Took"])
	{
//		NSLog(@"Tookline %@",line);
		return YES;
	}	
	return NO;
}

@end
