//
//  DirWorker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "DirWorker.h"
#import "FilesQueue.h"

@implementation DirWorker

-(id)initWithPath:(NSString *)aPath filesQueue:(FilesQueue *)q
{
	if (self = [super init])
	{
		path = [aPath copy];
		filesQueue = [q retain];
	}
	return self;
}

-(void)run
{
//	NSLog(@"Dirworker runs");
	NSDirectoryEnumerator *enu = [[NSFileManager defaultManager] enumeratorAtPath:path];
	NSString *filePath;
	NSArray *extensions = [NSArray arrayWithObjects:@"png",@"PNG",@"jpg",@"JPG",@"jpeg",@"JPEG",nil];
	BOOL added = NO;
    
	while(filePath = [enu nextObject])
	{
		NSString *newPath = [path stringByAppendingPathComponent:filePath];
//		NSLog(@"Foudn %@ = '%@'",newPath,[newPath pathExtension]);
		
		if (NSNotFound != [extensions indexOfObject:[newPath pathExtension]])
		{
			[filesQueue addFilePath:newPath dirs:NO];
            added = YES;
		}
	}
	
//	NSLog(@"DirWorker finished scan, triggers queue");
	if (added) [filesQueue runAdded];
//	NSLog(@"DirWorker finished completely");
}

-(void)dealloc
{
	[path release]; path = nil;
	[filesQueue release]; filesQueue = nil;
	[super dealloc];
}
@end
