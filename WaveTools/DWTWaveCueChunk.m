//
//  DWTWaveCueChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/21/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveCueChunk.h"
#import "WaveToolsLocalization.h"
#import "NSData+WaveToolsExtensions.h"


static const NSUInteger kDWTWaveCuePointPointIDOffset = 0;
static const NSUInteger kDWTWaveCuePointPositionOffset = 4;
static const NSUInteger kDWTWaveCuePointDataChunkIDOffset = 8;
static const NSUInteger kDWTWaveCuePointChunkStartOffset = 12;
static const NSUInteger kDWTWaveCuePointBlockStartOffset = 16;
static const NSUInteger kDWTWaveCuePointSampleOffsetOffset = 20;
static const NSUInteger kDWTWaveCuePointSize = 24;


@interface DWTWaveCuePoint ()
{
    uint32_t mCuePointID;
    uint32_t mPosition;
    NSString* mDataChunkID;
    uint32_t mChunkStart;
    uint32_t mBlockStart;
    uint32_t mSampleOffset;
}
@end

@implementation DWTWaveCuePoint

@synthesize cuePointID = mCuePointID;
@synthesize position = mPosition;
@synthesize dataChunkID = mDataChunkID;
@synthesize chunkStart = mChunkStart;
@synthesize blockStart = mBlockStart;
@synthesize sampleOffset = mSampleOffset;

- (NSString*) dataChunkID
{
    return mDataChunkID;
}

- (void) setDataChunkID:(NSString*)dataChunkID
{
    if (dataChunkID != mDataChunkID) {
        if (dataChunkID != nil && [dataChunkID length] != kDWTWaveChunkIDSize) {
            NSException* exc = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:DWTLocalizedString(@"Invalid chunk ID length.", @"Invalid chunk ID length.")
                                                     userInfo:[NSDictionary dictionary]];
            @throw exc;
        }
        [mDataChunkID release];
        mDataChunkID = [dataChunkID retain];
    }
}

- (id) init
{
    if ((self = [super init])) {
        // We don't actually have anything to do here.
    }
    return self;
}

- (id) initWithData:(NSData *)data offset:(NSUInteger)offset
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
    mCuePointID = [data readUint32AtOffset:offset + kDWTWaveCuePointPointIDOffset];
    mPosition = [data readUint32AtOffset:offset + kDWTWaveCuePointPositionOffset];
    mDataChunkID = [[data read4CharAtOffset:offset + kDWTWaveCuePointDataChunkIDOffset] retain];
    mChunkStart = [data readUint32AtOffset:offset + kDWTWaveCuePointChunkStartOffset];
    mBlockStart = [data readUint32AtOffset:offset + kDWTWaveCuePointBlockStartOffset];
    mSampleOffset = [data readUint32AtOffset:offset + kDWTWaveCuePointSampleOffsetOffset];
}

- (void) writeToData:(NSMutableData*)data offset:(NSUInteger)offset
{
    [data writeUint32:mCuePointID atOffset:offset + kDWTWaveCuePointPointIDOffset];
    [data writeUint32:mPosition atOffset:offset + kDWTWaveCuePointPositionOffset];
    [data write4Char:mDataChunkID atOffset:offset + kDWTWaveCuePointDataChunkIDOffset];
    [data writeUint32:mChunkStart atOffset:offset + kDWTWaveCuePointChunkStartOffset];
    [data writeUint32:mBlockStart atOffset:offset + kDWTWaveCuePointBlockStartOffset];
    [data writeUint32:mSampleOffset atOffset:offset + kDWTWaveCuePointSampleOffsetOffset];
}

- (NSUInteger) byteLength
{
    return kDWTWaveCuePointSize;
}

@end

#pragma mark -

@interface DWTWaveCueChunk ()
{
    NSMutableArray* mCuePoints;
}

- (void) p_fixupData;

@end

#pragma mark -

@implementation DWTWaveCueChunk

#pragma mark Properties

- (NSString*) moreInfo
{
    NSString* formatString = DWTLocalizedString(@"%lu cue points", @"format string for number of cue points");
    return [NSString stringWithFormat:formatString, [mCuePoints count]];
}

- (NSArray*) cuePoints
{
    return [NSArray arrayWithArray:mCuePoints];
}

- (void) setCuePoints:(NSArray*)cuePoints
{
    [mCuePoints removeAllObjects];
    if (cuePoints) {
        [cuePoints enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (![obj isKindOfClass:[DWTWaveCuePoint class]]) {
                NSException* exc = [NSException exceptionWithName:NSInvalidArgumentException
                                                           reason:DWTLocalizedString(@"Invalid object in cuePoints array", @"Invalid object in cuePoints array")
                                                         userInfo:[NSDictionary dictionary]];
                @throw exc;
            }
        }];
        [mCuePoints addObjectsFromArray:cuePoints];
    }
    [self p_fixupData];
}

- (NSUInteger) countOfCuePoints
{
    return [mCuePoints count];
}

- (DWTWaveCuePoint*) objectInCuePointsAtIndex:(NSUInteger)index
{
    return (DWTWaveCuePoint*)[mCuePoints objectAtIndex:index];
}

- (void) getCuePoints:(DWTWaveCuePoint**)buffer range:(NSRange)inRange
{
    [mCuePoints getObjects:buffer range:inRange];
}

- (void) insertObject:(DWTWaveCuePoint*)object inCuePointsAtIndex:(NSUInteger)index
{
    [mCuePoints insertObject:object atIndex:index];
    [self p_fixupData];
}

- (void) removeObjectFromCuePointsAtIndex:(NSUInteger)index
{
    [mCuePoints removeObjectAtIndex:index];
    [self p_fixupData];
}

- (void) replaceObjectInCuePointsAtIndex:(NSUInteger)index withObject:(DWTWaveCuePoint*)object
{
    [mCuePoints replaceObjectAtIndex:index withObject:object];
    [self p_fixupData];
}

- (void) appendCuePoint:(DWTWaveCuePoint*)cuePoint
{
    [mCuePoints addObject:cuePoint];
    [self p_fixupData];
}

#pragma mark - Lifecycle

+ (NSString*) defaultChunkID
{
    return @"cue ";
}

+ (NSData*) emptyChunkData
{
    static unsigned char s_emptyChunkBytes[] = {
        'c', 'u', 'e', ' ', 4, 0, 0, 0,
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
        NSUInteger cuePointCount = (NSUInteger)[directData readUint32AtOffset:0];
        if ([directData length] != (sizeof(uint32_t) + cuePointCount * kDWTWaveCuePointSize)) {
            [self release];
            self = nil;
        } else {
            mCuePoints = [[NSMutableArray alloc] initWithCapacity:cuePointCount];
            for (NSUInteger cuePointIndex = 0; cuePointIndex < cuePointCount; ++cuePointIndex) {
                NSUInteger offset = sizeof(uint32_t) + cuePointIndex * kDWTWaveCuePointSize;
                DWTWaveCuePoint* cuePoint = [[DWTWaveCuePoint alloc] initWithData:directData offset:offset];
                [mCuePoints addObject:cuePoint];
            }
        }
    }
    return self;
}

- (void) dealloc
{
    [mCuePoints release];
    mCuePoints = nil;
    [super dealloc];
}

#pragma mark -

+ (BOOL) canHandleChunkWithData:(NSData*)data
{
    BOOL canHandle = NO;
    if ([data length] >= kDWTWaveChunkHeaderSize + sizeof(uint32_t)) {
        uint32_t cuePointCount = [data readUint32AtOffset:kDWTWaveChunkHeaderSize];
        NSUInteger cuePointsSize = cuePointCount * kDWTWaveCuePointSize;
        NSUInteger correctSize = kDWTWaveChunkHeaderSize + sizeof(uint32_t) + cuePointsSize;
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
    NSUInteger cuePointCount = [mCuePoints count];
    NSUInteger dataSize = sizeof(uint32_t) + cuePointCount * kDWTWaveCuePointSize;
    NSMutableData* directData = [NSMutableData dataWithLength:dataSize];
    [directData writeUint32:(uint32_t)cuePointCount atOffset:0];
    for (NSUInteger cuePointIndex = 0; cuePointIndex < cuePointCount; ++cuePointIndex) {
        NSUInteger offset = sizeof(uint32_t) + cuePointIndex * kDWTWaveCuePointSize;
        DWTWaveCuePoint* cuePoint = [self objectInCuePointsAtIndex:cuePointIndex];
        [cuePoint writeToData:directData offset:offset];
    }
    self.directData = directData;
}

@end
