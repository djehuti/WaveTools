//
//  WaveNSDataTests.m
//  WaveTools
//
//  Created by Ben Cox on 7/22/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "WaveNSDataTests.h"
#import <WaveTools/WaveTools.h>


@implementation WaveNSDataTests

- (void) setUp
{
    [super setUp];
    // Set-up code here.
}

- (void) tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void) testString
{
    NSString* testString = @"The quick brown fox jumps over the lazy dog.";
    NSMutableData* data = [NSMutableData dataWithCapacity:50];
    [data writeNulTerminatedString:testString atOffset:0];
    NSString* roundtripString = [data readNulTerminatedStringAtOffset:0];
    STAssertTrue([testString isEqualToString:roundtripString], @"expected equal strings");
}

- (void) testIntegerStuff
{
    static unsigned char s_bytes[] = {
        1,
        2, 0,
        3, 0, 0, 0,
        4, 0, 0, 0, 0, 0, 0, 0
    };

    NSData* testData = [[NSData alloc] initWithBytesNoCopy:&s_bytes[0] length:sizeof(s_bytes) freeWhenDone:NO];
    uint8_t one = [testData readUint8AtOffset:0];
    uint16_t two = [testData readUint16AtOffset:1];
    uint32_t three = [testData readUint32AtOffset:3];
    uint64_t four = [testData readUint64AtOffset:7];

    STAssertEquals((uint64_t)one, 1UL, @"expected 1, got %lu", (unsigned long)one);
    STAssertEquals((uint64_t)two, 2UL, @"expected 2, got %lu", (unsigned long)two);
    STAssertEquals((uint64_t)three, 3UL, @"expected 3, got %lu", (unsigned long)three);
    STAssertEquals((uint64_t)four, 4UL, @"expected 4, got %lu", (unsigned long)four);

    NSMutableData* writeData = [[NSMutableData alloc] initWithCapacity:15];
    [writeData writeUint8:1 atOffset:0];
    [writeData writeUint16:2 atOffset:1];
    [writeData writeUint32:3 atOffset:3];
    [writeData writeUint64:4UL atOffset:7];

    STAssertEquals(15UL, [writeData length], @"expected 15 bytes, got %lu", (unsigned long)[writeData length]);
    int result = memcmp(&s_bytes[0], [writeData bytes], 15);
    STAssertEquals(0, result, @"expected bytes to compare equal");

    [writeData release];
    [testData release];
}

@end
