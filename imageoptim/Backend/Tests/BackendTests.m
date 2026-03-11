//
//  BackendTests.m
//  BackendTests
//
//  Created by Kornel on 20/04/2015.
//
//

@import Cocoa;
#import <XCTest/XCTest.h>
#import "Job.h"
#import "JobQueue.h"

@interface BackendTests : XCTestCase

@end

@implementation BackendTests

- (void)setUp {
    [super setUp];
    // Register app defaults to ensure optimization tools are enabled
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *defaultsURL = [mainBundle URLForResource:@"defaults" withExtension:@"plist"];
    if (defaultsURL) {
        NSDictionary *defs = [NSDictionary dictionaryWithContentsOfURL:defaultsURL];
        if (defs) {
            [[NSUserDefaults standardUserDefaults] registerDefaults:defs];
        }
    }
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCompressOne {
    NSURL *origPath = [[NSBundle bundleForClass:[self class]] URLForResource:@"unoptimized" withExtension:@"png"];
    NSURL *path = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]];

    NSFileManager *fm = [NSFileManager defaultManager];
    XCTAssertTrue([fm copyItemAtURL:origPath toURL:path error:nil]);

    Job *f = [[Job alloc] initWithFilePath:path resultsDatabase:nil];
    JobQueue *q = [[JobQueue alloc] initWithCPUs:4
                                            dirs:1
                                           files:4
                                        defaults:[NSUserDefaults standardUserDefaults]];

    [q addJob:f];
    XCTAssertTrue([f isBusy]);
    XCTAssertFalse([f isDone]);
    XCTAssertFalse([f isFailed]);
    [q wait];
    XCTAssertFalse([f isBusy]);

    NSNumber *size, *origSize;
    [path removeAllCachedResourceValues];
    [origPath removeAllCachedResourceValues];

    XCTAssertTrue([path getResourceValue:&size forKey:NSURLFileSizeKey error:nil]);
    XCTAssertTrue([origPath getResourceValue:&origSize forKey:NSURLFileSizeKey error:nil]);

    XCTAssertTrue([f isDone]);
    XCTAssertFalse([f isFailed]);
    XCTAssertFalse([f isStoppable]);

    XCTAssertLessThan(1, 2);
    XCTAssertLessThan([size integerValue], [origSize integerValue]);
    XCTAssertLessThanOrEqual(1, 2);
    XCTAssertLessThanOrEqual([size integerValue], 5552);

    XCTAssertTrue([f canRevert]);

    XCTAssertEqual([[f byteSizeOptimized] integerValue], [size integerValue]);
    XCTAssertEqual([[f byteSizeOriginal] integerValue], [origSize integerValue]);
}

- (void)testCompressJPEG {
    NSURL *origPath = [[NSBundle bundleForClass:[self class]] URLForResource:@"unoptimized" withExtension:@"jpg"];
    if (!origPath) {
        XCTSkip(@"unoptimized.jpg test resource not found");
    }
    NSURL *path = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]];

    NSFileManager *fm = [NSFileManager defaultManager];
    XCTAssertTrue([fm copyItemAtURL:origPath toURL:path error:nil]);

    Job *f = [[Job alloc] initWithFilePath:path resultsDatabase:nil];
    JobQueue *q = [[JobQueue alloc] initWithCPUs:4 dirs:1 files:4 defaults:[NSUserDefaults standardUserDefaults]];

    [q addJob:f];
    [q wait];

    XCTAssertTrue([f isDone]);
    XCTAssertFalse([f isFailed]);
}

- (void)testCompressGIF {
    NSURL *origPath = [[NSBundle bundleForClass:[self class]] URLForResource:@"unoptimized" withExtension:@"gif"];
    if (!origPath) {
        XCTSkip(@"unoptimized.gif test resource not found");
    }
    NSURL *path = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]];

    NSFileManager *fm = [NSFileManager defaultManager];
    XCTAssertTrue([fm copyItemAtURL:origPath toURL:path error:nil]);

    Job *f = [[Job alloc] initWithFilePath:path resultsDatabase:nil];
    JobQueue *q = [[JobQueue alloc] initWithCPUs:4 dirs:1 files:4 defaults:[NSUserDefaults standardUserDefaults]];

    [q addJob:f];
    [q wait];

    XCTAssertTrue([f isDone]);
    XCTAssertFalse([f isFailed]);
}

- (void)testCompressSVG {
    NSURL *origPath = [[NSBundle bundleForClass:[self class]] URLForResource:@"unoptimized" withExtension:@"svg"];
    if (!origPath) {
        XCTSkip(@"unoptimized.svg test resource not found");
    }
    NSURL *path = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]];

    NSFileManager *fm = [NSFileManager defaultManager];
    XCTAssertTrue([fm copyItemAtURL:origPath toURL:path error:nil]);

    Job *f = [[Job alloc] initWithFilePath:path resultsDatabase:nil];
    JobQueue *q = [[JobQueue alloc] initWithCPUs:4 dirs:1 files:4 defaults:[NSUserDefaults standardUserDefaults]];

    [q addJob:f];
    [q wait];

    XCTAssertTrue([f isDone]);
    XCTAssertFalse([f isFailed]);
}

@end
