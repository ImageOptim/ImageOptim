
#import "GifsicleWorker.h"
#import "../File.h"

@implementation GifsicleWorker

@synthesize interlace;

-(id)settingsIdentifier {
    return @(interlace);
}

-(BOOL)runWithTempPath:(NSString*)temp
{	
	NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-o",temp,
                            interlace ? @"--interlace" : @"--no-interlace",
                            @"-O3",
                            @"--careful",/* needed for Safari/Preview decoding bug */
                            @"--no-comments",@"--no-names",@"--same-delay",@"--same-loopcount",@"--no-warnings",
                            @"--",[file filePath],nil];

	if (![self taskForKey:@"Gifsicle" bundleName:@"gifsicle" arguments:args]) {
        return NO;
    }
	
	NSFileHandle *devnull = [NSFileHandle fileHandleWithNullDevice];
    
	[task setStandardInput: devnull];	
	[task setStandardError: devnull];	
	[task setStandardOutput: devnull];			
	
	[self launchTask];
	[task waitUntilExit];
    
	[devnull closeFile];	
	
	if ([task terminationStatus]) return NO;

    NSUInteger fileSizeOptimized = [File fileByteSize:temp];
    return [file setFilePathOptimized:temp size:fileSizeOptimized toolName:interlace ? @"Gifsicle interlaced" : @"Gifsicle"];
}

@end
