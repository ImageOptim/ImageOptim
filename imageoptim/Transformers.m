//
//  CeilFormatter.m
//
//  Created by porneL on 30.wrz.07.
//

#import "Transformers.h"


@implementation CeilFormatter

+ (Class)transformedValueClass {
    return [NSNumber class];
}

- (id)transformedValue:(id)value {
    double v = 1.0;
    if ([value respondsToSelector: @selector(doubleValue)]) {
        v = MAX(1.0F,ceil([value doubleValue]));
    }
    return @(v);
}
@end


@implementation DisabledColor

+ (Class)transformedValueClass {
    return [NSColor class];
}

- (id)transformedValue:(id)value {
    if ([value respondsToSelector: @selector(boolValue)] && ![value boolValue]) {
        return [NSColor disabledControlTextColor];
    }
    return [NSColor textColor];
}
@end


static NSMutableDictionary *imageCache;

@implementation IOStatusImage

+ (Class)transformedValueClass {
    return [NSImage class];
}

- (id)transformedValue:(id)value {
    if (!value) {
        value = @"err";
    }
    if (!imageCache) {
        imageCache = [NSMutableDictionary new];
    }
    NSImage *img = imageCache[value];
    if (!img) {
        imageCache[value] = img = [NSImage imageNamed:value];
    }
    return img;
}
@end
