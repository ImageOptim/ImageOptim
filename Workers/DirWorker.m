//
//  DirWorker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "DirWorker.h"
#import "FilesQueue.h"

@implementation DirWorker

@synthesize filesQueue;
@synthesize path;

-(id)initWithPath:(NSString *)aPath filesQueue:(FilesQueue *)q
{
	if (self = [super init])
	{
		self.path = aPath;
		self.filesQueue = q;
	}
	return self;
}

-(void)run
{
    @try {
        
    // FIXME: take extensions from list of enabled tools?
	NSArray *extensions = [NSArray arrayWithObjects:@"png",@"PNG",@"jpg",@"JPG",@"jpeg",@"JPEG",nil];
    
	for(NSString *filePath in [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:nil])
	{
		NSString *newPath = [path stringByAppendingPathComponent:filePath];
		//NSLog(@"Foudn %@ = '%@'",newPath,[newPath pathExtension]);
		
		if (NSNotFound != [extensions indexOfObject:[newPath pathExtension]])
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
