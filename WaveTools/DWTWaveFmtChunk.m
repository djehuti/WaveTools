//
//  DWTWaveFmtChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/12/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveFmtChunk.h"
#import "WaveToolsLocalization.h"


#define kDWTWaveFmtChunkCompressionCodeOffset           8
#define kDWTWaveFmtChunkNumChannelsOffset               10
#define kDWTWaveFmtChunkSampleRateOffset                12
#define kDWTWaveFmtChunkAverageBytesPerSecondOffset     16
#define kDWTWaveFmtChunkBlockAlignOffset                20
#define kDWTWaveFmtChunkBitsPerSampleOffset             22
#define kDWTWaveFmtChunkExtraFormatBytesOffset          24

@interface DWTWaveFmtChunk ()
{
    uint16_t mCompressionCode;
    uint16_t mNumChannels;
    uint32_t mSampleRate;
    uint32_t mAverageBytesPerSecond;
    uint16_t mBlockAlign;
    uint16_t mBitsPerSample;
    uint16_t mExtraFormatBytes;
}
@end


@implementation DWTWaveFmtChunk

@synthesize compressionCode = mCompressionCode;
@synthesize numChannels = mNumChannels;
@synthesize sampleRate = mSampleRate;
@synthesize averageBytesPerSecond = mAverageBytesPerSecond;
@synthesize blockAlign = mBlockAlign;
@synthesize bitsPerSample = mBitsPerSample;
@synthesize extraFormatBytes = mExtraFormatBytes;

- (NSString*) compressionDescription
{
    static NSDictionary* s_compressionCodeDescriptions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_compressionCodeDescriptions = [[NSDictionary alloc] initWithObjectsAndKeys:
                                         DWTLocalizedString(@"Unspecified", @"Unspecified audio codec"), [NSNumber numberWithInt:0],
                                         DWTLocalizedString(@"Linear PCM", @"PCM audio codec"), [NSNumber numberWithInt:1],
                                         DWTLocalizedString(@"Microsoft ADPCM", @"ADPCM audio codec"), [NSNumber numberWithInt:2],
                                         DWTLocalizedString(@"a-law", @"a-law audio codec"), [NSNumber numberWithInt:6],
                                         DWTLocalizedString(@"u-law", @"u-law audio codec"), [NSNumber numberWithInt:7],
                                         DWTLocalizedString(@"IMA ADPCM", @"IMA audio codec"), [NSNumber numberWithInt:17],
                                         DWTLocalizedString(@"Yamaha ADPCM", @"Yamaha ADPCM codec"), [NSNumber numberWithInt:20],
                                         DWTLocalizedString(@"GSM 6.10", @"GSM 6.10 audio codec"), [NSNumber numberWithInt:49],
                                         DWTLocalizedString(@"ITU G.721 ADPCM", @"ITU G.721 ADPCM audio codec"), [NSNumber numberWithInt:64],
                                         DWTLocalizedString(@"MPEG", @"MPEG audio codec"), [NSNumber numberWithInt:80],
                                         DWTLocalizedString(@"Experimental", @"Experimental audio codec"), [NSNumber numberWithInt:0xffff],
                                         nil];
    });
    NSString* description = [s_compressionCodeDescriptions objectForKey:[NSNumber numberWithInt:(int)self.compressionCode]];
    if (description == nil) {
        description = DWTLocalizedString(@"Unknown", @"Unknown audio codec");
    }
    return description;
}

- (id) initWithData:(NSData*)data
{
    if ((self = [super initWithData:data])) {
        Class c = [self class];
        mCompressionCode       = [c readUint16FromData:data atOffset:kDWTWaveFmtChunkCompressionCodeOffset];
        mNumChannels           = [c readUint16FromData:data atOffset:kDWTWaveFmtChunkNumChannelsOffset];
        mSampleRate            = [c readUint32FromData:data atOffset:kDWTWaveFmtChunkSampleRateOffset];
        mAverageBytesPerSecond = [c readUint32FromData:data atOffset:kDWTWaveFmtChunkAverageBytesPerSecondOffset];
        mBlockAlign            = [c readUint16FromData:data atOffset:kDWTWaveFmtChunkBlockAlignOffset];
        mBitsPerSample         = [c readUint16FromData:data atOffset:kDWTWaveFmtChunkBitsPerSampleOffset];
        mExtraFormatBytes      = [c readUint16FromData:data atOffset:kDWTWaveFmtChunkExtraFormatBytesOffset];
    }
    return self;
}

+ (NSUInteger) autoProcessSubchunkOffset
{
    return NSUIntegerMax;
}

- (NSString*) moreInfo
{
    NSString* formatString = DWTLocalizedString(@"%1$u channels, %2$u bits, sample rate %3$u, data rate %4$u, codec %5$@",
                                                @"fmt chunk summary description format specifier");
    return [NSString localizedStringWithFormat:formatString,
            (unsigned int) mNumChannels, (unsigned int) mBitsPerSample,
            (unsigned int) mSampleRate, (unsigned int) mAverageBytesPerSecond,
            [self compressionDescription]];
}

@end
