//
//  DWTWaveDataChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/17/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveDataChunk.h"
#import "WaveToolsLocalization.h"


@implementation DWTWaveDataChunk

+ (NSString*) defaultChunkID
{
    return @"data";
}

+ (NSUInteger) autoProcessSubchunkOffset
{
    return NSUIntegerMax;
}

- (NSString*) moreInfo
{
    return DWTLocalizedString(@"Audio Data Chunk", @"Audio data chunk description");
}

@end
