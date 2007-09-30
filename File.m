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
	}
	return self;	
}

-(NSString *)fileName
{
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
	[s retain];
	[filePath release];
	filePath = s;
}

-(long)byteSize
{
	return byteSize;
}

-(long)byteSizeOptimized
{
	return byteSizeOptimized;
}

-(void)dealloc
{
	NSLog(@"Dealloc %@",self);	
	[filePath release];
	[super dealloc];
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
	byteSize = size;
	if (!byteSizeOptimized || byteSizeOptimized > byteSize) byteSizeOptimized = size;
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
	[self setPercentOptimized:1.0];
	byteSizeOptimized = size;
}

-(NSString *)description
{
	NSString *s = [NSString stringWithFormat:@"%@ %d/%d", filePath,byteSize,byteSizeOptimized];
	return s;
}
@end