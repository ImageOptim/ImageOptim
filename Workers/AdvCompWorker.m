//
//  AdvCompWorker.m
//  ImageOptim
//
//  Created by porneL on 30.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "AdvCompWorker.h"
#import "File.h"

@implementation AdvCompWorker

-(void)run
{
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSString *executable = [self executablePathForKey:@"AdvPng" bundleName:@"advpng"];	
	if (!executable) return;

	NSString *temp = [self tempPath:@"AdvPng"];
//	NSLog(@"temp file for opti: %@",temp);
	
	if (![fm copyPath:[file filePath] toPath:temp handler:nil])
	{
		NSLog(@"Can't make temp copy of %@ in %@",[file filePath],temp);
	}
	
	NSTask *task = [self taskWithPath:executable arguments:[NSArray arrayWithObjects: @"-z",@"--",temp,nil]];
	
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
	//else NSLog(@"Advpng failed");
	
	[task release];
}

-(BOOL)parseLine:(NSString *)line
{
	NSScanner *scan = [NSScanner scannerWithString:line];
	
	int original,optimized;
	
	if ([scan scanInt:&original] && [scan scanInt:&optimized])
	{		
		fileSizeOptimized = optimized;
//		NSLog(@"advcomp returned %d vs %d",original,optimized);
		[file setByteSize:original];
		[file setByteSizeOptimized:optimized];
		return YES;		
	}
//	NSLog(@"adv: Dunno what is %@",line);
	return NO;
}

@end
