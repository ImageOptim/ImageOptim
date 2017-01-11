//
//  Worker.m
//
//  Created by porneL on 23.wrz.07.
//

#import "CommandWorker.h"
#include <unistd.h>
#import "../Job.h"
#import "../log.h"

@implementation CommandWorker {
}

-(BOOL)parseLine:(NSString *)line {
    /* stub */
    return NO;
}


-(void)parseLinesFromHandle:(NSFileHandle *)commandHandle {
    NSData *temp;
    char inputBuffer[4096];
    NSInteger inputBufferPos=0;
    while ((temp = [commandHandle availableData]) && [temp length]) {
        const char *tempBytes = [temp bytes];
        NSInteger bytesPos=0, bytesLength = [temp length];

        while (bytesPos < bytesLength) {
            if (tempBytes[bytesPos] == '\n' || tempBytes[bytesPos] == '\r' || inputBufferPos == sizeof(inputBuffer)-1) {
                inputBuffer[inputBufferPos] = '\0';
                if ([self parseLine:@(inputBuffer)]) {
                    [commandHandle readDataToEndOfFile];
                    return;
                }
                inputBufferPos=0;
                bytesPos++;
            } else {
                inputBuffer[inputBufferPos++] = tempBytes[bytesPos++];
            }
        }
    }
}

-(void)taskWithPath:(NSString *)path arguments:(NSArray *)arguments;
{
    task = [NSTask new];

    if ([task respondsToSelector:@selector(setQualityOfService:)]) {
        task.qualityOfService = NSQualityOfServiceUtility;
    }

    IODebug("Launching %@ %@",path,[arguments componentsJoinedByString:@" "]);

    [task setLaunchPath: path];
    [task setArguments: arguments];

    // clone the current environment
    NSMutableDictionary *
    environment =[NSMutableDictionary dictionaryWithDictionary: [[NSProcessInfo processInfo] environment]];

    // set up for unbuffered I/O
    environment[@"NSUnbufferedIO"] = @"YES";

    [task setEnvironment:environment];
}

-(void)run {
    NSURL *tempPath = [self tempPath];
    @try {
        if ([self runWithTempPath:tempPath] && ![self isCancelled]) {
            tempPath = nil;
        }
    }
    @catch(NSException *e) {
        IOWarn(@"%@ failed: %@: %@", [self className], [e name], e);
        [file setError:[NSString stringWithFormat:@"Internal Error: %@ %@", [e name], [e reason]]];
    }
    @finally {
        if (tempPath) {
            [[NSFileManager defaultManager] removeItemAtURL:tempPath error:nil];
        }
    }
}

-(void)launchTask {
    @try {
        BOOL supportsQoS = [task respondsToSelector:@selector(setQualityOfService:)];

        if (supportsQoS) {
            task.qualityOfService = self.qualityOfService;
        }
        [task launch];

        int pid = [task processIdentifier];
        if (pid > 1) setpriority(PRIO_PROCESS, pid, PRIO_MAX/2); // PRIO_MAX is minimum priority. POSIX is intuitive.
    }
    @catch (NSException *e) {
        IOWarn("Failed to launch %@ - %@",[self className],e);
    }
}

-(BOOL)waitUntilTaskExit {
    [task waitUntilExit];
    int status = [task terminationStatus];
    if (status) {
        NSLog(@"Task %@ failed with status %d", [self className], status);
        return NO;
    }
    return YES;
}

-(long)readNumberAfter:(NSString *)str inLine:(NSString *)line {
    NSRange substr = [line rangeOfString:str];

    if (substr.length && [line length] > substr.location + [str length]) {
        NSScanner *scan = [NSScanner scannerWithString:line];
        [scan setScanLocation:substr.location + [str length]];

        int res;
        if ([scan scanInt:&res]) {
            return res;
        }
    }
    return 0;
}

-(void)cancel {
    @try {
        [task terminate];
    } @catch(NSException *e) {
        /* ignore */
    }
    [super cancel];
}


-(BOOL)taskForKey:(NSString *)key bundleName:(NSString *)resourceName arguments:(NSArray *)args {
    NSString *executable = [self executablePathForKey:key bundleName:resourceName];
    if (!executable) {
        IOWarn("Cannot launch %@",resourceName);
        [file setError:[NSString stringWithFormat:NSLocalizedString(@"%@ failed to start",@"tooltip"),key]];
        return NO;
    }
    [self taskWithPath:executable arguments:args];
    return YES;
}

-(NSString *)pathForExecutableName:(NSString *)resourceName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSString *path = [bundle pathForAuxiliaryExecutable:resourceName];
    if (!path) {
        path = [bundle pathForResource:resourceName ofType:@""];
    }

    if (path) {
        if (![[NSFileManager defaultManager] isExecutableFileAtPath:path]) {
            IOWarn("File %@ for %@ is not executable", path, resourceName);
            return nil;
        }
    }
    return path;
}

-(NSString *)executablePathForKey:(NSString *)prefsName bundleName:(NSString *)resourceName {
    NSString *path = [self pathForExecutableName:resourceName];

    if (!path) {
        IOWarn("Can't find working executable for %@ - disabling",prefsName);
        NSBeep();
    }
    return path;
}

-(NSURL *)tempPath {
    static int uid=0;
    if (uid==0) uid = getpid()<<12;
    NSString *filename = [NSString stringWithFormat:@"ImageOptim.%@.%x.%x.temp",[self className],(unsigned int)([Job hash]^[self hash]),uid++];
    return [NSURL fileURLWithPath: [NSTemporaryDirectory() stringByAppendingPathComponent: filename]];
}

-(BOOL)runWithTempPath:(NSURL *)tempPath {
    return NO; /*abstract*/
}

-(NSInteger)timelimitForLevel:(NSInteger)level {
    const NSInteger timelimit = 10 + [file byteSizeOriginal]/1024;
    const NSInteger maxTime = 8 + level*13;
    return MIN(maxTime, timelimit);
}

@end
