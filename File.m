//
//  File.m
//  ImageOptim
//
//  Created by porneL on 8.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "File.h"


@implementation File

-(id)init
{
	return [self initWithFilePath:@"Test"];
}

-(id)initWithFilePath:(NSString *)name
{
	if (self = [super init])
	{	
		[self setFilePath:name];
		NSLog(@"Created new");
		lock = [NSLock new];
		localWorkerQueue = [NSMutableArray new];
	}
	return self;	
}

-(NSString *)fileName
{
	if (displayName) return displayName;
	if (filePath) return filePath;
	return @"N/A";
}

-(NSString *)filePath
{
	if (filePath) return filePath;
	return @"/tmp/!none!";
}


-(void)setFilePath:(NSString *)s
{
	[filePath release];
	filePath = [s copy];
	
	NSString *newDisplay = [[[NSFileManager defaultManager] displayNameAtPath:filePath] copy];
	[displayName release];
	displayName = newDisplay;
}

-(long)byteSize
{
	return byteSize;
}

-(long)byteSizeOptimized
{
	return byteSizeOptimized;
}

- (id)copyWithZone:(NSZone *)zone
{
	File *f = [[File allocWithZone:zone] init];
	[f setByteSize:byteSize];
	[f setByteSizeOptimized:byteSizeOptimized];
	[f setFilePath:filePath];
	NSLog(@"copied");
	return f;
}

-(void)setByteSize:(long)size
{
	if (!byteSize)
	{
		NSLog(@"setting file size of %@ to %d",self,size);
		byteSize = size;
		if (!byteSizeOptimized || byteSizeOptimized > byteSize) [self setByteSizeOptimized:size];		
	}
	else if (byteSize != size)
	{
		NSLog(@"crappy size given! %d, have %d",size,byteSize);
	}
}

-(float)percentOptimized
{
	if (![self isOptimized]) return 0.0;
	float p = 100.0 - 100.0* (float)byteSizeOptimized/(float)byteSize;
	if (p<0) return 0.0;
	return p;
}

-(void)setPercentOptimized:(float)f
{
	// just for KVO
}

-(float)percentDone
{
	return percentDone;
}

-(void)setPercentDone:(float)d
{
	percentDone = d;
}
-(BOOL)isOptimized
{
	return byteSizeOptimized!=0;
}

-(void)setByteSizeOptimized:(long)size
{
	if (!byteSizeOptimized || size < byteSizeOptimized)
	{
		NSLog(@"We've got a new winner. old %d new %d",byteSizeOptimized,size);
		byteSizeOptimized = size;
		[self setPercentOptimized:1.0]; //just for KVO
	}
}

-(void)removeOldFilePathOptimized:(NSString *)old
{
	if ([old length])
	{
		[[NSFileManager defaultManager] removeFileAtPath:old handler:nil];		
	}
}

-(void)setFilePathOptimized:(NSString *)path size:(long)size
{
	NSString *oldFile = nil;
	
	[lock lock];
	if (size <= byteSizeOptimized)
	{
		oldFile = filePathOptimized;		
		filePathOptimized = [path copy];
		[self setByteSizeOptimized:size];
	}
	[lock unlock];
	
	if (oldFile)
	{
		[self removeOldFilePathOptimized:oldFile];
		[oldFile release];
	}
	NSLog(@"Got optimized %db path %@",size,path);
}

-(void)workerHasFinished:(Worker *)worker
{
	
}

-(BOOL)startWorkersInQueue:(WorkerQueue *)workerQueue
{
	Worker *w = NULL;
	BOOL waitForChunksRemoved = NO;
	
	[globalWorkerQueue release];
	globalWorkerQueue = [workerQueue retain];
	
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
	if ([defs boolForKey:@"PngCrush.Enabled"])
	{
		w = [[PngCrushWorker alloc] initWithFile:self inQueue:workerQueue];
		[workerQueue addWorker:w];
		[w release];
	}
	if ([defs boolForKey:@"PngOut.Enabled"])
	{
		w = [[PngoutWorker alloc] initWithFile:self inQueue:workerQueue];
		[workerQueue addWorker:w];
		[w release];		
	}
	if ([defs boolForKey:@"OptiPng.Enabled"])
	{
		w = [[OptiPngWorker alloc] initWithFile:self inQueue:workerQueue];
		[workerQueue addWorker:w];
		[w release];		
	}
	if ([defs boolForKey:@"AdvPng.Enabled"])
	{
		w = [[AdvCompWorker alloc] initWithFile:self inQueue:workerQueue];
		[workerQueue addWorker:w];
		[w release];
	}
	
	if (w == NULL)
	{
		NSLog(@"Nothing enabled!");
		return NO;
	}
	return YES;
}

-(void)dealloc
{
	NSLog(@"Dealloc %@",self);
	[self removeOldFilePathOptimized:filePathOptimized];
	[filePathOptimized release];
	[filePath release];
	[displayName release];
	[lock release];
	[localWorkerQueue release];
	[globalWorkerQueue release];
	[super dealloc];
}


-(NSString *)description
{
	NSString *s = [NSString stringWithFormat:@"%@ %d/%d", filePath,byteSize,byteSizeOptimized];
	return s;
}
@end