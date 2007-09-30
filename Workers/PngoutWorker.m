//
//  PngoutWorker.m
//  ImageOptim
//
//  Created by porneL on 29.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PngoutWorker.h"
#import "File.h"

@implementation PngoutWorker

-(void)run
{
	NSTask *task = [self taskWithPath:@"/usr/bin/pngout" arguments:[NSArray arrayWithObjects: @"-v",@"-",@"-",nil]];
	
	if (!task) return;
	
	NSFileHandle *fileInputHandle = [NSFileHandle fileHandleForReadingAtPath:[file filePath]];
	if (fileInputHandle == nil)
	{
		NSLog(@"can't open %@",[file filePath]);
		return;
	}
	
	NSPipe *fileOutputPipe = [NSPipe pipe];
	NSFileHandle *fileOutputHandle = [fileOutputPipe fileHandleForReading];
	
	NSPipe *commandPipe = [NSPipe pipe];
	NSFileHandle *commandHandle = [commandPipe fileHandleForReading];		

	[task setStandardInput: fileInputHandle];		
	[task setStandardOutput: fileOutputHandle];	
	[task setStandardError: commandPipe];	
		
	[task launch];
	
	NSLog(@"launched pngout");
	[self parseLinesFromHandle:commandHandle];
	
	NSLog(@"finished reading lines");
	[commandHandle closeFile];
	
	//NSLog(@"Will read fileOutputHandle");
	//NSData *data = [fileOutputHandle readDataToEndOfFile];
	
	//NSLog(@"Will save data");
	//[self saveFileData:data];
	
	NSLog(@"finished reading output");
	
	[fileOutputHandle closeFile];
	[fileInputHandle closeFile];
		
	[task waitUntilExit];
	[task release];
	
	NSLog(@"PNGOUT finished");
}

-(BOOL)parseLine:(NSString *)line
{
	NSScanner *scan = [NSScanner scannerWithString:line];
	
	if ([line length] > 4 && [[line substringToIndex:4] isEqual:@" In:"])
	{
		NSLog(@"Foudn in %@",line);
		[scan setScanLocation:4];
		int byteSize=0;		
		if ([scan scanInt:&byteSize] && byteSize) [file setByteSize:byteSize];
	}
	else if ([line length] > 4 && [[line substringToIndex:4] isEqual:@"Out:"])
	{
		NSLog(@"Foudn out %@",line);
		[scan setScanLocation:4];
		int byteSize=0;		
		if ([scan scanInt:&byteSize] && byteSize) 
		{
			[file setByteSizeOptimized:byteSize];			
		}		
	}
	else if ([line length] >= 3 && [line characterAtIndex:2] == '%')
	{	
		NSLog(@"%@",line);
	}
	else if ([line length] >= 4 && [[line substringToIndex:4] isEqual:@"Took"])
	{
		NSLog(@"Tookline %@",line);
		return YES;
	}
	else NSLog(@"Dunno %@",line);
	
	return NO;
}

@end
