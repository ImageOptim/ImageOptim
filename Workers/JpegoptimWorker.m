//
//  JpegoptimWorker.m
//  ImageOptim
//
//  Created by porneL on 7.paź.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "JpegoptimWorker.h"
#import "File.h"

@implementation JpegoptimWorker

-(void)run
{
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSString *executable = [self executablePathForKey:@"JpegOptim" bundleName:@"jpegoptim"];	
	if (!executable) return;
	
	NSString *temp = [self tempPath:@"JpegOptim"];
	
	NSTask *task = [self taskWithPath:executable arguments:[NSArray arrayWithObjects: @"--strip-all",@"-q",@"--",temp,nil]];
	
	if (![fm copyPath:[file filePath] toPath:temp handler:nil])
	{
		NSLog(@"Can't make temp copy of %@ in %@",[file filePath],temp);
	}
	
	NSPipe *commandPipe = [NSPipe pipe];
	NSFileHandle *commandHandle = [commandPipe fileHandleForReading];		
	
	[task setStandardOutput: commandPipe];	
	[task setStandardError: commandPipe];	
	
	[self launchTask:task];
	
	[self parseLinesFromHandle:commandHandle];
	
	[commandHandle closeFile];
	
	[task waitUntilExit];
	
	if (![task terminationStatus] && fileSizeOptimized)
	{
		[file setFilePathOptimized:temp	size:fileSizeOptimized];
	}
	
	[task release];
}

-(BOOL)parseLine:(NSString *)line
{
	int size;
	if (size = [self readNumberAfter:@" [OK] " inLine:line])
	{
		//NSLog(@"File size %d",size);
		[file setByteSize:size];
	}
	if (size = [self readNumberAfter:@" --> " inLine:line])
	{
		//NSLog(@"File size optimized %d",size);
		[file setByteSizeOptimized:size];
		fileSizeOptimized = size;
		return YES;
	}
	return NO;
}


@end
