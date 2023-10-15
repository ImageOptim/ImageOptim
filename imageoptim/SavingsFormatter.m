//
//  SavingsFormatter.m
//  ImageOptim
//
//

#import "SavingsFormatter.h"

@implementation SavingsFormatter

- (NSString *)stringForObjectValue:(id)anObject {
    double val = [anObject doubleValue];

    if (val < 0) return @"";
    if (val < 1.0 / 1024.0) {
        return @"0%";
    }
    return [super stringForObjectValue:anObject];
}

@end
