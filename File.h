//
//  File.h
//  ImageOptim
//
//  Created by porneL on 8.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface File : NSObject <NSCopying> {
	NSString *filePath;
	long byteSize;
	long byteSizeOptimized;	
	float percentDone;
}

-(id)initWithFilePath:(NSString *)name;
-(id)copyWithZone:(NSZone *)zone;
-(void)setByteSize:(long)size;
-(void)setByteSizeOptimized:(long)size;
-(BOOL)isOptimized;

-(void)setFilePath:(NSString *)s;

-(NSString *)fileName;
-(NSString *)filePath;
-(long)byteSize;
-(long)byteSizeOptimized;
-(float)percentDone;
-(void)setPercentDone:(float)d;
@end
