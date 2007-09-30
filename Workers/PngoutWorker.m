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
	NSTask *task = [self taskWithPath:@"/usr/local/bin/pngout" arguments:[NSArray arrayWithObjects: @"-v",@"-",@"-",nil]];
	
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
	
	[self parseLinesFromHandle:commandHandle];
	
	[self saveFileData:[fileOutputHandle readDataToEndOfFile]];
	
	[fileOutputHandle closeFile];
	[fileInputHandle closeFile];
	[commandHandle closeFile];
		
	[task waitUntilExit];
	[task release];
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
	}
	else if ([line length] >= 4 && [[line substringToIndex:4] isEqual:@"Took"])
	{
		return YES;
	}
	//else NSLog(@"Dunno %@",line);
	
	return NO;
}

@end
