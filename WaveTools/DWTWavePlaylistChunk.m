//
//  DWTWavePlaylistChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/22/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "DWTWavePlaylistChunk.h"
#import "WaveToolsLocalization.h"
#import "NSData+WaveToolsExtensions.h"


static const NSUInteger kDWTWavePlaylistSegmentCuePointIDOffset = 0;
static const NSUInteger kDWTWavePlaylistSegmentLengthOffset = 4;
static const NSUInteger kDWTWavePlaylistSegmentRepeatCountOffset = 8;
static const NSUInteger kDWTWavePlaylistSegmentSize = 12;


@interface DWTWavePlaylistSegment ()
{
    uint32_t mCuePointID;
    uint32_t mLength;
    uint32_t mRepeatCount;
}
@end

@implementation DWTWavePlaylistSegment

@synthesize cuePointID = mCuePointID;
@synthesize length = mLength;
@synthesize repeatCount = mRepeatCount;

- (id) init
{
    if ((self = [super init])) {
        // We don't actually have anything to do here.
    }
    return self;
}

- (id) initWithData:(NSData*)data offset:(NSUInteger)offset
{
    if ((self = [super init])) {
        @try {
            [self readFromData:data offset:offset];
        }
        @catch (NSException* exception) {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (void) readFromData:(NSData*)data offset:(NSUInteger)offset
{
    mCuePointID = [data readUint32AtOffset:offset + kDWTWavePlaylistSegmentCuePointIDOffset];
    mLength = [data readUint32AtOffset:offset + kDWTWavePlaylistSegmentLengthOffset];
    mRepeatCount = [data readUint32AtOffset:offset + kDWTWavePlaylistSegmentRepeatCountOffset];
}

- (void) writeToData:(NSMutableData*)data offset:(NSUInteger)offset
{
    [data writeUint32:mCuePointID atOffset:offset + kDWTWavePlaylistSegmentCuePointIDOffset];
    [data writeUint32:mLength atOffset:offset + kDWTWavePlaylistSegmentLengthOffset];
    [data writeUint32:mRepeatCount atOffset:offset + kDWTWavePlaylistSegmentRepeatCountOffset];
}

- (NSUInteger) byteLength
{
    return kDWTWavePlaylistSegmentSize;
}

@end

#pragma mark -

@interface DWTWavePlaylistChunk ()
{
    NSMutableArray* mSegments;
}

- (void) p_fixupData;

@end

#pragma mark -

@implementation DWTWavePlaylistChunk

#pragma mark Properties

- (NSString*) moreInfo
{
    NSString* formatString = DWTLocalizedString(@"%lu segments", @"format string for playlist segment count");
    return [NSString stringWithFormat:formatString, [mSegments count]];
}

- (NSArray*) segments
{
    return [NSArray arrayWithArray:mSegments];
}

- (void) setSegments:(NSArray*)segments
{
    [mSegments removeAllObjects];
    if (segments) {
        [segments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (![obj isKindOfClass:[DWTWavePlaylistSegment class]]) {
                NSException* exc = [NSException exceptionWithName:NSInvalidArgumentException
                                                           reason:DWTLocalizedString(@"Invalid object in playlist segments array", @"Invalid object in playlist segments array")
                                                         userInfo:[NSDictionary dictionary]];
                @throw exc;
            }
        }];
    }
    [self p_fixupData];
}

- (NSUInteger) countOfSegments
{
    return [mSegments count];
}

- (DWTWavePlaylistSegment*) objectInSegmentsAtIndex:(NSUInteger)index
{
    return (DWTWavePlaylistSegment*)[mSegments objectAtIndex:index];
}

- (void) getSegments:(DWTWavePlaylistSegment**)buffer range:(NSRange)inRange
{
    [mSegments getObjects:buffer range:inRange];
}

- (void) insertObject:(DWTWavePlaylistSegment*)object inSegmentsAtIndex:(NSUInteger)index
{
    [mSegments insertObject:object atIndex:index];
    [self p_fixupData];
}

- (void) removeObjectFromSegmentsAtIndex:(NSUInteger)index
{
    [mSegments removeObjectAtIndex:index];
    [self p_fixupData];
}

- (void) replaceObjectInSegmentsAtIndex:(NSUInteger)index withObject:(DWTWavePlaylistSegment*)object
{
    [mSegments replaceObjectAtIndex:index withObject:object];
    [self p_fixupData];
}

- (void) appendSegment:(DWTWavePlaylistSegment*)segment
{
    [mSegments addObject:segment];
    [self p_fixupData];
}

#pragma mark - Lifecycle

+ (NSString*) defaultChunkID
{
    return @"plst";
}

+ (NSData*) emptyChunkData
{
    static unsigned char s_emptyChunkBytes[] = {
        'p', 'l', 's', 't', 4, 0, 0, 0,
        0, 0, 0, 0
    };
    static NSData* s_emptyChunkData = nil;
    static dispatch_once_t s_emptyChunkOnce;
    dispatch_once(&s_emptyChunkOnce, ^{
        s_emptyChunkData = [[NSData alloc] initWithBytesNoCopy:&s_emptyChunkBytes[0] length:sizeof(s_emptyChunkBytes) freeWhenDone:NO];
    });
    return s_emptyChunkData;
}

- (id) initWithData:(NSData*)data
{
    if ((self = [super initWithData:data])) {
        NSData* directData = self.directData;
        NSUInteger segmentCount = (NSUInteger)[directData readUint32AtOffset:0];
        if ([directData length] != (sizeof(uint32_t) + segmentCount * kDWTWavePlaylistSegmentSize)) {
            [self release];
            self = nil;
        } else {
            mSegments = [[NSMutableArray alloc] initWithCapacity:segmentCount];
            for (NSUInteger segmentIndex = 0; segmentIndex < segmentCount; ++segmentIndex) {
                NSUInteger offset = sizeof(uint32_t) + segmentIndex * kDWTWavePlaylistSegmentSize;
                DWTWavePlaylistSegment* segment = [[DWTWavePlaylistSegment alloc] initWithData:directData offset:offset];
                [mSegments addObject:segment];
            }
        }
    }
    return self;
}

- (void) dealloc
{
    [mSegments release];
    mSegments = nil;
    [super dealloc];
}

#pragma mark -

+ (BOOL) canHandleChunkWithData:(NSData*)data
{
    BOOL canHandle = NO;
    if ([data length] >= kDWTWaveChunkHeaderSize + sizeof(uint32_t)) {
        uint32_t segmentCount = [data readUint32AtOffset:kDWTWaveChunkHeaderSize];
        NSUInteger segmentsSize = segmentCount * kDWTWavePlaylistSegmentSize;
        NSUInteger correctSize = kDWTWaveChunkHeaderSize + sizeof(uint32_t) + segmentsSize;
        if ([data length] == correctSize) {
            canHandle = YES;
        }
    }
    return canHandle;
}

+ (NSUInteger) autoProcessSubchunkOffset
{
    // No subchunks.
    return NSUIntegerMax;
}

#pragma mark - Debugging

- (NSString*) additionalDebugInfo
{
    return [NSString stringWithFormat:@" %@", self.moreInfo];
}

#pragma mark - Private Methods

- (void) p_fixupData
{
    NSUInteger segmentCount = [mSegments count];
    NSUInteger dataSize = sizeof(uint32_t) + segmentCount * kDWTWavePlaylistSegmentSize;
    NSMutableData* directData = [NSMutableData dataWithLength:dataSize];
    [directData writeUint32:(uint32_t)segmentCount atOffset:0];
    for (NSUInteger segmentIndex = 0; segmentIndex < segmentCount; ++segmentIndex) {
        NSUInteger offset = sizeof(uint32_t) + segmentIndex * kDWTWavePlaylistSegmentSize;
        DWTWavePlaylistSegment* segment = [self objectInSegmentsAtIndex:segmentIndex];
        [segment writeToData:directData offset:offset];
    }
    self.directData = directData;
}

@end
