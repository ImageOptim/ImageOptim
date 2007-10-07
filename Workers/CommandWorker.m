//
//  Worker.m
//  ImageOptim
//
//  Created by porneL on 23.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CommandWorker.h"
#include <unistd.h>
#import "File.h"

@implementation CommandWorker

-(id)initWithFile:(File *)aFile
{
	if (self = [self init])
	{
		file = [aFile retain];
	}
	return self;
}

-(BOOL)parseLine:(NSString *)line
{
	/* stub */
	return NO;
}


-(void)dealloc
{
	[file release]; file = nil;
	[super dealloc];
}

-(void)parseLinesFromHandle:(NSFileHandle *)commandHandle
{
	NSData *temp;
	char inputBuffer[4096];
	int inputBufferPos=0;	
	while((temp = [commandHandle availableData]) && [temp length]) 
	{			
		const char *tempBytes = [temp bytes];
		int bytesPos=0, bytesLength = [temp length];
		
		while(bytesPos < bytesLength)
		{
			if (tempBytes[bytesPos] == '\n' || tempBytes[bytesPos] == '\r' || inputBufferPos == sizeof(inputBuffer)-1)
			{
				inputBuffer[inputBufferPos] = '\0';
				if ([self parseLine:[NSString stringWithUTF8String:inputBuffer]])
				{
					return;				
				}
				inputBufferPos=0;bytesPos++;
			}
			else
			{
				inputBuffer[inputBufferPos++] = tempBytes[bytesPos++];
			}
		}
	}
}

-(NSTask *)taskWithPath:(NSString*)path arguments:(NSArray *)arguments;
{
	NSTask *task;
	task = [[NSTask alloc] init];
	
	[task setLaunchPath: path];
	[task setArguments: arguments];

	// clone the current environment
	NSMutableDictionary* environment =
		[NSMutableDictionary dictionaryWithDictionary:
			[[NSProcessInfo processInfo] environment]
		];
	// set up for unbuffered I/O
	[environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
	[task setEnvironment:environment];		

	
//	NSLog(@"Ready to run %@ %@",path,arguments);
	return task;
}

-(void)launchTask:(NSTask *)task
{
	@try
	{			
		[task launch];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"RunLowPriority"])
		{
			int pid = [task processIdentifier];
	//		NSLog(@"running with lopri %d",pid);
			if (pid > 1) setpriority(PRIO_PROCESS, pid, 10);
		}
	}
	@catch(NSException *e)
	{
		NSLog(@"Failed to launch %@ - %@",[self className],e);
	}
}

-(long)readNumberAfter:(NSString *)str inLine:(NSString *)line
{
	NSRange substr = [line rangeOfString:str];
	
	if (substr.length && [line length] > substr.location + [str length])
	{		
		NSScanner *scan = [NSScanner scannerWithString:line];	
		[scan setScanLocation:substr.location + [str length]];
		
		int res;
		if ([scan scanInt:&res])
		{
			return res;
		}
	}
	return 0;
}

-(NSString *)executablePathForKey:(NSString *)prefsName bundleName:(NSString *)resourceName
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *path = nil;
	
	if ([defs boolForKey:[NSString stringWithFormat:@"%@.Bundle",prefsName]])
	{
		if ((path = [[NSBundle mainBundle] pathForResource:resourceName ofType:nil]) && [[NSFileManager defaultManager] isExecutableFileAtPath:path])
		{
			return path;
		}
		else
		{
			NSLog(@"There's no bundled executable for %@ - disabling",prefsName);
			[defs setBool:NO forKey:[NSString stringWithFormat:@"%@.Bundle",prefsName]];
		}
	}

	path = [defs stringForKey:[NSString stringWithFormat:@"%@.Path",prefsName]];
	if ([path length] && [[NSFileManager defaultManager] isExecutableFileAtPath:path])
	{
		return path;
	}
	
	NSLog(@"Can't find working executable for %@ - disabling",prefsName);
	
	[defs setBool:NO forKey:[NSString stringWithFormat:@"%@.Enabled",prefsName]];
	
	return nil;
}

-(NSString *)tempPath:(NSString*)baseName
{
	return [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat:@"ImageOptim.%@.%x.%x.png",baseName,[file hash],random()]];
}

-(id)delegate
{
	return file;
}
@end
