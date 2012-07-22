//
//  DWTWaveRegnChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/22/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveRegnChunk.h"
#import "WaveToolsLocalization.h"


@implementation DWTWaveRegnChunk

+ (NSString*) defaultChunkID
{
    return @"regn";
}

+ (NSUInteger) autoProcessSubchunkOffset
{
    return NSUIntegerMax;
}

- (NSString*) moreInfo
{
    return DWTLocalizedString(@"Pro Tools proprietary region chunk", @"regn chunk description");
}

@end
