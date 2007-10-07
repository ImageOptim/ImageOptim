//
//  File.m
//  ImageOptim
//
//  Created by porneL on 8.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "File.h"
#import "WorkerQueue.h"
#import "AdvCompWorker.h"
#import "PngoutWorker.h"
#import "OptiPngWorker.h"
#import "PngCrushWorker.h"

@implementation File

-(id)initWithFilePath:(NSString *)name;
{
	if (self = [self init])
	{	
		[self setFilePath:name];
		[self setStatus:@"wait"];
		lock = [NSLock new];
//		NSLog(@"Created new");
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
	if (filePath != s)
	{
		[filePath release];
		filePath = [s copy];
		
		NSString *newDisplay = [[[NSFileManager defaultManager] displayNameAtPath:filePath] copy];
		[displayName release];
		displayName = newDisplay;		
	}
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
//	NSLog(@"copied");
	return f;
}

-(void)setByteSize:(long)size
{
	if (!byteSize && size > 10)
	{
//		NSLog(@"setting file size of %@ to %d",self,size);
		byteSize = size;
		if (!byteSizeOptimized || byteSizeOptimized > byteSize) [self setByteSizeOptimized:size];		
	}
	else if (byteSize != size)
	{
//		NSLog(@"crappy size given! %d, have %d",size,byteSize);
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
	if ((!byteSizeOptimized || size < byteSizeOptimized) && size > 10)
	{
//		NSLog(@"We've got a new winner. old %d new %d",byteSizeOptimized,size);
		byteSizeOptimized = size;
		[self setPercentOptimized:0]; //just for KVO
	}
}

-(void)removeOldFilePathOptimized:(NSString *)old
{
	if (old && [old length])
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
		
	if (oldFile)
	{
		[self removeOldFilePathOptimized:oldFile];
		[oldFile release];
	}
	[lock unlock];
//	NSLog(@"Got optimized %db path %@",size,path);
}

-(BOOL)saveResult
{
	@try
	{
		NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
		BOOL preserve = [defs boolForKey:@"PreservePermissions"];
		BOOL backup = [defs boolForKey:@"BackupFiles"];
		NSFileManager *fm = [NSFileManager defaultManager];
		
		if (backup)
		{
			NSString *backupPath = [filePath stringByAppendingString:@"~"];
			
			[fm removeFileAtPath:backupPath handler:nil];
			
			BOOL res;
			if (preserve)
			{
				res = [fm copyPath:filePath toPath:backupPath handler:nil];
			}
			else
			{
				res = [fm movePath:filePath toPath:backupPath handler:nil];
			}
			
			if (!res)
			{
				NSLog(@"failed to save backup as %@ (preserve = %d)",backupPath,preserve);
				return NO;
			}
		}
		
		if (preserve)
		{		
			NSFileHandle *read = [NSFileHandle fileHandleForReadingAtPath:filePathOptimized];
			NSFileHandle *write = [NSFileHandle fileHandleForWritingAtPath:filePath];
			NSData *data = [read readDataToEndOfFile];
			
			if ([data length] == byteSizeOptimized && [data length] > 10)
			{
				[write writeData:data];
				[write truncateFileAtOffset:[data length]];
			}
			else 
			{
				NSLog(@"Temp file size %d does not match expected %d",[data length],byteSizeOptimized);
				return NO;				
			}
		}
		else
		{
			if (!backup) {[fm removeFileAtPath:filePath handler:nil];}
			
			if (![fm movePath:filePathOptimized toPath:filePath handler:nil]) 
			{
				NSLog(@"Failed to move from %@ to %@",filePathOptimized, filePath);
				return NO;				
			}
		}
	}
	@catch(NSException *e)
	{
		NSLog(@"Exception thrown %@",e);
		return NO;
	}
	return YES;
}

-(void)workerHasStarted:(Worker *)worker
{
	[lock lock];
	workersActive++;
	[self setStatus:@"progress"];
	[lock unlock];
}

-(void)workerHasFinished:(Worker *)worker
{
	[lock lock];
	workersActive--;
	workersFinished++;
	
	if (!byteSize || !byteSizeOptimized)
	{
		[self setStatus:@"err"];
	}
	else if (workersFinished == workersTotal)
	{
		if (byteSize > byteSizeOptimized)
		{
			if ([self saveResult])
			{
				[self setStatus:@"ok"];						
			}
			else [self setStatus:@"err"];
		}
		else [self setStatus:@"noopt"];	
	}
	else if (workersActive == 0)
	{
		[self setStatus:@"wait"];
	}
	[lock unlock];
}

-(void)enqueueWorkersInQueue:(WorkerQueue *)queue
{
	Worker *w = NULL;
	NSMutableArray *runFirst = [NSMutableArray new];
	NSMutableArray *runLater = [NSMutableArray new];
		
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
	if ([defs boolForKey:@"PngCrush.Enabled"])
	{
		w = [[PngCrushWorker alloc] initWithFile:self];
		if ([w makesNonOptimizingModifications]) [runFirst addObject:w];
		else [runLater addObject:w];
		[w release];
	}
	if ([defs boolForKey:@"PngOut.Enabled"])
	{
		w = [[PngoutWorker alloc] initWithFile:self];
		if ([w makesNonOptimizingModifications]) [runFirst addObject:w];
		else [runLater addObject:w];
		[w release];		
	}
	if ([defs boolForKey:@"OptiPng.Enabled"])
	{
		w = [[OptiPngWorker alloc] initWithFile:self];
		if ([w makesNonOptimizingModifications]) [runFirst addObject:w];
		else [runLater addObject:w];
		[w release];		
	}
	if ([defs boolForKey:@"AdvPng.Enabled"])
	{
		w = [[AdvCompWorker alloc] initWithFile:self];
		if ([w makesNonOptimizingModifications]) [runFirst addObject:w];
		else [runLater addObject:w];
		[w release];
	}
	
	NSEnumerator *enu = [runFirst objectEnumerator];
	Worker *lastWorker = nil;
	
//	NSLog(@"file %@ has workers first %@ and later %@",self,runFirst,runLater);
		
	workersTotal = [runFirst count] + [runLater count];
	workersActive = 0;
	workersFinished = 0;
	
	while(w = [enu nextObject])
	{
		[queue addWorker:w after:lastWorker];
		lastWorker = w;
	}
	
	enu = [runLater objectEnumerator];
	while(w = [enu nextObject])
	{
		[queue addWorker:w after:[runFirst lastObject]];
	}	
	
	[runFirst release];
	[runLater release];
}

-(void)dealloc
{
//	NSLog(@"File dealloc %@",self);
	[self setStatusImage:nil];
	[self removeOldFilePathOptimized:filePathOptimized];
	[filePathOptimized release]; filePathOptimized = nil;
	[filePath release]; filePath = nil;
	[displayName release]; displayName = nil;
	[lock release]; lock = nil;
	[serialQueue release]; serialQueue = nil;
	[super dealloc];
}

-(NSImage *)statusImage
{
	return statusImage;
}

-(void)setStatus:(NSString *)name
{
//	NSLog(@"status is now %@",name);
	NSImage *i;
	i = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForImageResource:name]];
	[self setStatusImage:i];
	[i release];
}

-(void)setStatusImage:(NSImage *)i
{
	if (i != statusImage)
	{
		[statusImage release];
		statusImage = [i retain];		
	}
}

-(NSString *)description
{
	NSString *s = [NSString stringWithFormat:@"%@ %d/%d", filePath,byteSize,byteSizeOptimized];
	return s;
}
@end