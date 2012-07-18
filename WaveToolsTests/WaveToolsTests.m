//
//  WaveToolsTests.m
//  WaveToolsTests
//
//  Created by Ben Cox on 7/17/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import "WaveToolsTests.h"
#import <WaveTools/WaveTools.h>


@implementation WaveToolsTests

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

- (void) testGcd
{
    const uint64_t x = 44100UL;
    const uint64_t y = 96000UL;
    const uint64_t true_gcd = 300UL;

    uint64_t gcd = DWTGCD(x, y);

    STAssertEquals(gcd, true_gcd, @"bad gcd %lu != %lu", gcd, true_gcd);
}

- (void) testGcd0
{
    STAssertThrows(DWTGCD(0UL, 1UL), @"Expected gcd(0,1) to throw");
    STAssertThrows(DWTGCD(1UL, 0UL), @"Expected gcd(0,1) to throw");
}

- (void) testLcm
{
    const uint64_t x = 44100UL;
    const uint64_t y = 96000UL;
    const uint64_t true_lcm = 14112000UL;

    uint64_t lcm = DWTLCM(x, y);

    STAssertEquals(lcm, true_lcm, @"bad lcm %lu != %lu", lcm, true_lcm);
}

- (void) testLcm0
{
    uint64_t lcm1 = DWTLCM(0UL, 1UL);
    uint64_t lcm2 = DWTLCM(1UL, 0UL);

    STAssertEquals(lcm1, 0UL, @"expected lcm(0,1)==0, got %lu", lcm1);
    STAssertEquals(lcm2, 0UL, @"expected lcm(1,0)==0, got %lu", lcm2);
}

- (void) testRandom
{
    uint64_t randAccum = 0;
    for (int i = 0; i < 1000; ++i) {
        randAccum |= DWTRandom();
    }
    // This test will randomly fail in rare cases (64 in 2^1000 times, I think).
    STAssertEquals(randAccum, UINT64_MAX, @"expected all bits to eventually show up; got 0x%16lx", randAccum);
}

- (void) testSinc
{
    const double test1x = 0.0;
    const double test2x = 0.5;
    const double test3x = 1.0;
    const double test4x = 1.5;
    const double test5x = 2.0;

    double test1y = DWTSinc(test1x);
    double test2y = DWTSinc(test2x);
    double test3y = DWTSinc(test3x);
    double test4y = DWTSinc(test4x);
    double test5y = DWTSinc(test5x);

    STAssertEquals(test1y, 1.0, @"sinc(%g) === 1, got %g", test1x, test1y);
    STAssertTrue(test2y > 0.0, @"sinc(%g) < 0, got %g", test2x, test2y);
    STAssertTrue(DWTMathAlmostEqual(test3y, 0.0, 1e-16), @"sinc(%g) == 0, got %g", test3x, test3y);
    STAssertTrue(test4y < 0.0, @"sinc(%g) > 0, got %g", test4x, test4y);
    STAssertTrue(DWTMathAlmostEqual(test5y, 0.0, 1e-16), @"sinc(%g) == 0, got %g", test5x, test5y);
}

@end
