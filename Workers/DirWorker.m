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

-(void)run
{
    @try {
            
	for(NSString *filePath in [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:nil])
	{
		NSString *newPath = [path stringByAppendingPathComponent:filePath];
		
		if ([extensions containsObject:[newPath pathExtension]])
		{
			[filesQueue addPath:newPath dirs:NO];
		}
	}
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
