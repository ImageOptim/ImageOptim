//
//  DirWorker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "DirWorker.h"
#import "../FilesQueue.h"

@implementation DirWorker


@synthesize path;

-(id)initWithPath:(NSString *)aPath filesQueue:(FilesQueue *)q extensions:(NSArray*)theExtensions
{
	if (self = [super init])
	{
		self.path = aPath;
		filesQueue = q;
        extensions = theExtensions;
	}
	return self;
}

-(void)main
{
	const NSUInteger buffer_capacity = 256;
	NSUInteger buffer_size = 1;
	NSUInteger buffered = 0;
	NSMutableArray *buffer = [NSMutableArray arrayWithCapacity:buffer_capacity];
	
    @try 
	{
		for(NSString *filePath in [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:nil])
		{
			NSString *newPath = [path stringByAppendingPathComponent:filePath];
			
			if ([extensions containsObject:[newPath pathExtension]])
			{
				[buffer addObject:newPath]; buffered++;
				if (buffered >= buffer_size)
				{
					// assuming that previous buffer flushes created some work to do
					// buffer size can be increased to lower overhead
					buffer_size = MIN(buffer_capacity, buffer_size*2 + 4);
					[filesQueue addFilePaths:buffer];
					[buffer removeAllObjects]; buffered=0;
				}
			}
		}
		
		if ([buffer count]) [filesQueue addFilePaths:buffer];
		//NSLog(@"DirWorker finished completely");			
    }
    @catch (NSException *ex) {
        NSLog(@"DIR worker failed %@",ex);
    }
}

-(NSString *)description {
    return [NSString stringWithFormat:@"Dir %@ (%@)",path,[super description]];
}

@end
