//
//  DWTWaveFile.m
//  WaveTools
//
//  Created by Ben Cox on 7/26/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveFile.h"
#import "DWTAudioBuffer.h"
#import "DWTAudioFileRegion.h"
#import "DWTWaveChunk.h"
#import "DWTWaveFmtChunk.h"
#import "DWTWaveDataChunk.h"
#import "DWTWaveListAdtlChunk.h"
#import "DWTWaveCueChunk.h"
#import "DWTWaveLabelChunk.h"
#import "DWTWaveLabeledTextChunk.h"
#import "DWTWaveRegnChunk.h"
#import "WaveToolsLocalization.h"

#import <CoreFoundation/CoreFoundation.h>
#import <string.h>


#pragma mark Helper Functions

static inline int DWTBytesPerChannelSample(NSUInteger bitDepth)
{
    return ((((int)bitDepth) + 7) / 8);
}

static inline uint64_t DWTWaveDataSampleSourceGetSample(const void* firstByte, int numBytes)
{
    const unsigned char* byte = (const unsigned char *)firstByte;
    int shift = 8 * (8 - numBytes);
    uint64_t result = 0;
    for (int i = 0; i < numBytes; ++i) {
        result |= (((uint64_t)(*byte)) << shift);
        byte++;
        shift += 8;
    }
    return (int64_t)result;
}

static inline uint64_t DWTWaveDataSampleSourceGetByteSample(const unsigned char* pByte)
{
    return ((int64_t)((*pByte) - 128) << 56);
}

#pragma mark -

@interface DWTWaveDataSampleSource : NSObject <DWTAudioSampleSource>
{
    NSUInteger mNumBytesPerSample;
    NSUInteger mNumChannels;
    NSUInteger mChannelNumber;
    NSUInteger mBitDepth;
    DWTWaveDataChunk* mDataChunk;
}

- (NSUInteger) firstByteIndexForSample:(NSUInteger)sample;

- (id) initWithDataChunk:(DWTWaveDataChunk*)dataChunk
                 channel:(NSUInteger)channel
              ofChannels:(NSUInteger)numChannels
                bitDepth:(NSUInteger)bitDepth
          bytesPerSample:(NSUInteger)bytesPerSample;

@end

@implementation DWTWaveDataSampleSource

- (id) initWithDataChunk:(DWTWaveDataChunk*)dataChunk
                 channel:(NSUInteger)channel
              ofChannels:(NSUInteger)numChannels
                bitDepth:(NSUInteger)bitDepth
          bytesPerSample:(NSUInteger)bytesPerSample
{
    if ((self = [super init])) {
        NSUInteger expectedBytesPerSample = DWTBytesPerChannelSample(bitDepth) * numChannels;
        if (channel >= numChannels || bytesPerSample != expectedBytesPerSample) {
            [self release];
            self = nil;
        } else {
            mNumBytesPerSample = bytesPerSample;
            mNumChannels = numChannels;
            mChannelNumber = channel;
            mBitDepth = bitDepth;
            mDataChunk = [dataChunk retain];
        }
    }
    return self;
}

- (void) dealloc
{
    [mDataChunk release];
    mDataChunk = nil;
    [super dealloc];
}

- (NSUInteger) firstByteIndexForSample:(NSUInteger)sample
{
    NSUInteger intraSampleOffset = DWTBytesPerChannelSample(mBitDepth) * mChannelNumber;
    return (sample * mNumBytesPerSample) + intraSampleOffset;
}

#pragma mark DWTAudioSampleSource Methods

- (NSUInteger) sampleCount
{
    NSUInteger byteCount = [[mDataChunk directData] length];
    return byteCount / mNumBytesPerSample;
}

- (NSUInteger) bitDepth
{
    return mBitDepth;
}

- (int64_t) sampleAtIndex:(NSUInteger)index
{
    if (index >= [self sampleCount]) {
        NSException* exc = [NSException exceptionWithName:NSRangeException
                                                   reason:DWTLocalizedString(@"sample index out of range", @"sample index out of range message")
                                                 userInfo:[NSDictionary dictionary]];
        @throw exc;
    }
    int bytesPerChannelSample = DWTBytesPerChannelSample(mBitDepth);
    const void* base = [[mDataChunk directData] bytes];
    const void* firstByte = base + [self firstByteIndexForSample:index];
    if (bytesPerChannelSample == 1) {
        return DWTWaveDataSampleSourceGetByteSample(firstByte);
    } else {
        return DWTWaveDataSampleSourceGetSample(firstByte, bytesPerChannelSample);
    }
}

- (void) readSamples:(int64_t *)samples inRange:(NSRange)range
{
    NSUInteger maxRange = NSMaxRange(range);
    if (maxRange > [self sampleCount]) {
        NSException* exc = [NSException exceptionWithName:NSRangeException
                                                   reason:DWTLocalizedString(@"sample index out of range", @"sample index out of range message")
                                                 userInfo:[NSDictionary dictionary]];
        @throw exc;
    }
    int bytesPerChannelSample = DWTBytesPerChannelSample(mBitDepth);
    const void* base = [[mDataChunk directData] bytes];
    const void* currentByte = base + [self firstByteIndexForSample:range.location];
    if (bytesPerChannelSample == 1) {
        for (NSUInteger index = range.location; index < maxRange; ++index) {
            samples[index] = DWTWaveDataSampleSourceGetByteSample(currentByte);
            ++currentByte;
        }
    } else {
        for (NSUInteger index = range.location; index < maxRange; ++index) {
            samples[index] = DWTWaveDataSampleSourceGetSample(currentByte, bytesPerChannelSample);
            currentByte += mNumBytesPerSample;
        }
    }
}

@end

#pragma mark -

@interface DWTWaveFile ()
{
    DWTWaveChunk* mRiffChunk;
    DWTWaveFmtChunk* mFormatChunk; // Not separately retained; points to the one we find in the mRiffChunk.
    DWTWaveDataChunk* mDataChunk;  // Not separately retained (as above).
}
@end


@implementation DWTWaveFile

#pragma mark Properties

- (DWTWaveChunk*) riffChunk
{
    return mRiffChunk;
}

- (NSUInteger) sampleRate
{
    return (NSUInteger)mFormatChunk.sampleRate;
}

- (NSUInteger) bitDepth
{
    return (NSUInteger)mFormatChunk.bitsPerSample;
}

- (NSUInteger) numberOfChannels
{
    return (NSUInteger)mFormatChunk.numChannels;
}

- (NSUInteger) length
{
    return ([[mDataChunk directData] length] / (NSUInteger)mFormatChunk.blockAlign);
}

- (NSArray*) regions
{
    return [NSArray array]; // TODO: Find the regions.
}

#pragma mark Lifecycle

- (id) initWithData:(NSData*)data
{
    if ((self = [super init])) {
        mRiffChunk = [[DWTWaveChunk chunkForData:data] retain];
        if (mRiffChunk == nil || ![mRiffChunk.chunkID isEqualToString:@"RIFF"]) {
            [self release];
            self = nil;
        } else {
            for (DWTWaveChunk* chunk in mRiffChunk.subchunks) {
                if (mFormatChunk == nil && [chunk isKindOfClass:[DWTWaveFmtChunk class]]) {
                    mFormatChunk = (DWTWaveFmtChunk*)chunk;
                }
                if (mDataChunk == nil && [chunk isKindOfClass:[DWTWaveDataChunk class]]) {
                    mDataChunk = (DWTWaveDataChunk*)chunk;
                }
            }
            if (mFormatChunk == nil || mDataChunk == nil) {
                [self release];
                self = nil;
            }
        }
    }
    return self;
}

- (void) dealloc
{
    mDataChunk = nil;
    mFormatChunk = nil;
    [mRiffChunk release];
    mRiffChunk = nil;
    [super dealloc];
}

#pragma mark DWTAudioFile Methods

- (id<DWTAudioSampleSource>) sampleSourceForChannel:(NSUInteger)channel
{
    // TODO: We should verify that our mFormatChunk compression code is 1.
    return [[[DWTWaveDataSampleSource alloc] initWithDataChunk:mDataChunk
                                                       channel:channel
                                                    ofChannels:self.numberOfChannels
                                                      bitDepth:self.bitDepth
                                                bytesPerSample:(NSUInteger)mFormatChunk.blockAlign] autorelease];
}

@end
