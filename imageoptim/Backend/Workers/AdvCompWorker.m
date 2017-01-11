//
//  AdvCompWorker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "AdvCompWorker.h"
#import "../Job.h"
#import "../../log.h"

@implementation AdvCompWorker

-(instancetype)initWithLevel:(NSInteger)aLevel file:(Job *)aFile {
    if (self = [super initWithFile:aFile]) {
        level = MAX(1, MIN(4, aLevel));
    }
    return self;
}

-(NSInteger)settingsIdentifier {
    return level;
}

-(BOOL)runWithTempPath:(NSURL *)temp {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;

    if (![fm copyItemAtURL:file.filePathOptimized toURL:temp error:&error]) {
        IOWarn("Can't make temp copy of %@ in %@; %@",file.filePathOptimized.path,temp.path,error);
        return NO;
    }

    NSMutableArray* args = [NSMutableArray arrayWithObjects:
                            [NSString stringWithFormat:@"-%d",(int)(level ? level : 4)],
                            @"-z", @"--", temp.path, nil];

    if (![self taskForKey:@"AdvPng" bundleName:@"advpng" arguments:args]) {
        return NO;
    }

    NSPipe *commandPipe = [NSPipe pipe];
    NSFileHandle *commandHandle = [commandPipe fileHandleForReading];

    [task setStandardOutput: commandPipe];
    [task setStandardError: commandPipe];

    [self launchTask];

    [self parseLinesFromHandle:commandHandle];
    BOOL ok = [self waitUntilTaskExit];

    [commandHandle closeFile];

    if (!ok) return NO;

    return [file setFilePathOptimized:temp  size:fileSizeOptimized toolName:@"AdvPNG"];
}

-(BOOL)parseLine:(NSString *)line {
    NSScanner *scan = [NSScanner scannerWithString:line];

    int original,optimized;

    if ([scan scanInt:&original] && [scan scanInt:&optimized]) {
        fileSizeOptimized = optimized;
        return YES;
    }
    return NO;
}

@end
