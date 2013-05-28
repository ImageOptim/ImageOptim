//
//  Utils.h
//  ImageOptim
//
//  Created by James on 24/5/13.
//
//

#import <Foundation/Foundation.h>

#ifdef DEBUGX
#   define DLog2(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog2(...)
#endif


@interface Utilities : NSScriptCommand{
   // NSNumber *queueCount;
}

+ (Utilities *)utilitiesSharedSingleton;

@property (nonatomic, strong)  NSNumber *queueCount;

@end
