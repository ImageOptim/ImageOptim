//
//  DirWorker.m
//  ImageOptim
//
//  Created by porneL on 30.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "DirWorker.h"


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

-(void)dealloc
{
	[path release];
	[filesQueue release];
	[super dealloc];
}
@end
