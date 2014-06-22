
#import <Foundation/Foundation.h>

@interface ResultsDb : NSObject {
}
-(BOOL)hasResultWithFileSize:(NSUInteger)size;
-(BOOL)getResultWithHash:(uint32_t[static 4])hash;
-(void)setUnoptimizableFileHash:(uint32_t[static 4])inputFileHash size:(NSUInteger)byteSizeOnDisk;
@end
