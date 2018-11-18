//
//  JobProxy.h
//  ImageOptim
//
//  Created by Kornel on 17/11/2018.
//

@import Cocoa;

@class ResultsDb, File, TempFile, Job;

NS_ASSUME_NONNULL_BEGIN

@interface JobProxy : NSObject<NSCopying> {
    Job *job;
}

- (Job *)job;
- (BOOL)stop;
- (BOOL)revert;
- (File *)savedOutputOrInput;
- (nullable instancetype)initWithJob:(Job *)job;
- (id)copyWithZone:(nullable NSZone *)zone;

@property (readonly, nonatomic) BOOL canRevert, isDone, isFailed, isBusy, isStoppable, isOptimized;
@property (readonly, nonatomic) NSString *fileName;
@property (readonly, nonatomic) NSURL *filePath;
@property (readonly, nonatomic, nullable) NSString *statusText, *bestToolName;
@property (readonly, nonatomic) NSString *displayName;
@property (readonly, nonatomic) NSString *statusImageName;
@property (readonly, nonatomic) NSNumber *byteSizeOriginal;
@property (readonly, nonatomic) NSNumber *byteSizeOptimized;
@property (readonly, nonatomic) NSNumber *percentOptimized;

@end
NS_ASSUME_NONNULL_END
