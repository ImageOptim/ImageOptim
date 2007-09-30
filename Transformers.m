//
//  CeilFormatter.m
//  ImageOptim
//
//  Created by porneL on 30.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Transformers.h"


@implementation CeilFormatter

+ (Class)transformedValueClass;
{
    return [NSNumber class];
}

- (id)transformedValue:(id)value;
{
	float v = 1.0;
	if ([value respondsToSelector: @selector(floatValue)]) 
	{
		v = MAX(1.0F,ceil([value floatValue]));
    }
	return [NSNumber numberWithFloat:v];
}
@end


@implementation DisabledColor

+ (Class)transformedValueClass;
{
    return [NSColor class];
}

- (id)transformedValue:(id)value;
{
	if ([value respondsToSelector: @selector(boolValue)] && ![value boolValue]) 
	{
		return [NSColor disabledControlTextColor];
    }
	return [NSColor textColor];
}
@end
