
#import "SharedPrefs.h"

NSUserDefaults *IOSharedPrefs(void) {

    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10) {
        return nil;
    }

    return [[NSUserDefaults alloc] initWithSuiteName:@"59KZTZA4XR.net.pornel.ImageOptim"];
}


static void copyToDefs(const NSArray *__nonnull keys, const NSUserDefaults *__nonnull defs, NSUserDefaults *__nonnull shared) {

    for (NSString *key in keys) {
        id val = [defs objectForKey:key];
        if (val) {
            [shared setObject:val forKey:key];
        } else {
            [shared removeObjectForKey:key];
        }
    }
}

void IOSharedPrefsCopy(NSUserDefaults *__nonnull defs) {

    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10) {
        return;
    }

    // Whole dictionaryRepresentation is massive, so just copy interesting bits
    const NSArray *keys = @[
        @"AdvPngEnabled", @"AdvPngLevel", @"GifsicleEnabled",
        @"JpegOptimEnabled", @"JpegTranEnabled", @"JpegTranStripAll",
        @"OptiPngEnabled", @"OptiPngLevel",
        @"PngCrushEnabled", @"PngOutEnabled", @"PngOutLevel", @"PngOutRemoveChunks", @"ZopfliEnabled",
        @"PngMinQuality", @"JpegOptimMaxQuality",
    ];

    NSUserDefaults *shared = IOSharedPrefs();

    copyToDefs(keys, defs, shared);

    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification object:defs queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note){
        copyToDefs(keys, defs, shared);
    }];
}
