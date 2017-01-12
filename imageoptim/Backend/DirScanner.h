//
//
//  Created by porneL on 30.wrz.07.
//

#import <Cocoa/Cocoa.h>

@class FilesController;

@interface DirScanner : NSOperation {
	FilesController *filesController;
	NSURL *path;
    NSArray *extensions;
}

-(instancetype)initWithPath:(NSURL *)path filesController:(FilesController *)q extensions:(NSArray*)e;

@property (copy) NSURL *path;
@end
