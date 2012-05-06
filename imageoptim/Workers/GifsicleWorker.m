
#import "GifsicleWorker.h"
#import "../File.h"

@implementation GifsicleWorker

@synthesize interlace;

-(void)run
{	
	NSString *temp = [self tempPath];
	//
	NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-o",temp,
                            interlace ? @"--interlace" : @"--no-interlace",
                            @"-O3",
                            @"--careful",/* needed for Safari/Preview decoding bug */
                            @"--no-comments",@"--no-names",@"--same-delay",@"--same-loopcount",@"--no-warnings",
                            @"--",[file filePath],nil];

	if (![self taskForKey:@"Gifsicle" bundleName:@"gifsicle" arguments:args]) {
        return;        
    }
	
	NSFileHandle *devnull = [NSFileHandle fileHandleWithNullDevice];
    
	[task setStandardInput: devnull];	
	[task setStandardError: devnull];	
	[task setStandardOutput: devnull];			
	
	[self launchTask];
	[task waitUntilExit];
    
	[devnull closeFile];	
	
    if ([self isCancelled]) return;

    NSUInteger fileSizeOptimized = [File fileByteSize:temp];
    NSInteger termstatus = [task terminationStatus];
	if (!termstatus && fileSizeOptimized)
	{
		[file setFilePathOptimized:temp size:fileSizeOptimized toolName:interlace ? @"Gifsicle interlaced" : @"Gifsicle"];	
	}
}

@end
