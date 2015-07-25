
#import "GifsicleWorker.h"
#import "../File.h"

@implementation GifsicleWorker

- (instancetype)initWithInterlace:(BOOL)yn file:(File *)aFile {
    if ((self = [super initWithFile:aFile])) {
        interlace = yn;
    }
    return self;
}

-(NSInteger)settingsIdentifier {
    return interlace;
}

-(BOOL)runWithTempPath:(NSURL *)temp {
    NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-o",temp.path,
                            interlace ? @"--interlace" : @"--no-interlace",
                            @"-O3",
                            @"--careful",/* needed for Safari/Preview decoding bug */
                            @"--no-comments",@"--no-names",@"--same-delay",@"--same-loopcount",@"--no-warnings",
                            @"--",file.filePathOptimized.path,nil];

    if (![self taskForKey:@"Gifsicle" bundleName:@"gifsicle" arguments:args]) {
        return NO;
    }

    NSFileHandle *devnull = [NSFileHandle fileHandleWithNullDevice];

    [task setStandardInput: devnull];
    [task setStandardError: devnull];
    [task setStandardOutput: devnull];

    [self launchTask];
    [task waitUntilExit];

    [devnull closeFile];

    if ([task terminationStatus]) return NO;

    NSUInteger fileSizeOptimized = [File fileByteSize:temp];
    return [file setFilePathOptimized:temp size:fileSizeOptimized toolName:interlace ? @"Gifsicle interlaced" : @"Gifsicle"];
}

@end
