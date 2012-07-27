//
//  DWTAudioBuffer.h
//  WaveTools
//
//  Created by Ben Cox on 7/26/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import <Foundation/Foundation.h>


@protocol DWTAudioSamples <NSObject>

@required

@property (nonatomic, readonly, assign) NSUInteger sampleCount;
@property (nonatomic, readonly, assign) NSUInteger bitDepth;

@end

#pragma mark - DWTAudioSampleSource

@protocol DWTAudioSampleSource <DWTAudioSamples>

@required

- (int64_t) sampleAtIndex:(NSUInteger)index;

@optional

- (void) readSamples:(int64_t*)samples inRange:(NSRange)range;

@end

#pragma mark - DWTAudioSampleSink

@protocol DWTAudioSampleSink <DWTAudioSamples>

@required

- (void) setSample:(int64_t)sample atIndex:(NSUInteger)index;

@optional

- (void) setSamples:(const int64_t*)samples inRange:(NSRange)range;

@end


#pragma mark -


@interface DWTAudioBuffer : NSObject

@property (nonatomic, readonly) NSRange sampleRange;
@property (nonatomic, readonly) NSUInteger sourceBitDepth;
@property (nonatomic, readonly) int64_t* mutableSamples;

- (int64_t) sampleAtIndex:(NSUInteger)index; // Must be within sampleRange.
- (void) setSample:(int64_t)sample atIndex:(NSUInteger)index;

- (id) initWithSource:(id<DWTAudioSampleSource>)source range:(NSRange)range;
- (void) flushToSink:(id<DWTAudioSampleSink>)sink;

@end
