//
//  AdvCompWorker.m
//
//  Created by porneL on 30.wrz.07.
//

#import "OptiPngWorker.h"
#import "../File.h"

@implementation OptiPngWorker

-(id)init {
    if (self = [super init]) {
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        optlevel = [defs integerForKey:@"OptiPngLevel"];
        interlace = [defs integerForKey:@"OptiPngInterlace"];

    }
    return self;
}


-(id)settingsIdentifier {
    return @(optlevel*2+interlace);
}

-(BOOL)runWithTempPath:(NSString *)temp {
    NSMutableArray *args = [NSMutableArray arrayWithObjects: [NSString stringWithFormat:@"-o%d",(int)(optlevel ? optlevel : 6)],
                            @"-out",temp,@"--",file.filePathOptimized,nil];

    if (interlace != -1) {
        [args insertObject:[NSString stringWithFormat:@"-i%d",(int)interlace] atIndex:0];
    }

    if (![self taskForKey:@"OptiPng" bundleName:@"optipng" arguments:args]) {
        return NO;
    }

    NSPipe *commandPipe = [NSPipe pipe];
    NSFileHandle *commandHandle = [commandPipe fileHandleForReading];

    [task setStandardError: commandPipe];
    [task setStandardOutput: commandPipe];

    [self launchTask];

    [self parseLinesFromHandle:commandHandle];

    [task waitUntilExit];
    [commandHandle closeFile];

    if ([task terminationStatus]) return NO;

    if (fileSizeOptimized) {
        return [file setFilePathOptimized:temp size:fileSizeOptimized toolName:@"OptiPNG"];
    }
    return NO;
}

-(BOOL)parseLine:(NSString *)line {
    NSUInteger res;

    if ([line length] > 20) {
        if ((res = [self readNumberAfter:@"Output file size = " inLine:line])) {
            fileSizeOptimized = res;
            return YES;
        }
    }
    return NO;
}

@end
