//
//  WaveChunkTests.m
//  WaveTools
//
//  Created by Ben Cox on 7/21/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "WaveChunkTests.h"
#import <WaveTools/WaveTools.h>


@implementation WaveChunkTests

+ (void) initialize
{
    if (self == [WaveChunkTests class]) {
        [DWTWaveChunk registerChunkClasses];
    }
}

- (void) setUp
{
    [super setUp];
    // Set-up code here.
}

- (void) tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void) testAllEmptyChunks
{
    DWTWaveChunk* chunk = nil;
    STAssertNoThrow(chunk = [[[DWTWaveChunk alloc] init] autorelease], @"init empty riff chunk");
    STAssertNotNil(chunk, @"init empty riff chunk");
    STAssertNoThrow(chunk = [[[DWTWaveUnknownChunk alloc] init] autorelease], @"init empty unknown chunk");
    STAssertNotNil(chunk, @"init empty unknown chunk");
    STAssertNoThrow(chunk = [[[DWTWaveDataChunk alloc] init] autorelease], @"init empty data chunk");
    STAssertNotNil(chunk, @"init empty data chunk");
    STAssertNoThrow(chunk = [[[DWTWaveFmtChunk alloc] init] autorelease], @"init empty fmt chunk");
    STAssertNotNil(chunk, @"init empty fmt chunk");
    STAssertNoThrow(chunk = [[[DWTWaveGenericListChunk alloc] init] autorelease], @"init empty generic list chunk");
    STAssertNotNil(chunk, @"init empty generic list chunk");
    STAssertNoThrow(chunk = [[[DWTWaveListInfoChunk alloc] init] autorelease], @"init empty list info chunk");
    STAssertNotNil(chunk, @"init empty list info chunk");
    STAssertNoThrow(chunk = [[[DWTWaveListAdtlChunk alloc] init] autorelease], @"init empty list adtl chunk");
    STAssertNotNil(chunk, @"init empty list adtl chunk");
    STAssertNoThrow(chunk = [[[DWTWaveStringChunk alloc] init] autorelease], @"init empty string chunk");
    STAssertNotNil(chunk, @"init empty string chunk");
    STAssertNoThrow(chunk = [[[DWTWaveLabelChunk alloc] init] autorelease], @"init empty label chunk");
    STAssertNotNil(chunk, @"init empty label chunk");
    STAssertNoThrow(chunk = [[[DWTWaveCueChunk alloc] init] autorelease], @"init empty cue chunk");
    STAssertNotNil(chunk, @"init empty cue chunk");
    STAssertNoThrow(chunk = [[[DWTWaveSilentChunk alloc] init] autorelease], @"init empty silent chunk");
    STAssertNotNil(chunk, @"init empty silent chunk");
    STAssertNoThrow(chunk = [[[DWTWavePlaylistChunk alloc] init] autorelease], @"init empty playlist chunk");
    STAssertNotNil(chunk, @"init empty playlist chunk");
}

- (void) testRiff
{
    static unsigned char riffData[] = {
        'R', 'I', 'F', 'F', 4, 0, 0, 0,
        'W', 'A', 'V', 'E'
    };

    NSData* emptyChunkData = [NSData dataWithBytesNoCopy:&riffData[0] length:sizeof(riffData) freeWhenDone:NO];
    DWTWaveChunk* chunk = [DWTWaveChunk chunkForData:emptyChunkData];
    STAssertNotNil(chunk, @"expected non-nil chunk");
    STAssertTrue([[chunk chunkID] isEqualToString:@"RIFF"], @"expected RIFF chunk");
    STAssertTrue([chunk countOfSubchunks] == 0, @"expected 0 subchunks");
}

- (void) testASubchunk
{
    static unsigned char riffData[] = {
        'R', 'I', 'F', 'F', 16, 0, 0, 0,
        'W', 'A', 'V', 'E',
        'd', 'a', 't', 'a', 4, 0, 0, 0,
        0, 0, 0, 0
    };
    
    NSData* emptyChunkData = [NSData dataWithBytesNoCopy:&riffData[0] length:sizeof(riffData) freeWhenDone:NO];
    DWTWaveChunk* chunk = [DWTWaveChunk chunkForData:emptyChunkData];
    STAssertNotNil(chunk, @"expected non-nil chunk");
    STAssertTrue([[chunk chunkID] isEqualToString:@"RIFF"], @"expected RIFF chunk");
    STAssertTrue([chunk countOfSubchunks] == 1, @"expected 1 subchunks");
    DWTWaveChunk* subchunk = [chunk objectInSubchunksAtIndex:0];
    STAssertTrue([[subchunk chunkID] isEqualToString:@"data"], @"expected data subchunk");
    STAssertTrue([subchunk chunkDataSize] == 4, @"expected data subchunk size 4");
    STAssertTrue([[subchunk directData] length] == 4, @"expected directData size 4");
}

- (void) testWriting
{
    static unsigned char riffData[] = {
        'R', 'I', 'F', 'F', 32, 0, 0, 0,
        'W', 'A', 'V', 'E',
        'L', 'I', 'S', 'T', 20, 0, 0, 0,
        'I', 'N', 'F', 'O',
        'I', 'A', 'R', 'T', 8, 0, 0, 0,
        'B', 'e', 'n', ' ', 'C', 'o', 'x', 0,
    };
    static NSUInteger riffDataSize = sizeof(riffData)/sizeof(riffData[0]);

    DWTWaveChunk* riffChunk = [[[DWTWaveChunk alloc] init] autorelease];
    riffChunk.chunkID = @"RIFF";
    riffChunk.directData = [@"WAVE" dataUsingEncoding:NSISOLatin1StringEncoding];
    DWTWaveListInfoChunk* listChunk = [[[DWTWaveListInfoChunk alloc] init] autorelease];
    listChunk.chunkID = @"LIST";
    listChunk.directData = [@"INFO" dataUsingEncoding:NSISOLatin1StringEncoding]; // TODO: This should be part of the list info chunk constructor.
    [riffChunk appendSubchunk:listChunk];
    DWTWaveStringChunk* iartChunk = [[[DWTWaveStringChunk alloc] init] autorelease];
    iartChunk.chunkID = @"IART";
    iartChunk.stringValue = @"Ben Cox";
    [listChunk appendSubchunk:iartChunk];
    NSData* data = [riffChunk data];
    STAssertEquals([data length], riffDataSize, @"expected %lu bytes", riffDataSize);
    int compare = memcmp([data bytes], &riffData[0], riffDataSize);
    STAssertEquals(compare, 0, @"expected data to match");
}

@end
