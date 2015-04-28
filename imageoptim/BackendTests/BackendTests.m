//
//  BackendTests.m
//  BackendTests
//
//  Created by Kornel on 20/04/2015.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "File.h"
#import "FilesQueue.h"

@interface BackendTests : XCTestCase

@end

@implementation BackendTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
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

    File *f = [[File alloc] initWithFilePath:path resultsDatabase:nil];
    FilesQueue *q = [FilesQueue new];

    [q addFile:f];
    XCTAssertTrue([f isBusy]);
    [q wait];

    NSNumber *size, *origSize;
    XCTAssertTrue([path getResourceValue:&size forKey:NSURLFileSizeKey error:nil]);
    XCTAssertTrue([origPath getResourceValue:&origPath forKey:NSURLFileSizeKey error:nil]);

    XCTAssertLessThan([origSize integerValue], [size integerValue]);
    XCTAssertLessThanOrEqual(5552, [size integerValue]);
}

@end
