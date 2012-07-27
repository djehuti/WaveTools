//
//  DWTAudioFile.h
//  WaveTools
//
//  Created by Ben Cox on 7/26/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import <Foundation/Foundation.h>


@class DWTAudioFileRegion;
@protocol DWTAudioSampleSource;
@class DWTAudioBuffer;


@protocol DWTAudioFile <NSObject>

@property (nonatomic, readonly, assign) NSUInteger sampleRate;
@property (nonatomic, readonly, assign) NSUInteger bitDepth;
@property (nonatomic, readonly, assign) NSUInteger numberOfChannels;
@property (nonatomic, readonly, assign) NSUInteger length; // in samples
// This is an array of DWTAudioFileRegions.
@property (nonatomic, readonly, copy) NSArray* regions;

- (id<DWTAudioSampleSource>) sampleSourceForChannel:(NSUInteger)channel;

- (id) initWithData:(NSData*)data;

@end
