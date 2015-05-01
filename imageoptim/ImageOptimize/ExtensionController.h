//
//  ExtensionController.h
//  Optimize
//
//  Created by Kornel on 18/04/2015.
//
//

#import <Cocoa/Cocoa.h>

@class File, FilesQueue;

@interface ExtensionController : NSViewController

@property (strong) File *currentFile;
@property IBOutlet NSTextField *status;
@property (strong) FilesQueue *filesQueue;
@end
