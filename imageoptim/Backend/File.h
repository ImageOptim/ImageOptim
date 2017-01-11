//
//  File.h
//  ImageOptim
//
//  Created by Kornel on 11/01/2017.
//
//

#import <Foundation/Foundation.h>

enum IOFileType {
    FILETYPE_PNG=1,
    FILETYPE_JPEG,
    FILETYPE_GIF
};

NS_ASSUME_NONNULL_BEGIN
@interface File : NSObject {
    @public
    enum IOFileType fileType;
}

-(nullable instancetype)initWithData:(NSData *)fileData fromPath:(NSURL *)path;

-(nullable File*)copyOfPath:(NSURL *)path;
-(nullable File*)copyOfPath:(NSURL *)path size:(NSUInteger)s;

-(BOOL)isLarge;
-(BOOL)isSmall;

@property (readonly) NSURL *path;
@property (readonly, assign) NSUInteger byteSize;
@property (readonly, nonatomic, nullable) NSString *mimeType;

+(NSInteger)byteSize:(NSURL *)afile;

@end
NS_ASSUME_NONNULL_END
