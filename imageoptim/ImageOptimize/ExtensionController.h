//
//  ExtensionController.h
//  Optimize
//
//  Created by Kornel on 18/04/2015.
//
//

@import Cocoa;

@class Job, JobQueue;

@interface ExtensionController : NSViewController

@property (strong) Job *currentFile;
@property IBOutlet NSTextField *status;
@property (strong) JobQueue *jobQueue;
@end
