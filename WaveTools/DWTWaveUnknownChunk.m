//
//  DWTWaveUnknownChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/12/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveUnknownChunk.h"
#import "WaveToolsLocalization.h"


@implementation DWTWaveUnknownChunk

+ (NSUInteger) autoProcessSubchunkOffset
{
    return NSUIntegerMax;
}

- (NSString*) moreInfo
{
    return DWTLocalizedString(@"(no details available)", @"unknown chunk description");
}

@end
