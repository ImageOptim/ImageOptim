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
        tryfilters = [defaults boolForKey:@"PngOutTryFilters"];
        level = 3-[defaults integerForKey:@"PngOutLevel"];
        removechunks = [defaults boolForKey:@"PngOutRemoveChunks"];
        interruptIfTakesTooLong = [defaults boolForKey:@"PngOutInterruptIfTakesTooLong"];
    }
    return self;
}

-(void)run
{
//	NSLog(@"PNGOUT running");
	NSString *temp = [self tempPath];

    // uses stdout for file to force progress output to unbufferred stderr
	NSMutableArray *args = [NSMutableArray arrayWithObjects: @"-v",/*@"--",*/[file filePath],@"-",nil];


	if (tryfilters) // -r is not this option... I'll implement it later, maybe
	{
		[args insertObject:@"-r" atIndex:0];
	}

	if (level)
	{
		[args insertObject:[NSString stringWithFormat:@"-s%d",level] atIndex:0];
	}

	if (!removechunks)
	{
		[args insertObject:@"-k1" atIndex:0];
	}

	NSTask *task = [self taskForKey:@"PngOut" bundleName:@"pngout" arguments:args];
    if (!task) {
        return;
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

    if (interruptIfTakesTooLong) [task performSelector:@selector(interrupt) withObject:nil afterDelay:60.0];// TODO: configurable timeout?
	[self launchTask:task];

//	NSLog(@"launched pngout");
	[self parseLinesFromHandle:commandHandle];

    if (interruptIfTakesTooLong) [NSObject cancelPreviousPerformRequestsWithTarget:task selector:@selector(interrupt) object:nil];

    [commandHandle readInBackgroundAndNotify];
//	NSLog(@"finished reading lines");

	[task waitUntilExit];
    [commandHandle closeFile];
	[fileOutputHandle closeFile];

	if (![task terminationStatus] && fileSizeOptimized)
	{
//		NSLog(@"Will save data");
		[file setFilePathOptimized:temp size:fileSizeOptimized toolName:@"PNGOUT"];
	}
	//else NSLog(@"pngout failed");

	;

//	NSLog(@"PNGOUT finished");
}

-(BOOL)makesNonOptimizingModifications
{
	return YES;
}

-(BOOL)parseLine:(NSString *)line
{
    // run PNGOUT killing timer
    [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];

	NSScanner *scan = [NSScanner scannerWithString:line];

	if ([line length] > 4 && [[line substringToIndex:4] isEqual:@" In:"])
	{
//		NSLog(@"Foudn in %@",line);
		[scan setScanLocation:4];
		int byteSize=0;
		if ([scan scanInt:&byteSize] && byteSize) [file setByteSize:byteSize];
	}
	else if ([line length] > 4 && [[line substringToIndex:4] isEqual:@"Out:"])
	{
//		NSLog(@"Foudn out %@",line);
		[scan setScanLocation:4];
		int byteSize=0;
		if ([scan scanInt:&byteSize] && byteSize)
		{
			fileSizeOptimized = byteSize;
			//[file setByteSizeOptimized:byteSize];
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
