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
	NSTask *task = [self taskWithPath:@"/usr/local/bin/advpng" arguments:[NSArray arrayWithObjects: @"-z",@"--",[file filePath],nil]];
	
	NSPipe *commandPipe = [NSPipe pipe];
	NSFileHandle *commandHandle = [commandPipe fileHandleForReading];		
	
	[task setStandardOutput: commandPipe];	
	[task setStandardError: commandPipe];	
	
	[task launch];
	
	[self parseLinesFromHandle:commandHandle];
	
	[commandHandle closeFile];
	
	[task waitUntilExit];
	[task release];
}

-(BOOL)parseLine:(NSString *)line
{
	NSScanner *scan = [NSScanner scannerWithString:line];
	
	int original,optimized;
	
	if ([scan scanInt:&original] && [scan scanInt:&optimized])
	{		
		NSLog(@"advcomp returned %d vs %d",original,optimized);		
		return YES;		
	}
	NSLog(@"adv: Dunno what is %@",line);
	return NO;
}

@end
