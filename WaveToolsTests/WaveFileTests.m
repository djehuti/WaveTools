//
//  WaveFileTests.m
//  WaveTools
//
//  Created by Ben Cox on 7/26/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "WaveFileTests.h"
#import <WaveTools/WaveTools.h>


@interface WaveFileTests ()
{
    NSString* mPathToMinimal16Wav;
    NSString* mPathToMinimal24Wav;
}

@end


@implementation WaveFileTests

- (void) setUp
{
    [super setUp];
    mPathToMinimal16Wav = [[[NSBundle bundleForClass:[self class]] pathForResource:@"minimal16" ofType:@"wav"] retain];
    mPathToMinimal24Wav = [[[NSBundle bundleForClass:[self class]] pathForResource:@"minimal24" ofType:@"wav"] retain];
}

- (void) tearDown
{
    [mPathToMinimal16Wav release];
    mPathToMinimal16Wav = nil;
    [mPathToMinimal24Wav release];
    mPathToMinimal24Wav = nil;
    [super tearDown];
}

- (void) testLoadFile
{
    DWTWaveFile* waveFile = [[DWTWaveFile alloc] initWithData:[NSData dataWithContentsOfFile:mPathToMinimal16Wav]];
    STAssertNotNil(waveFile, @"expected to load 16 bit file");
    [waveFile release];
    waveFile = [[DWTWaveFile alloc] initWithData:[NSData dataWithContentsOfFile:mPathToMinimal24Wav]];
    STAssertNotNil(waveFile, @"expected to load 24 bit file");
    [waveFile release];
}

- (void) testAudioSource16
{
    DWTWaveFile* waveFile = [[DWTWaveFile alloc] initWithData:[NSData dataWithContentsOfFile:mPathToMinimal16Wav]];
    STAssertNotNil(waveFile, @"expected to load 16 bit file");
    STAssertTrue(waveFile.length == 2, @"expected 2 samples long, got %lu", waveFile.length);
    id<DWTAudioSampleSource> audioSource = [waveFile sampleSourceForChannel:0];
    STAssertNotNil(audioSource, @"expected to get a sample source for channel 0");
    DWTAudioBuffer* buffer = [[DWTAudioBuffer alloc] initWithSource:audioSource range:NSMakeRange(0, 2)];
    STAssertNotNil(buffer, @"expected to get a buffer");
    int64_t sample = [buffer sampleAtIndex:0];
    STAssertTrue(sample == (1LL << 48), @"expected sample value 1, got %ld", sample);
    sample = [buffer sampleAtIndex:1];
    STAssertTrue(sample == (3LL << 48), @"expected sample value 3, got %ld", sample);
    STAssertThrows([buffer sampleAtIndex:2], @"expected exception");
    [buffer release];
    audioSource = [waveFile sampleSourceForChannel:1];
    STAssertNotNil(audioSource, @"expected to get a sample source for channel 1");
    buffer = [[DWTAudioBuffer alloc] initWithSource:audioSource range:NSMakeRange(0, 2)];
    STAssertNotNil(buffer, @"expected to get a buffer");
    sample = [buffer sampleAtIndex:0];
    STAssertTrue(sample == (2LL << 48), @"expected sample value 2, got %ld", sample);
    sample = [buffer sampleAtIndex:1];
    STAssertTrue(sample == (-4LL << 48), @"expected sample value -4, got %ld", sample);
    STAssertThrows([buffer sampleAtIndex:2], @"expected exception");
    [buffer release];
    audioSource = [waveFile sampleSourceForChannel:2];
    STAssertNil(audioSource, @"expected not to get a source for channel 2");
    [waveFile release];
}

- (void) testAudioSource24
{
    DWTWaveFile* waveFile = [[DWTWaveFile alloc] initWithData:[NSData dataWithContentsOfFile:mPathToMinimal24Wav]];
    STAssertNotNil(waveFile, @"expected to load 24 bit file");
    STAssertTrue(waveFile.length == 2, @"expected 2 samples long, got %lu", waveFile.length);
    id<DWTAudioSampleSource> audioSource = [waveFile sampleSourceForChannel:0];
    STAssertNotNil(audioSource, @"expected to get a sample source for channel 0");
    DWTAudioBuffer* buffer = [[DWTAudioBuffer alloc] initWithSource:audioSource range:NSMakeRange(0, 2)];
    STAssertNotNil(buffer, @"expected to get a buffer");
    int64_t sample = [buffer sampleAtIndex:0];
    STAssertTrue(sample == (1LL << 40), @"expected sample value 1, got %ld", sample);
    sample = [buffer sampleAtIndex:1];
    STAssertTrue(sample == (3LL << 40), @"expected sample value 3, got %ld", sample);
    STAssertThrows([buffer sampleAtIndex:2], @"expected exception");
    [buffer release];
    audioSource = [waveFile sampleSourceForChannel:1];
    STAssertNotNil(audioSource, @"expected to get a sample source for channel 1");
    buffer = [[DWTAudioBuffer alloc] initWithSource:audioSource range:NSMakeRange(0, 2)];
    STAssertNotNil(buffer, @"expected to get a buffer");
    sample = [buffer sampleAtIndex:0];
    STAssertTrue(sample == (2LL << 40), @"expected sample value 2, got %ld", sample);
    sample = [buffer sampleAtIndex:1];
    STAssertTrue(sample == (-4LL << 40), @"expected sample value -4, got %ld", sample);
    STAssertThrows([buffer sampleAtIndex:2], @"expected exception");
    [buffer release];
    audioSource = [waveFile sampleSourceForChannel:2];
    STAssertNil(audioSource, @"expected not to get a source for channel 2");
    [waveFile release];
}

- (void) testRoundTrip
{
    // Create a wave file from chunks.
    DWTWaveChunk* riffChunk = [[DWTWaveChunk alloc] init];
    riffChunk.directData = [@"WAVE" dataUsingEncoding:NSISOLatin1StringEncoding];
    DWTWaveFmtChunk* fmtChunk = [[DWTWaveFmtChunk alloc] init];
    fmtChunk.compressionCode = 1; // TODO: This should be a symbolic constant.
    fmtChunk.numChannels = 4;
    fmtChunk.sampleRate = 13;
    fmtChunk.averageBytesPerSecond = 19; // This is not validated.
    fmtChunk.blockAlign = 16; // 4 bytes per sample per channel * 4 channels
    fmtChunk.bitsPerSample = 32;
    [riffChunk appendSubchunk:fmtChunk];
    [fmtChunk release];
    fmtChunk = nil;
    DWTWaveDataChunk* dataChunk = [[DWTWaveDataChunk alloc] init];
    int32_t samples[] = {
        1, 2, -3, 4,
        5, 6, 7, -8
    };
    dataChunk.directData = [[NSData alloc] initWithBytes:&samples[0] length:sizeof(samples)];
    [riffChunk appendSubchunk:dataChunk];
    [dataChunk release];

    // Grab the data.
    NSData* fileData = [[riffChunk data] retain];
    [riffChunk release];

    // Now try to read the file back from the data we got.
    DWTWaveFile* waveFile = [[DWTWaveFile alloc] initWithData:fileData];
    STAssertNotNil(waveFile, @"expected to load file created from scratch");
    STAssertNotNil(waveFile.riffChunk, @"expected a riff chunk");
    STAssertTrue([waveFile.riffChunk countOfSubchunks] == 2, @"expected 2 subchunks");
    STAssertTrue(waveFile.sampleRate == 13, @"expected sample rate 13, got %lu", waveFile.sampleRate);
    STAssertTrue(waveFile.bitDepth == 32, @"expected 32 bits, got %lu", waveFile.bitDepth);
    STAssertTrue(waveFile.numberOfChannels == 4, @"expected 4 channels, got %lu", waveFile.numberOfChannels);
    STAssertTrue(waveFile.length == 2, @"expected 2 samples long, got %lu", waveFile.length);

    id<DWTAudioSampleSource> audioSource = [waveFile sampleSourceForChannel:0];
    STAssertNotNil(audioSource, @"expected to get a sample source for channel 0");
    DWTAudioBuffer* buffer = [[DWTAudioBuffer alloc] initWithSource:audioSource range:NSMakeRange(0, 2)];
    STAssertNotNil(buffer, @"expected to get a buffer");
    int64_t sample = [buffer sampleAtIndex:0];
    STAssertTrue(sample == (1LL << 32), @"expected sample value 1, got %ld", sample);
    sample = [buffer sampleAtIndex:1];
    STAssertTrue(sample == (5LL << 32), @"expected sample value 5, got %ld", sample);
    STAssertThrows([buffer sampleAtIndex:2], @"expected exception");
    [buffer release];

    audioSource = [waveFile sampleSourceForChannel:1];
    STAssertNotNil(audioSource, @"expected to get a sample source for channel 1");
    buffer = [[DWTAudioBuffer alloc] initWithSource:audioSource range:NSMakeRange(0, 2)];
    STAssertNotNil(buffer, @"expected to get a buffer");
    sample = [buffer sampleAtIndex:0];
    STAssertTrue(sample == (2LL << 32), @"expected sample value 2, got %ld", sample);
    sample = [buffer sampleAtIndex:1];
    STAssertTrue(sample == (6LL << 32), @"expected sample value -4, got %ld", sample);
    STAssertThrows([buffer sampleAtIndex:2], @"expected exception");
    [buffer release];

    audioSource = [waveFile sampleSourceForChannel:2];
    STAssertNotNil(audioSource, @"expected to get a sample source for channel 2");
    buffer = [[DWTAudioBuffer alloc] initWithSource:audioSource range:NSMakeRange(0, 2)];
    STAssertNotNil(buffer, @"expected to get a buffer");
    sample = [buffer sampleAtIndex:0];
    STAssertTrue(sample == (-3LL << 32), @"expected sample value -3, got %ld", sample);
    sample = [buffer sampleAtIndex:1];
    STAssertTrue(sample == (7LL << 32), @"expected sample value 7, got %ld", sample);
    STAssertThrows([buffer sampleAtIndex:2], @"expected exception");
    [buffer release];

    audioSource = [waveFile sampleSourceForChannel:3];
    STAssertNotNil(audioSource, @"expected to get a sample source for channel 3");
    buffer = [[DWTAudioBuffer alloc] initWithSource:audioSource range:NSMakeRange(0, 2)];
    STAssertNotNil(buffer, @"expected to get a buffer");
    sample = [buffer sampleAtIndex:0];
    STAssertTrue(sample == (4LL << 32), @"expected sample value 4, got %ld", sample);
    sample = [buffer sampleAtIndex:1];
    STAssertTrue(sample == (-8LL << 32), @"expected sample value -8, got %ld", sample);
    STAssertThrows([buffer sampleAtIndex:2], @"expected exception");
    [buffer release];

    audioSource = [waveFile sampleSourceForChannel:4];
    STAssertNil(audioSource, @"expected not to get a source for channel 4");
    [waveFile release];
}

@end
