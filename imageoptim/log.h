//
//  log.h
//  ImageOptim

extern int hideLogs;

#define IODebug(...) if (!hideLogs) NSLog(@"" __VA_ARGS__);
#define IOWarn(...) NSLog(@"" __VA_ARGS__);
