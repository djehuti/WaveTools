//
//  DWTWaveLabeledTextChunk.h
//  WaveTools
//
//  Created by Ben Cox on 7/22/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import <WaveTools/WaveTools.h>


extern NSString* const kDWTWaveLabeledTextRegionPurposeID; // @"rgn "


@interface DWTWaveLabeledTextChunk : DWTWaveChunk

@property (nonatomic, readwrite, assign) uint32_t cuePointID;
@property (nonatomic, readwrite, assign) uint32_t length;
@property (nonatomic, readwrite, retain) NSString* purposeID; // kDWTWaveLabeledTextRegionPurposeID for regions.
@property (nonatomic, readwrite, assign) uint16_t country;
@property (nonatomic, readwrite, assign) uint16_t language;
@property (nonatomic, readwrite, assign) uint16_t dialect;
@property (nonatomic, readwrite, assign) uint16_t codePage;
@property (nonatomic, readwrite, retain) NSString* stringValue;

@end
