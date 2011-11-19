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
        strip = [defaults boolForKey:@"JpegTranStripAll"];
    }
    return self;
}

-(void)run
{
	NSString *temp = [self tempPath];

    // eh, handling of paths starting with "-" is unsafe here. Hopefully all paths from dropped files will be absolute...
	NSMutableArray *args = [NSMutableArray arrayWithObjects:[file filePath],temp,nil];
	
	if (strip) {
		[args insertObject:@"-s" atIndex:0];
 	}

    if (![self taskForKey:@"JpegTran" bundleName:@"jpegrescan" arguments:args]) {
        return;
    }
    
    [task setCurrentDirectoryPath:[[[NSBundle mainBundle] pathForAuxiliaryExecutable:@"jpegtran"] stringByDeletingLastPathComponent]];

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
