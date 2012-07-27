//
//  DWTAudioBuffer.m
//  WaveTools
//
//  Created by Ben Cox on 7/26/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "DWTAudioBuffer.h"
#import "WaveToolsLocalization.h"


@interface DWTAudioBuffer ()
{
    NSRange mSampleRange;
    NSUInteger mSourceBitDepth;
    int64_t* mSamples;
}
@end

@implementation DWTAudioBuffer

@synthesize sampleRange = mSampleRange;
@synthesize sourceBitDepth = mSourceBitDepth;
@synthesize mutableSamples = mSamples;

- (int64_t) sampleAtIndex:(NSUInteger)index
{
    if (index < mSampleRange.location || index >= NSMaxRange(mSampleRange)) {
        NSException* exc = [NSException exceptionWithName:NSRangeException
                                                   reason:DWTLocalizedString(@"sample index out of range", @"sample index out of range message")
                                                 userInfo:[NSDictionary dictionary]];
        @throw exc;
    }
    NSUInteger realIndex = index - mSampleRange.location;
    return mSamples[realIndex];
}

- (void) setSample:(int64_t)sample atIndex:(NSUInteger)index
{
    if (index < mSampleRange.location || index >= NSMaxRange(mSampleRange)) {
        NSException* exc = [NSException exceptionWithName:NSRangeException
                                                   reason:DWTLocalizedString(@"sample index out of range", @"sample index out of range message")
                                                 userInfo:[NSDictionary dictionary]];
        @throw exc;
    }
    NSUInteger realIndex = index - mSampleRange.location;
    mSamples[realIndex] = sample;
}

- (id) initWithSource:(id<DWTAudioSampleSource>)source range:(NSRange)range;
{
    NSUInteger maxRange = NSMaxRange(range);
    if ((self = [super init])) {
        if (source == nil) {
            [self release];
            self = nil;
        }
        else if ([source sampleCount] < maxRange) {
            [self release];
            self = nil;
        }
        else {
            mSampleRange = range;
            mSourceBitDepth = [source bitDepth];
            mSamples = (int64_t*)malloc(mSampleRange.length * sizeof(int64_t));
            if ([source respondsToSelector:@selector(readSamples:inRange:)]) {
                [source readSamples:mSamples inRange:mSampleRange];
            } else {
                for (NSUInteger sampleIndex = mSampleRange.location; sampleIndex < maxRange; ++sampleIndex) {
                    mSamples[sampleIndex] = [source sampleAtIndex:sampleIndex];
                }
            }
        }
    }
    return self;
}

- (void) flushToSink:(id<DWTAudioSampleSink>)sink
{
    NSUInteger maxRange = NSMaxRange(mSampleRange);
    if (sink == nil) {
        NSException* exc = [NSException exceptionWithName:NSInvalidArgumentException
                                                   reason:DWTLocalizedString(@"nil sink passed", @"nil sink exception")
                                                 userInfo:[NSDictionary dictionary]];
        @throw exc;
    }
    else if ([sink sampleCount] < maxRange) {
        NSException* exc = [NSException exceptionWithName:NSRangeException
                                                   reason:DWTLocalizedString(@"sink cannot accommodate samples", @"sink too small exception")
                                                 userInfo:[NSDictionary dictionary]];
        @throw exc;
    }
    if ([sink respondsToSelector:@selector(setSamples:inRange:)]) {
        [sink setSamples:mSamples inRange:mSampleRange];
    } else {
        for (NSUInteger sampleIndex = mSampleRange.location; sampleIndex < maxRange; ++sampleIndex) {
            [sink setSample:mSamples[sampleIndex] atIndex:sampleIndex];
        }
    }
}

- (void) dealloc
{
    free(mSamples);
    mSamples = NULL;
    [super dealloc];
}

@end
