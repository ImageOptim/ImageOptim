//
//  AdvCompWorker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "AdvCompWorker.h"
#import "../File.h"
#import "../log.h"

@implementation AdvCompWorker

-(id)init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        level = [defaults integerForKey:@"AdvPngLevel"];

    }
    return self;
}

-(id)settingsIdentifier {
    return @(level);
}

-(BOOL)runWithTempPath:(NSString *)temp {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;

    if (![fm copyItemAtPath:[file filePath] toPath:temp error:&error]) {
        IOWarn("Can't make temp copy of %@ in %@; %@",[file filePath],temp,error);
        return NO;
    }

    if (![self taskForKey:@"AdvPng" bundleName:@"advpng"
            arguments:[NSArray arrayWithObjects: [NSString stringWithFormat:@"-%d",(int)(level ? level : 4)],@"-z",@"--",temp,nil]]) {
        return NO;
    }

    NSPipe *commandPipe = [NSPipe pipe];
    NSFileHandle *commandHandle = [commandPipe fileHandleForReading];

    [task setStandardOutput: commandPipe];
    [task setStandardError: commandPipe];

    [self launchTask];

    [self parseLinesFromHandle:commandHandle];

    [commandHandle readInBackgroundAndNotify];
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
