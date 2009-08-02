//
//  AdvCompWorker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "OptiPngWorker.h"
#import "File.h"

@implementation OptiPngWorker

-(id)init {
    if (self = [super init])
    {
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        optlevel = [defs integerForKey:@"OptiPng.Level"];
        interlace = [defs integerForKey:@"OptiPng.Interlace"];

    }
    return self;
}

-(void)run
{	
	NSString *temp = [self tempPath:@"OptiPng"];
	
	NSMutableArray *args = [NSMutableArray arrayWithObjects: [NSString stringWithFormat:@"-o%d",optlevel ? optlevel : 6],
							@"-out",temp,@"--",[file filePath],nil];

	if (interlace != -1)
	{
		[args insertObject:[NSString stringWithFormat:@"-i%d",interlace] atIndex:0];
	}	
	
	NSTask *task = [self taskForKey:@"OptiPng" bundleName:@"optipng" arguments:args];
	if (!task) {
        NSLog(@"Could not launch OptiPng");
        [file setStatus:@"err" text:@"OptiPNG failed to start"];
    }
	
	NSPipe *commandPipe = [NSPipe pipe];
	NSFileHandle *commandHandle = [commandPipe fileHandleForReading];		
	
	[task setStandardError: commandPipe];	
	[task setStandardOutput: commandPipe];			
	
	[self launchTask:task];
	
	[self parseLinesFromHandle:commandHandle];
	
    [commandHandle readInBackgroundAndNotify];
	
	[task waitUntilExit];
	[commandHandle closeFile];	
	
	if (![task terminationStatus] && fileSizeOptimized)
	{
		[file setFilePathOptimized:temp size:fileSizeOptimized];	
	}
	//else NSLog(@"Optipng failed to optimize anything");
}

-(BOOL)parseLine:(NSString *)line
{
	//NSLog(@"### %@",line);
		
	unsigned long res;
	
	if ([line length] > 20)
	{
		// idat sizes are totally broken in latest optipng
		/*if (res = [self readNumberAfter:@"Input IDAT size = " inLine:line])
		{
			idatSize = res;
			NSLog(@"OptiPng input idat %d",res);
		}
		else if (res = [self readNumberAfter:@"IDAT size = " inLine:line])
		{		
			//[file setByteSizeOptimized: fileSize - idatSize + res];
			NSLog(@"Idat %d guesstimate %d",res,fileSize - idatSize + res);
		}
		else*/
		if (res = [self readNumberAfter:@"Input file size = " inLine:line])
		{
			fileSize = res;
			[file setByteSize:fileSize];
			//NSLog(@"OptiPng input file %d",res);
		}
		else if (res = [self readNumberAfter:@"Output file size = " inLine:line])
		{
			fileSizeOptimized = res;
			//[file setByteSizeOptimized:fileSizeOptimized];
			//NSLog(@"OptiPng output %d",res);

			return YES;
		}			
	}
	return NO;
}

@end
