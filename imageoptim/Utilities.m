//
//  Utils.m
//  ImageOptim
//
//  Created by James on 24/5/13.
//
//

#import "Utilities.h"

@implementation Utilities

@synthesize queueCount;

+ (Utilities *)utilitiesSharedSingleton
{
    static Utilities *utilitiesSharedSingleton;
    
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        utilitiesSharedSingleton = [[self alloc] init];
    });
    
    return utilitiesSharedSingleton;
}

-(id)init{
    
    if( (self = [super init]) ) {
        self.queueCount = [NSNumber numberWithInt:0];
        return self;
    }
    else {
        return nil;
    }
}

- (void)observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context{
    
    if ( [keyPath isEqualToString:@"queueCount"] ) {
        
        if([change objectForKey:NSKeyValueChangeNewKey] != [NSNull null]){
            
            if([[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[change objectForKey:NSKeyValueChangeOldKey]] == NO){
                self.queueCount = [change objectForKey:NSKeyValueChangeNewKey];
                DLog2(@"q len now %@", self.queueCount);
            }
            else{
                DLog2(@"NO change");
            }
        }
        else{
            DLog2(@"NSKeyValueChangeNewKey == nsnull");
        }
    }
}

@end
