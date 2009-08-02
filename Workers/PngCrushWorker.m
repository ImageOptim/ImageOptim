//
//  PngCrushWorker.m
//
//  Created by porneL on 1.paź.07.
//

#import "PngCrushWorker.h"


@implementation PngCrushWorker

-(id)init {
    if (self = [super init])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        chunks = [defaults arrayForKey:@"PngCrush.Chunks"];
        tryfix = [defaults boolForKey:@"PngCrush.Fix"];
    }
    return self;
}

-(void)run
{
	NSString *temp = [self tempPath:@"PngCrush"];

	NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-brute",@"-cc",@"--",[file filePath],temp,nil];
	
	NSDictionary *dict;
	for(dict in chunks)
	{
		NSString *name = [dict objectForKey:@"name"];
		if (name)
		{
			[args insertObject:name atIndex:0];
			[args insertObject:@"-rem" atIndex:0];
		}
	}
	
	if (tryfix)
	{
		[args insertObject:@"-fix" atIndex:0];
	}

	NSTask *task = [self taskForKey:@"PngCrush" bundleName:@"pngcrush" arguments:args];
    if (!task) {
        NSLog(@"Could not launch PngCrush");
        [file setStatus:@"err" text:@"PngCrush failed to start"];
    }
    
	
	NSPipe *commandPipe = [NSPipe pipe];
	NSFileHandle *commandHandle = [commandPipe fileHandleForReading];		
	
	[task setStandardOutput: commandPipe];	
	[task setStandardError: commandPipe];	
	
	[self launchTask:task];
	
	//[self parseLinesFromHandle:commandHandle];
	
    [commandHandle readInBackgroundAndNotify];
	
	[task waitUntilExit];	
	
	[commandHandle closeFile];
	
	if (![task terminationStatus])
	{
		unsigned long fileSizeOptimized;
		if (fileSizeOptimized = [File fileByteSize:temp])
		{
			[file setFilePathOptimized:temp	size:fileSizeOptimized];			
		}
	}
	else NSLog(@"pngcrush failed");
}

//-(BOOL)parseLine:(NSString *)line
//{
//	int res;
//	//NSLog(@"PNGCrush: %@",line);
//	if ((res = [self readNumberAfter:@") =     " inLine:line]) || (res = [self readNumberAfter:@"IDAT chunks    =     " inLine:line]))
//	{	
//        // eh
//    }
//	else
//	{
//		NSRange substr = [line rangeOfString:@"Best pngcrush method"];
//		if (substr.length)
//		{
//			return YES;			
//		}
//	}
//	return NO;
//}


-(BOOL)makesNonOptimizingModifications
{
	return YES;
}

@end
