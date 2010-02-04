//
//  JpegtranWorker.m
//
//  Created by porneL on 7.paź.07.
//

#import "JpegtranWorker.h"
#import "../File.h"

@implementation JpegtranWorker

-(id)init {
    if (self = [super init])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        strip = [defaults boolForKey:@"JpegTran.StripAll"];
    }
    return self;
}

-(void)run
{
	NSFileManager *fm = [NSFileManager defaultManager];	
	NSString *temp = [self tempPath];
    NSError *error = nil;
	
	if (![fm copyItemAtPath:[file filePath] toPath:temp error:&error])
	{
		NSLog(@"Can't make temp copy of %@ in %@; %@",[file filePath],temp, error);
	}

    // eh, handling of paths starting with "-" is unsafe here. Hopefully all paths from dropped files will be absolute...
	NSMutableArray *args = [NSMutableArray arrayWithObjects: @"-verbose",@"-optimize",@"-progressive",@"-outfile",temp,[file filePath],nil];
	
	if (strip)
	{
		[args insertObject:@"-copy" atIndex:0];
		[args insertObject:@"none" atIndex:1];
 	}
    else
    {
		[args insertObject:@"-copy" atIndex:0];
		[args insertObject:@"all" atIndex:1];        
    }
		
	NSTask *task = [self taskForKey:@"JpegTran" bundleName:@"jpegtran" arguments:args];
	
    
	NSPipe *commandPipe = [NSPipe pipe];
	NSFileHandle *commandHandle = [commandPipe fileHandleForReading];		
	
	[task setStandardOutput: commandPipe];	
	[task setStandardError: commandPipe];	
	
    NSLog(@"jpegtran ready to run");
	[self launchTask:task];
	
	[self parseLinesFromHandle:commandHandle];

	[commandHandle readInBackgroundAndNotify];
	[task waitUntilExit];

	[commandHandle closeFile];
	
	if (![task terminationStatus])
	{
        NSUInteger fileSizeOptimized;
		if (fileSizeOptimized = [File fileByteSize:temp])
		{
			[file setFilePathOptimized:temp	size:fileSizeOptimized toolName:[self className]];			
		}        
	}
	
}

-(BOOL)parseLine:(NSString *)line
{
    NSRange substr = [line rangeOfString:@"End Of Image"];
    if (substr.length)
    {
        return YES;			
    }
	return NO;
}


@end
