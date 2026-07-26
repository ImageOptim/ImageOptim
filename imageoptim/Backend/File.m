//
//  File.m
//  ImageOptim
//
//  Created by Kornel on 11/01/2017.
//
//

#import "File.h"
#import "TempFile.h"
#import "../log.h"
#import <assert.h>

@implementation File

- (nullable instancetype)initWithType:(enum IOFileType)type size:(NSUInteger)size fromPath:(NSURL *)aPath {
    if (!size) {
        return nil;
    }

    if ((self = [super init])) {
        _path = aPath;
        _byteSize = size;
        fileType = type;
    }
    return self;
}

/// A WebP file is a RIFF container. Only a still, losslessly-compressed image
/// (a VP8L chunk) can be recompressed without losing quality: there is just one
/// WebP encoder, so re-encoding a lossy VP8 bitstream would degrade it, and an
/// animation (ANIM) can't be handled by cwebp at all. Both are rejected here.
///
/// A plain lossless file has VP8L right after the header, but a file with an
/// alpha channel, ICC profile or EXIF is wrapped in an extended (VP8X) header,
/// so the chunks have to be walked to find out.
static BOOL IsLosslessWebP(NSData *fileData) {
    const NSUInteger length = fileData.length;
    if (length < 12) {
        return NO;
    }

    unsigned char header[12];
    [fileData getBytes:header length:sizeof(header)];

    if (0 != memcmp(header, "RIFF", 4) || 0 != memcmp(header + 8, "WEBP", 4)) {
        return NO;
    }

    // Walk the chunk list. A plain lossless file has VP8L first; one with an
    // alpha channel, ICC profile or EXIF starts with an extended VP8X header
    // and VP8L follows further in. Chunks are an 8-byte header plus a payload
    // padded to an even length. The iteration cap bounds the work a malformed
    // file full of tiny chunks could cause.
    NSUInteger offset = 12;
    for (int i = 0; i < 64 && offset + 8 <= length; i++) {
        unsigned char chunk[8];
        [fileData getBytes:chunk range:NSMakeRange(offset, sizeof(chunk))];

        if (0 == memcmp(chunk, "VP8L", 4)) {
            return YES;
        }
        if (0 == memcmp(chunk, "VP8 ", 4) || 0 == memcmp(chunk, "ANIM", 4)) {
            return NO;
        }

        const uint32_t payload = (uint32_t)chunk[4] | ((uint32_t)chunk[5] << 8) |
                                 ((uint32_t)chunk[6] << 16) | ((uint32_t)chunk[7] << 24);
        const NSUInteger step = 8 + (NSUInteger)payload + (payload & 1);
        if (step <= 8 || step > length - offset) {
            return NO; // truncated or malformed
        }
        offset += step;
    }
    return NO;
}

-(instancetype)initWithData:(NSData *)fileData fromPath:(NSURL *)aPath {
    const unsigned char pngheader[] = {0x89,0x50,0x4e,0x47,0x0d,0x0a};
    const unsigned char jpegheader[] = {0xff,0xd8,0xff};
    const unsigned char gifheader[] = {0x47,0x49,0x46,0x38};
    const unsigned char svgheader[] = {'<','s','v','g'};
    char fileHeaderBytes[6];

    if (!fileData || fileData.length < sizeof(fileHeaderBytes)) {
        return nil;
    }

    [fileData getBytes:fileHeaderBytes length:sizeof(fileHeaderBytes)];

    enum IOFileType type = 0;

    if (0 == memcmp(fileHeaderBytes, pngheader, sizeof(pngheader))) {
        type = FILETYPE_PNG;
    } else if (0 == memcmp(fileHeaderBytes, jpegheader, sizeof(jpegheader))) {
        type = FILETYPE_JPEG;
    } else if (0 == memcmp(fileHeaderBytes, gifheader, sizeof(gifheader))) {
        type = FILETYPE_GIF;
    } else if (0 == memcmp(fileHeaderBytes, svgheader, sizeof(svgheader)) || [aPath.pathExtension isEqualToString:@"svg"]) {
        type = FILETYPE_SVG;
    } else if (IsLosslessWebP(fileData)) {
        type = FILETYPE_WEBP_LOSSLESS;
    }

    return [self initWithType:type size:fileData.length fromPath:aPath];
}

- (nullable File *)copyOfPath:(NSURL *)path {
    return [[File alloc] initWithType:fileType size:[File byteSize:path] fromPath:path];
}

- (nullable File *)copyOfPath:(NSURL *)path size:(NSUInteger)s {
    return [[File alloc] initWithType:fileType size:s fromPath:path];
}

- (nullable TempFile *)tempCopyOfPath:(NSURL *)path {
    return [[TempFile alloc] initWithType:fileType size:[File byteSize:path] fromPath:path];
}

- (nullable TempFile *)tempCopyOfPath:(NSURL *)path size:(NSUInteger)s {
    if (!s) {
        return nil;
    }

    if (s != [File byteSize:path]) {
        NSLog(@"Expected size %d, but file is actually %d", (int)s, (int)[File byteSize:path]);
        return nil;
    }
    return [[TempFile alloc] initWithType:fileType size:s fromPath:path];
}

- (BOOL)isLarge {
    if (fileType == FILETYPE_PNG) {
        return _byteSize > 250 * 1024;
    }
    return _byteSize > 1 * 1024 * 1024;
}

- (BOOL)isSmall {
    if (fileType == FILETYPE_PNG) {
        return _byteSize < 2048;
    }
    return _byteSize < 10 * 1024;
}

+ (NSInteger)byteSize:(NSURL *)afile {
    NSNumber *value = nil;
    NSError *err = nil;
    if ([afile getResourceValue:&value forKey:NSURLFileSizeKey error:&err] && value) {
        return [value integerValue];
    }
    IOWarn("Could not stat %@: %@", afile.path, err);
    return 0;
}

- (nullable NSString *)mimeType {
    switch (fileType) {
        case FILETYPE_PNG: return @"image/png";
        case FILETYPE_JPEG: return @"image/jpeg";
        case FILETYPE_GIF: return @"image/gif";
        case FILETYPE_SVG: return @"image/svg";
        case FILETYPE_WEBP_LOSSLESS: return @"image/webp";
        default:
            return nil;
    }
}

@end
