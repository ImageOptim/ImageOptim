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

// wrapper for NSLocalizedString
#define _(localizedString) NSLocalizedString(localizedString, nil)


#if ! __has_feature(objc_arc)
#define IOWIAutorelease(__v) ([__v autorelease]);
#define IOWIReturnAutoreleased IOWIAutorelease

#define IOWIRetain(__v) ([__v retain]);
#define IOWIReturnRetained IOWIRetain

#define IOWIRelease(__v) ([__v release]);
#define IOWISafeRelease(__v) ([__v release], __v = nil);

#else
// -fobjc-arc
#define IOWIAutorelease(__v)
#define IOWIReturnAutoreleased(__v) (__v)

#define IOWIRetain(__v)
#define IOWIReturnRetained(__v) (__v)

#define IOWIRelease(__v)
#define IOWISafeRelease(__v) (__v = nil);

#endif


@interface Utilities : NSScriptCommand{
   NSNumber *queueCount;
}

+ (Utilities *)utilitiesSharedSingleton;

@property (nonatomic, strong)  NSNumber *queueCount;

@end
