//
//  AdvCompWorker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "AdvCompWorker.h"
#import "File.h"

@implementation AdvCompWorker

-(void)run
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *temp = [self tempPath:@"AdvPng"];
	
	if (![fm copyPath:[file filePath] toPath:temp handler:nil])
	{
		NSLog(@"Can't make temp copy of %@ in %@",[file filePath],temp);
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
	int level = [defaults integerForKey:@"AdvPng.Level"];
	
	NSTask *task = [self taskForKey:@"AdvPng" bundleName:@"advpng" 
						  arguments:[NSArray arrayWithObjects: [NSString stringWithFormat:@"-%d",level ? level : 4],@"-z",@"--",temp,nil]];
    if (!task) {
        NSLog(@"Could not launch AdvPng");
        [file setStatus:@"err" text:@"AdvPng failed to start"];
    }
    
	
	NSPipe *commandPipe = [NSPipe pipe];
	NSFileHandle *commandHandle = [commandPipe fileHandleForReading];		
	
	[task setStandardOutput: commandPipe];	
	[task setStandardError: commandPipe];	
	
	[self launchTask:task];
	
	[self parseLinesFromHandle:commandHandle];
	
	[commandHandle readInBackgroundAndNotify];
	[task waitUntilExit];
    
	[commandHandle closeFile];	
    
	if (![task terminationStatus] && fileSizeOptimized)
	{
		[file setFilePathOptimized:temp	size:fileSizeOptimized];
	}
	//else NSLog(@"Advpng failed");
}

-(BOOL)parseLine:(NSString *)line
{
	NSScanner *scan = [NSScanner scannerWithString:line];
	
	int original,optimized;
	
	if ([scan scanInt:&original] && [scan scanInt:&optimized])
	{		
		fileSizeOptimized = optimized;
//		NSLog(@"advcomp returned %d vs %d",original,optimized);
		[file setByteSize:original];
		//[file setByteSizeOptimized:optimized];
		return YES;		
	}
//	NSLog(@"adv: Dunno what is %@",line);
	return NO;
}

@end
