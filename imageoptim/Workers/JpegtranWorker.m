//
//  JpegtranWorker.m
//
//  Created by porneL on 7.paź.07.
//

#import "JpegtranWorker.h"
#import "../File.h"

@implementation JpegtranWorker

-(NSInteger)settingsIdentifier {
    return strip;
}

-(instancetype)initWithDefaults:(NSUserDefaults *)defaults file:(File *)aFile {
    if (self = [super initWithDefaults:defaults file:aFile]) {
        strip = [defaults boolForKey:@"JpegTranStripAll"];
    }
    return self;
}

-(BOOL)runWithTempPath:(NSURL *)temp {
    // eh, handling of paths starting with "-" is unsafe here. Hopefully all paths from dropped files will be absolute...
    NSMutableArray *args = [NSMutableArray arrayWithObject:file.filePathOptimized.path];

    [args insertObject:@"-outfile" atIndex:0];
    [args insertObject:temp.path atIndex:1];

    [args insertObject:@"-optimize" atIndex:0];
    [args insertObject:@"-copy" atIndex:0];
    [args insertObject:strip ? @"none" : @"all" atIndex:1];

    if (![self taskForKey:@"JpegTran" bundleName:@"jpegtran" arguments:args]) {
        return NO;
    }

    NSString *jpegtranPath = [self pathForExecutableName:@"jpegtran"];
    if (!jpegtranPath) {
        return NO;
    }
    [task setCurrentDirectoryPath:[jpegtranPath stringByDeletingLastPathComponent]];

    NSPipe *commandPipe = [NSPipe pipe];
    NSFileHandle *commandHandle = [commandPipe fileHandleForReading];

    [task setStandardOutput: commandPipe];
    [task setStandardError: commandPipe];

    [self launchTask];

    [commandHandle readToEndOfFileInBackgroundAndNotify];
    [task waitUntilExit];

    [commandHandle closeFile];

    if ([task terminationStatus]) return NO;

    NSUInteger fileSizeOptimized = [File fileByteSize:temp];
    if (fileSizeOptimized) {
        return [file setFilePathOptimized:temp size:fileSizeOptimized toolName:@"MozJPEG"];
    }
    return NO;
}

-(BOOL)parseLine:(NSString *)line {
    NSRange substr = [line rangeOfString:@"End Of Image"];
    if (substr.length) {
        return YES;
    }
    return NO;
}


@end
