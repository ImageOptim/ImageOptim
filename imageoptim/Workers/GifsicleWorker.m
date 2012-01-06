//
//  AdvCompWorker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "GifsicleWorker.h"
#import "../File.h"

@implementation GifsicleWorker

@synthesize interlace;

//-(id)init {
//    if (self = [super init])
//    {
//        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
//        optlevel = [defs integerForKey:@"OptiPngLevel"];
//        interlace = [defs integerForKey:@"OptiPngInterlace"];
//
//    }
//    return self;
//}

-(void)run
{	
	NSString *temp = [self tempPath];
	//
	NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-o",temp,
                            interlace ? @"--interlace" : @"--no-interlace",
                            @"-O3",@"--no-comments",@"--no-names",@"--same-delay",@"--same-loopcount",@"--no-warnings",
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
