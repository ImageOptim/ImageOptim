//
//  Created by porneL on 7.wrz.07.
//

int quitWhenDone = 0;

#import "log.h"
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static int isLaunchedWithCliArguments(int argc, char *argv[]) {
    // Unfortunately NSApplicationLaunchIsDefaultLaunchKey doesn't cover bare CLI launch
    if (argc < 2) return 0;
    for (int i=0; i < argc; i++) {
        if ('-' == argv[i][0]) { // Normal OS X launch sets -psn
            return 0;
        }
    }
    return 1;
}

int main(int argc, char *argv[]) {
    quitWhenDone = hideLogs = isLaunchedWithCliArguments(argc, argv);

    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_10 && ![NSVisualEffectView class]) {
        Class NSVisualEffectViewClass = objc_allocateClassPair([NSView class], "NSVisualEffectView", 0);
        objc_registerClassPair(NSVisualEffectViewClass);
    }

    return NSApplicationMain(argc, (const char **) argv);
}
