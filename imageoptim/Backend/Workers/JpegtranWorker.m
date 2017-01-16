//
//  JpegtranWorker.m
//
//  Created by porneL on 7.paź.07.
//

#import "JpegtranWorker.h"
#import "../Job.h"
#import "../TempFile.h"

@implementation JpegtranWorker

- (NSInteger)settingsIdentifier {
    return strip;
}

- (instancetype)initWithDefaults:(NSUserDefaults *)defaults file:(Job *)aFile {
    if (self = [super initWithFile:aFile]) {
        strip = [defaults boolForKey:@"JpegTranStripAll"];
    }
    return self;
}

- (BOOL)optimizeFile:(File *)file toTempPath:(NSURL *)temp {
    // eh, handling of paths starting with "-" is unsafe here. Hopefully all paths from dropped files will be absolute...
    NSMutableArray *args = [NSMutableArray arrayWithObject:file.path];

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

    [task setStandardOutput:commandPipe];
    [task setStandardError:commandPipe];

    [self launchTask];

    [commandHandle readToEndOfFileInBackgroundAndNotify];
    BOOL ok = [self waitUntilTaskExit];

    [commandHandle closeFile];

    if (!ok) return NO;

    return [job setFileOptimized:[file tempCopyOfPath:temp] toolName:@"MozJPEG"];
}

- (BOOL)parseLine:(NSString *)line {
    NSRange substr = [line rangeOfString:@"End Of Image"];
    if (substr.length) {
        return YES;
    }
    return NO;
}


@end
