//
//  PngCrushWorker.m
//  ImageOptim
//
//  Created by porneL on 1.paź.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PngCrushWorker.h"


@implementation PngCrushWorker

-(void)run
{
	if (![file byteSize]) [file setByteSize:[self fileByteSize:[file filePath]]];
	
	NSString *temp = [self tempPath:@"PngCrush"];
//	NSLog(@"temp file for crush: %@",temp);
	
	NSString *executable = [self executablePathForKey:@"PngCrush" bundleName:@"pngcrush"];	
	if (!executable) return;

	NSTask *task = [self taskWithPath:executable arguments:[NSArray arrayWithObjects:@"-cc",@"--",[file filePath],temp,nil]];
	
	NSPipe *commandPipe = [NSPipe pipe];
	NSFileHandle *commandHandle = [commandPipe fileHandleForReading];		
	
	[task setStandardOutput: commandPipe];	
	[task setStandardError: commandPipe];	
	
	[self launchTask:task];
	
	[self parseLinesFromHandle:commandHandle];
	
	[commandHandle closeFile];
	
	[task waitUntilExit];	
	
	if (![task terminationStatus])
	{
		long fileSizeOptimized;
		if (fileSizeOptimized = [self fileByteSize:temp])
		{
			[file setFilePathOptimized:temp	size:fileSizeOptimized];			
		}
	}
	else NSLog(@"pngcrush failed");
	
	[task autorelease];
}

-(long)fileByteSize:(NSString *)afile
{
	NSDictionary *attr = [[NSFileManager defaultManager] fileAttributesAtPath:afile traverseLink:NO];
	if (attr) return [[attr objectForKey:NSFileSize] longValue];
	return 0;
}

-(BOOL)parseLine:(NSString *)line
{
	int res;
	NSLog(line);
	if ((res = [self readNumberAfter:@")=    " inLine:line]) || (res = [self readNumberAfter:@"IDAT chunks   =    " inLine:line]))
	{	
		if (!firstIdatSize)
		{
			firstIdatSize = res;
//			NSLog(@"Idat is %d",res);
		}
		else
		{
			int fileSize = [file byteSize];
			if (fileSize)
			{
				int optimized = fileSize + res - firstIdatSize;
				
				[file setByteSizeOptimized:optimized];
				
//				NSLog(@"pngcrush returned %d vs %d",fileSize,optimized);
			}
			else
			{
//				NSLog(@"ignoring %d idat, no file size",res);				
			}
		}
	}
	else 
	{
		NSRange substr = [line rangeOfString:@"Best pngcrush method"];
		if (substr.length)
		{
			return YES;			
		}
		else 
		{
//			NSLog(@"dunno %@",line);
			
		}

	}
	return NO;
}


-(BOOL)makesNonOptimizingModifications
{
	return YES;
}
@end
