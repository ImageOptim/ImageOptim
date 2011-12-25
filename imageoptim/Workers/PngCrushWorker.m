//
//  PngCrushWorker.m
//
//  Created by porneL on 1.paź.07.
//

#import "PngCrushWorker.h"


@implementation PngCrushWorker

-(void)run
{
	NSString *temp = [self tempPath];

	NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-reduce",@"-brute",@"-cc",@"--",[file filePath],temp,nil];
	
    // Reusing PngOut config here
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PngOutRemoveChunks"]) {
        [args insertObject:@"-rem" atIndex:0];
        [args insertObject:@"alla" atIndex:1];
    }
	
    if (![self taskForKey:@"PngCrush" bundleName:@"pngcrush" arguments:args]) {
        return;
    }
    
	NSPipe *commandPipe = [NSPipe pipe];
	NSFileHandle *commandHandle = [commandPipe fileHandleForReading];		
	
	[task setStandardOutput: commandPipe];	
	[task setStandardError: commandPipe];	
	
	[self launchTask];
	
    [commandHandle readToEndOfFileInBackgroundAndNotify];
	
	[task waitUntilExit];	
	
	[commandHandle closeFile];
	
    if ([self isCancelled]) return;

	if (![task terminationStatus])
	{
		NSUInteger fileSizeOptimized;
		if ((fileSizeOptimized = [File fileByteSize:temp]))
		{
			[file setFilePathOptimized:temp	size:fileSizeOptimized toolName:[self className]];			
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
