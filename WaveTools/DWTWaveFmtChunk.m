//
//  DWTWaveFmtChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/12/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveFmtChunk.h"
#import "WaveToolsLocalization.h"
#import "NSData+WaveToolsExtensions.h"


#define kDWTWaveFmtChunkCompressionCodeOffset           0
#define kDWTWaveFmtChunkNumChannelsOffset               2
#define kDWTWaveFmtChunkSampleRateOffset                4
#define kDWTWaveFmtChunkAverageBytesPerSecondOffset     8
#define kDWTWaveFmtChunkBlockAlignOffset                12
#define kDWTWaveFmtChunkBitsPerSampleOffset             14
#define kDWTWaveFmtChunkExtraFormatBytesOffset          16
#define kDWTWaveFmtChunkMinimumSize                     16

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

// TODO: Separate all of these into getters/setters so that the setters can recalculate the data.
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

+ (NSData*) emptyChunkData
{
    static unsigned char s_emptyChunkBytes[] = {
        'f', 'm', 't', ' ', 18, 0, 0, 0,
        1, 0, // compression code 1
        2, 0, // 2 channels
        68, 172, 0, 0, // 44100
        0, 238, 2, 0, // average bytes per second (192k)
        4, 0, // 4 bytes per sample slice (block align)
        16, 0, // 16 bits per sample
        0, 0 // 0 extra format bytes
    };
    static NSData* s_emptyChunkData = nil;
    static dispatch_once_t s_emptyChunkOnce;
    dispatch_once(&s_emptyChunkOnce, ^{
        s_emptyChunkData = [[NSData alloc] initWithBytesNoCopy:&s_emptyChunkBytes[0] length:sizeof(s_emptyChunkBytes) freeWhenDone:NO];
    });
    return s_emptyChunkData;
}

+ (BOOL) canHandleChunkWithData:(NSData *)data
{
    return ([data length] >= (kDWTWaveChunkHeaderSize + kDWTWaveFmtChunkMinimumSize));
}

- (id) initWithData:(NSData*)data
{
    if ((self = [super initWithData:data])) {
        NSData* directData = [self directData];
        mCompressionCode       = [directData readUint16AtOffset:kDWTWaveFmtChunkCompressionCodeOffset];
        mNumChannels           = [directData readUint16AtOffset:kDWTWaveFmtChunkNumChannelsOffset];
        mSampleRate            = [directData readUint32AtOffset:kDWTWaveFmtChunkSampleRateOffset];
        mAverageBytesPerSecond = [directData readUint32AtOffset:kDWTWaveFmtChunkAverageBytesPerSecondOffset];
        mBlockAlign            = [directData readUint16AtOffset:kDWTWaveFmtChunkBlockAlignOffset];
        mBitsPerSample         = [directData readUint16AtOffset:kDWTWaveFmtChunkBitsPerSampleOffset];
        if ([directData length] >= (kDWTWaveFmtChunkExtraFormatBytesOffset + sizeof(uint16_t))) {
            mExtraFormatBytes      = [directData readUint16AtOffset:kDWTWaveFmtChunkExtraFormatBytesOffset];
        }
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
