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
#define kDWTWaveFmtChunkExtraFormatBytesLengthOffset    16
#define kDWTWaveFmtChunkExtraFormatBytesOffset          18
#define kDWTWaveFmtChunkMinimumSize                     16


@interface DWTWaveFmtChunk ()
{
    uint16_t mCompressionCode;
    uint16_t mNumChannels;
    uint32_t mSampleRate;
    uint32_t mAverageBytesPerSecond;
    uint16_t mBlockAlign;
    uint16_t mBitsPerSample;
    NSData* mExtraFormatBytes;
}

- (void) p_fixupData;

@end


@implementation DWTWaveFmtChunk

- (uint16_t) compressionCode
{
    return mCompressionCode;
}

- (void) setCompressionCode:(uint16_t)compressionCode
{
    if (compressionCode != mCompressionCode) {
        mCompressionCode = compressionCode;
        [self p_fixupData];
    }
}

- (uint16_t) numChannels
{
    return mNumChannels;
}

- (void) setNumChannels:(uint16_t)numChannels
{
    if (numChannels != mNumChannels) {
        mNumChannels = numChannels;
        [self p_fixupData];
    }
}

- (uint32_t) sampleRate
{
    return mSampleRate;
}

- (void) setSampleRate:(uint32_t)sampleRate
{
    if (sampleRate != mSampleRate) {
        mSampleRate = sampleRate;
        [self p_fixupData];
    }
}

- (uint32_t) averageBytesPerSecond
{
    return mAverageBytesPerSecond;
}

- (void) setAverageBytesPerSecond:(uint32_t)averageBytesPerSecond
{
    if (averageBytesPerSecond != mAverageBytesPerSecond) {
        mAverageBytesPerSecond = averageBytesPerSecond;
        [self p_fixupData];
    }
}

- (uint16_t) blockAlign
{
    return mBlockAlign;
}

- (void) setBlockAlign:(uint16_t)blockAlign
{
    if (blockAlign != mBlockAlign) {
        mBlockAlign = blockAlign;
        [self p_fixupData];
    }
}

- (uint16_t) bitsPerSample
{
    return mBitsPerSample;
}

- (void) setBitsPerSample:(uint16_t)bitsPerSample
{
    if (bitsPerSample != mBitsPerSample) {
        mBitsPerSample = bitsPerSample;
        [self p_fixupData];
    }
}

- (NSData*) extraFormatBytes
{
    return mExtraFormatBytes;
}

- (void) setExtraFormatBytes:(NSData*)extraFormatBytes
{
    if (extraFormatBytes != mExtraFormatBytes) {
        if ([extraFormatBytes length] > UINT16_MAX) {
            NSException* exc = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:DWTLocalizedString(@"Extra format data cannot exceed 65535 bytes.", @"Extra format bytes length too long message")
                                                     userInfo:[NSDictionary dictionary]];
            @throw exc;
        }
        [mExtraFormatBytes release];
        mExtraFormatBytes = [extraFormatBytes retain];
        [self p_fixupData];
    }
}

// TODO: Separate all of these into getters/setters so that the setters can recalculate the data.
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
        'f', 'm', 't', ' ', 16, 0, 0, 0,
        1, 0, // compression code 1
        2, 0, // 2 channels
        68, 172, 0, 0, // 44100
        0, 238, 2, 0, // average bytes per second (192k)
        4, 0, // 4 bytes per sample slice (block align)
        16, 0, // 16 bits per sample
               // extra format bytes not present
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
    BOOL ok = NO;
    NSUInteger dataLength = [data length];

    if (dataLength >= (kDWTWaveChunkHeaderSize + kDWTWaveFmtChunkMinimumSize)) {
        if (dataLength == (kDWTWaveChunkHeaderSize + kDWTWaveFmtChunkMinimumSize)) {
            // No extra format bytes.
            ok = YES;
        } else {
            // There are extra format bytes. Better be at least long enough for the length field.
            if (dataLength >= (kDWTWaveChunkHeaderSize + kDWTWaveFmtChunkExtraFormatBytesLengthOffset + sizeof(uint16_t))) {
                // It's long enough for the length field. Get the length.
                NSUInteger extraFormatLength = [data readUint16AtOffset:kDWTWaveChunkHeaderSize + kDWTWaveFmtChunkExtraFormatBytesLengthOffset];
                // Better be at least long enough for that many bytes.
                ok = (dataLength >= (kDWTWaveChunkHeaderSize + kDWTWaveFmtChunkExtraFormatBytesOffset + extraFormatLength));
            }
        }
    }

    return ok;
}

- (id) initWithData:(NSData*)data
{
    if ((self = [super initWithData:data])) {
        NSData* directData = self.directData;
        mCompressionCode       = [directData readUint16AtOffset:kDWTWaveFmtChunkCompressionCodeOffset];
        mNumChannels           = [directData readUint16AtOffset:kDWTWaveFmtChunkNumChannelsOffset];
        mSampleRate            = [directData readUint32AtOffset:kDWTWaveFmtChunkSampleRateOffset];
        mAverageBytesPerSecond = [directData readUint32AtOffset:kDWTWaveFmtChunkAverageBytesPerSecondOffset];
        mBlockAlign            = [directData readUint16AtOffset:kDWTWaveFmtChunkBlockAlignOffset];
        mBitsPerSample         = [directData readUint16AtOffset:kDWTWaveFmtChunkBitsPerSampleOffset];
        if ([directData length] >= (kDWTWaveFmtChunkExtraFormatBytesLengthOffset + sizeof(uint16_t))) {
            NSUInteger extraFormatLength = (NSUInteger)[directData readUint16AtOffset:kDWTWaveFmtChunkExtraFormatBytesLengthOffset];
            if ([directData length] < (kDWTWaveFmtChunkExtraFormatBytesOffset + extraFormatLength)) {
                [self release];
                self = nil;
            } else {
                NSRange extraFormatRange = NSMakeRange(kDWTWaveFmtChunkExtraFormatBytesOffset, extraFormatLength);
                mExtraFormatBytes = [[directData subdataWithRange:extraFormatRange] retain];
            }
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

#pragma mark - Private Methods

- (void) p_fixupData
{
    NSUInteger dataLength = kDWTWaveFmtChunkMinimumSize;
    if (mExtraFormatBytes) {
        dataLength += 2 + [mExtraFormatBytes length];
    }
    NSMutableData* newData = [NSMutableData dataWithCapacity:dataLength];
    [newData writeUint16:mCompressionCode atOffset:kDWTWaveFmtChunkCompressionCodeOffset];
    [newData writeUint16:mNumChannels atOffset:kDWTWaveFmtChunkNumChannelsOffset];
    [newData writeUint32:mSampleRate atOffset:kDWTWaveFmtChunkSampleRateOffset];
    [newData writeUint32:mAverageBytesPerSecond atOffset:kDWTWaveFmtChunkAverageBytesPerSecondOffset];
    [newData writeUint16:mBlockAlign atOffset:kDWTWaveFmtChunkBlockAlignOffset];
    [newData writeUint16:mBitsPerSample atOffset:kDWTWaveFmtChunkBitsPerSampleOffset];
    if (mExtraFormatBytes) {
        [newData writeUint16:(uint16_t)[mExtraFormatBytes length] atOffset:kDWTWaveFmtChunkExtraFormatBytesLengthOffset];
        [newData appendData:mExtraFormatBytes];
    }
    self.directData = newData;
}

@end
