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
	NSString *temp = [self tempPath:@"PngCrush"];

	NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-brute",@"-cc",@"--",[file filePath],temp,nil];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSArray *chunks = [defaults arrayForKey:@"PngCrush.Chunks"];
	NSEnumerator *enu = [chunks objectEnumerator];
	NSDictionary *dict;
	while(dict = [enu nextObject])
	{
		NSString *name = [dict objectForKey:@"name"];
		if (name)
		{
			[args insertObject:name atIndex:0];
			[args insertObject:@"-rem" atIndex:0];
		}
	}
	
	if ([defaults boolForKey:@"PngCrush.Fix"])
	{
		[args insertObject:@"-fix" atIndex:0];
	}

	NSTask *task = [self taskForKey:@"PngCrush" bundleName:@"pngcrush" arguments:args];
	if (!task) return;
	
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
		if (fileSizeOptimized = [File fileByteSize:temp])
		{
			[file setFilePathOptimized:temp	size:fileSizeOptimized];			
		}
	}
	else NSLog(@"pngcrush failed");
	
	[task autorelease];
}

-(BOOL)parseLine:(NSString *)line
{
	int res;
	//NSLog(line);
	if ((res = [self readNumberAfter:@") =     " inLine:line]) || (res = [self readNumberAfter:@"IDAT chunks    =     " inLine:line]))
	{	
		if (!firstIdatSize)
		{
			firstIdatSize = res;
			//NSLog(@"Initial idat is %d",res);
		}
		else
		{
			int fileSize = [file byteSize];
			if (fileSize)
			{
				int optimized = fileSize + res - firstIdatSize;
				
				[file setByteSizeOptimized:optimized];
				
				//NSLog(@"pngcrush returned %d vs %d → %d",fileSize,optimized,[file byteSizeOptimized]);
			}
			else
			{
				//NSLog(@"ignoring %d idat, no file size",res);				
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
