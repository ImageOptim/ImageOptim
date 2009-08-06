//
//  JpegoptimWorker.m
//
//  Created by porneL on 7.paź.07.
//

#import "JpegoptimWorker.h"
#import "File.h"

@implementation JpegoptimWorker

-(id)init {
    if (self = [super init])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        comments = [defaults boolForKey:@"JpegOptim.StripComments"];
        exif = [defaults boolForKey:@"JpegOptim.StripExif"];   
        maxquality = [defaults integerForKey:@"JpegOptim.MaxQuality"];
    }
    return self;
}

-(BOOL)makesNonOptimizingModifications {
    return maxquality < 100;
}

-(void)run
{
	NSFileManager *fm = [NSFileManager defaultManager];	
	NSString *temp = [self tempPath:@"JpegOptim"];
	
	if (![fm copyPath:[file filePath] toPath:temp handler:nil])
	{
		NSLog(@"Can't make temp copy of %@ in %@",[file filePath],temp);
	}

	NSMutableArray *args = [NSMutableArray arrayWithObjects: @"-q",@"--",temp,nil];
	

	if (exif && comments)
	{
		[args insertObject:@"--strip-all" atIndex:0];
	}
	else if (exif)
	{
		[args insertObject:@"--strip-exif" atIndex:0];
	}
	else if (comments)
	{
		[args insertObject:@"--strip-com" atIndex:0];
	}
	
	if (maxquality > 10 && maxquality < 100)
	{
		[args insertObject:[NSString stringWithFormat:@"-m%d",maxquality] atIndex:0];
	}
		
	NSTask *task = [self taskForKey:@"JpegOptim" bundleName:@"jpegoptim" arguments:args];
	
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
	
}

-(BOOL)parseLine:(NSString *)line
{
	int size;
	if (size = [self readNumberAfter:@" [OK] " inLine:line])
	{
		//NSLog(@"File size %d",size);
		[file setByteSize:size];
	}
	if (size = [self readNumberAfter:@" --> " inLine:line])
	{
		//NSLog(@"File size optimized %d",size);
		//[file setByteSizeOptimized:size];
		fileSizeOptimized = size;
		return YES;
	}
	return NO;
}


@end
