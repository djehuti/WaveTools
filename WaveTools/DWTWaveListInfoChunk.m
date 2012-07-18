//
//  DWTWaveListInfoChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/17/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveListInfoChunk.h"


@implementation DWTWaveListInfoChunk

+ (NSUInteger) autoProcessSubchunkOffset
{
    // The first bit is INFO and then subchunks.
    return 4;
}

- (NSString*) moreInfo
{
    return @"";
}

@end
