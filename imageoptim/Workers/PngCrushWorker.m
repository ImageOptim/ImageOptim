//
//  PngCrushWorker.m
//
//  Created by porneL on 1.paź.07.
//

#import "PngCrushWorker.h"


@implementation PngCrushWorker
- (id)init {
    if ((self = [super init])) {
        strip = [[NSUserDefaults standardUserDefaults] boolForKey:@"PngOutRemoveChunks"];
    }
    return self;
}

-(BOOL)runWithTempPath:(NSString*)temp
{
	NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-nofilecheck",@"-bail",@"-blacken",@"-reduce",@"-cc",@"--",[file filePath],temp,nil];
	
    // Reusing PngOut config here
    if (strip) {
        [args insertObject:@"-rem" atIndex:0];
        [args insertObject:@"alla" atIndex:1];
    }

    if ([file isSmall]) {
        [args insertObject:@"-brute" atIndex:0];
    }
	
    if (![self taskForKey:@"PngCrush" bundleName:@"pngcrush" arguments:args]) {
        return NO;
    }
    
	NSPipe *commandPipe = [NSPipe pipe];
	NSFileHandle *commandHandle = [commandPipe fileHandleForReading];		
	
	[task setStandardOutput: commandPipe];	
	[task setStandardError: commandPipe];	
	
	[self launchTask];
	
    [commandHandle readToEndOfFileInBackgroundAndNotify];
	
	[task waitUntilExit];	
	
	[commandHandle closeFile];
	
	if ([task terminationStatus]) return NO;

    NSUInteger fileSizeOptimized;
    // pngcrush sometimes writes only PNG header (70 bytes)!
    if ((fileSizeOptimized = [File fileByteSize:temp]) && fileSizeOptimized > 70) {
        return [file setFilePathOptimized:temp	size:fileSizeOptimized toolName:[self className]];
    }
    return NO;
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
	return strip;
}

@end
