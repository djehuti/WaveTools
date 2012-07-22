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

@end
