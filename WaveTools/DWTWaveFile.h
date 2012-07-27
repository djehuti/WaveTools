//
//  DWTWaveFile.h
//  WaveTools
//
//  Created by Ben Cox on 7/26/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <WaveTools/DWTAudioFile.h>


@class DWTWaveChunk;


@interface DWTWaveFile : NSObject <DWTAudioFile>

@property (nonatomic, readonly, retain) DWTWaveChunk* riffChunk;

@end
