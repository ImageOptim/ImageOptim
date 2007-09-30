//
//  Worker.m
//  ImageOptim
//
//  Created by porneL on 23.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "FileWorker.h"
#include <unistd.h>
#import "File.h"

@implementation FileWorker

-(id)initWithFile:(File *)aFile inQueue:(WorkerQueue *)aQueue;
{
	if (self = [self initWithQueue:aQueue])
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
	[file release];
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
			if (tempBytes[bytesPos] < ' ' || inputBufferPos == sizeof(inputBuffer)-1)
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
	if (![[NSFileManager defaultManager] isExecutableFileAtPath:path])
	{
		NSLog(@"Not executable %@ (launched with %@, btw)",path,arguments);
		return nil;
	}
	
	
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

	return task;
}


-(void)saveFileData:(NSData *)data
{
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:[file filePath]];
	[fileHandle writeData:data];
	[fileHandle truncateFileAtOffset:[data length]];
}
@end
