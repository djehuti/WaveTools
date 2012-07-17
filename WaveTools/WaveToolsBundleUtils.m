//
//  WaveToolsBundleUtils.m
//  WaveTools
//
//  Created by Ben Cox on 7/17/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import "WaveToolsBundleUtils.h"


// This class exists only so that we can ask for the bundle where it lives.

@interface DWTWaveToolsBundleUtils : NSObject
@end

@implementation DWTWaveToolsBundleUtils
@end


NSBundle* DWTWaveToolsBundle(void)
{
    static NSBundle* s_waveToolsBundle = nil;
    static dispatch_once_t s_bundleOnce;
    dispatch_once(&s_bundleOnce, ^{
        s_waveToolsBundle = [[NSBundle bundleForClass:[DWTWaveToolsBundleUtils class]] retain];
    });
    return s_waveToolsBundle;
}
