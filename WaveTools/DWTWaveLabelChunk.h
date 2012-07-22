//
//  DWTWaveLabelChunk.h
//  WaveTools
//
//  Created by Ben Cox on 7/21/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import <WaveTools/WaveTools.h>


@interface DWTWaveLabelChunk : DWTWaveChunk

@property (nonatomic, readwrite, assign) uint32_t cuePointID;
@property (nonatomic, readwrite, retain) NSString* stringValue;

@end
