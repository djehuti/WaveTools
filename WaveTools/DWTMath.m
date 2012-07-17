//
//  DWTMath.m
//  WaveTools
//
//  Created by Ben Cox on 7/17/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#define EXCLUDE_DWTMATH_INLINE_DEFINITIONS
#import "DWTMath.h"
#import "WaveToolsLocalization.h"


// Computes the GCD of x and y, using Euclid's algorithm.
// Throws an exception if x or y is 0.
uint64_t DWTGCD(uint64_t x, uint64_t y)
{
    if (x == 0 || y == 0) {
        NSException* exc = [NSException exceptionWithName:NSInvalidArgumentException
                                                   reason:DWTLocalizedString(@"An argument to DWTGCD was 0.", @"An argument to DWTGCD was 0.")
                                                 userInfo:[NSDictionary dictionary]];
        @throw exc;
    }
    unsigned long a = MAX(x, y);
    unsigned long b = MIN(x, y);
    while (a > b && b != 0) {
        a = a - b;
        if (b > a) {
            unsigned long tmp = a;
            a = b;
            b = tmp;
        }
    }
    return a;
}

// Computes the LCM of x and y. Returns 0 if x or y is 0.
uint64_t DWTLCM(uint64_t x, uint64_t y)
{
    uint64_t lcm = 0;
    if (x != 0 && y != 0) {
        // Divide by the GCD first (we know the result will be integral)
        // before multiplying, in order to avoid any potential overflow.
        lcm = (x / DWTGCD(x, y)) * y;
    }
    return lcm;
}

// Returns sinc(x); that is, sin(pi*x)/(pi*x), where sinc(0)===1.
double DWTSinc(double x)
{
    double sinc = 1.0;
    if (x != 0.0) {
        double pix = M_PI * x;
        return sin(pix) / pix;
    }
    return sinc;
}
