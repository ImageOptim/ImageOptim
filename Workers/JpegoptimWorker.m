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
	//	NSLog(@"temp file for opti: %@",temp);
	
	NSTask *task = [self taskWithPath:executable arguments:[NSArray arrayWithObjects: @"--strip-all",@"-q",@"--",temp,nil]];
	
	NSPipe *commandPipe = [NSPipe pipe];
	NSFileHandle *commandHandle = [commandPipe fileHandleForReading];		
	/*
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
	//else NSLog(@"Advpng failed");
	*/
	[task release];
}

-(BOOL)parseLine:(NSString *)line
{
/*	NSScanner *scan = [NSScanner scannerWithString:line];
	
	int original,optimized;
	
	if ([scan scanInt:&original] && [scan scanInt:&optimized])
	{		
		fileSizeOptimized = optimized;
		//		NSLog(@"advcomp returned %d vs %d",original,optimized);
		[file setByteSize:original];
		[file setByteSizeOptimized:optimized];
		return YES;		
	}
	//	NSLog(@"adv: Dunno what is %@",line);*/
	return NO;
}


@end
