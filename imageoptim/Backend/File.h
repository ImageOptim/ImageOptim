//
//  File.h
//  ImageOptim
//
//  Created by Kornel on 11/01/2017.
//
//

#import <Foundation/Foundation.h>

@class TempFile;

enum IOFileType {
    FILETYPE_PNG = 1,
    FILETYPE_JPEG,
    FILETYPE_GIF,
    FILETYPE_SVG,
};

NS_ASSUME_NONNULL_BEGIN
@interface File : NSObject {
@public
    enum IOFileType fileType;
}

- (nullable instancetype)initWithData:(NSData *)fileData fromPath:(NSURL *)path;

// This is not copying, but only creates an instance poiting to the new place
// If size is given, it aviods disk accesss
- (nullable File *)copyOfPath:(NSURL *)path;
- (nullable File *)copyOfPath:(NSURL *)path size:(NSUInteger)s;
- (nullable TempFile *)tempCopyOfPath:(NSURL *)path;
- (nullable TempFile *)tempCopyOfPath:(NSURL *)path size:(NSUInteger)s;

- (BOOL)isLarge;
- (BOOL)isSmall;

@property (readonly) NSURL *path;
@property (readonly, assign) NSUInteger byteSize;
@property (readonly, nonatomic, nullable) NSString *mimeType;

+ (NSInteger)byteSize:(NSURL *)afile;

@end
NS_ASSUME_NONNULL_END
