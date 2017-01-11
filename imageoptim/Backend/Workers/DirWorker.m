//
//  DirWorker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "DirWorker.h"
#import "../FilesController.h"
#import "../log.h"

@implementation DirWorker


@synthesize path;

-(instancetype)initWithPath:(NSURL *)aPath filesController:(FilesController *)q extensions:(NSArray *)theExtensions {
    if (self = [super init]) {
        self.path = aPath;
        filesController = q;
        extensions = theExtensions;
    }
    return self;
}

-(void)main {
    const NSUInteger buffer_capacity = 256;
    NSUInteger buffer_size = 16;
    NSMutableArray *buffer = [NSMutableArray arrayWithCapacity:buffer_capacity];

    @try {
        for (NSURL *newPath in [[NSFileManager defaultManager] enumeratorAtURL:path
                                                        includingPropertiesForKeys:@[]
                                                                           options:0
                                                                      errorHandler:nil]) {
            if ([extensions containsObject:[newPath pathExtension]]) {
                [buffer addObject:newPath];
                if ([buffer count] >= buffer_size) {
                    // assuming that previous buffer flushes created some work to do
                    // buffer size can be increased to lower overhead
                    buffer_size = MIN(buffer_capacity, buffer_size*4);
                    [filesController addURLs:buffer filesOnly:YES];
                    [buffer removeAllObjects];
                }
            }
        }

        if ([buffer count]) [filesController addURLs:buffer filesOnly:YES];
    }
    @catch (NSException *ex) {
        IOWarn("DIR worker failed %@",ex);
    }
}

-(NSString *)description {
    return [NSString stringWithFormat:@"Dir %@ (%@)",path,[super description]];
}

@end
