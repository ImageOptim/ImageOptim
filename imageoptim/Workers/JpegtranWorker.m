//
//  JpegtranWorker.m
//
//  Created by porneL on 7.paź.07.
//

#import "JpegtranWorker.h"
#import "../File.h"

@implementation JpegtranWorker

-(NSInteger)settingsIdentifier {
    return jpegrescan*2+strip;
}

-(instancetype)initWithFile:(File *)aFile {
    if (self = [super initWithFile:aFile]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        strip = [defaults boolForKey:@"JpegTranStripAll"];

        jpegrescan = [defaults boolForKey:@"JpegRescanEnabled"];
    }
    return self;
}

-(BOOL)runWithTempPath:(NSURL *)temp {
    // eh, handling of paths starting with "-" is unsafe here. Hopefully all paths from dropped files will be absolute...
    NSMutableArray *args = [NSMutableArray arrayWithObject:file.filePathOptimized.path];
    NSString *executableName, *prefName;

    if (jpegrescan) {
        executableName = @"jpegrescan";
        prefName = @"JpegRescan";
        if (strip) {
            [args insertObject:@"-s" atIndex:0];
        }
        [args addObject:temp.path];
    } else {
        executableName = @"jpegtran";
        prefName = @"JpegTran";
        [args insertObject:@"-outfile" atIndex:0];
        [args insertObject:temp.path atIndex:1];

        [args insertObject:@"-optimize" atIndex:0];
        [args insertObject:@"-copy" atIndex:0];
        [args insertObject:strip ? @"none" : @"all" atIndex:1];
    }

    // For jpegrescan to work both JpegTran and JpegRescan need to be enabled
    if (![self sandBoxedTaskForKey:prefName bundleName:executableName arguments:args]) {
        return NO;
    }

    [task setCurrentDirectoryPath:[[[NSBundle mainBundle] pathForAuxiliaryExecutable:@"jpegtran"] stringByDeletingLastPathComponent]];

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
        return [file setFilePathOptimized:temp size:fileSizeOptimized toolName:executableName];
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
