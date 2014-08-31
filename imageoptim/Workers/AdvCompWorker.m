//
//  AdvCompWorker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "AdvCompWorker.h"
#import "../File.h"
#import "../log.h"

@implementation AdvCompWorker

-(instancetype)init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        level = [defaults integerForKey:@"AdvPngLevel"];

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
  
    if (![self sandBoxedTaskForKey:@"AdvPng" bundleName:@"advpng" arguments:args]) {
        return NO;
    }

    NSPipe *commandPipe = [NSPipe pipe];
    NSFileHandle *commandHandle = [commandPipe fileHandleForReading];

    [task setStandardOutput: commandPipe];
    [task setStandardError: commandPipe];

    [self launchTask];

    [self parseLinesFromHandle:commandHandle];
    [task waitUntilExit];

    [commandHandle closeFile];

    if ([task terminationStatus]) return NO;

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
