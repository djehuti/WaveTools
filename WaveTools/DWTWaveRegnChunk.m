//
//  DWTWaveRegnChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/22/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveRegnChunk.h"
#import "WaveToolsLocalization.h"


static const NSUInteger kDWTWaveRegnRegionStartOffset               = 16;
static const NSUInteger kDWTWaveRegnRegionEndOffset                 = 24;
static const NSUInteger kDWTWaveRegnRegionSyncPointOffset           = 32;
static const NSUInteger kDWTWaveRegnRegionUserTimeStampOffset       = 40;
static const NSUInteger kDWTWaveRegnRegionOriginalTimeStampOffset   = 48;
static const NSUInteger kDWTWaveRegnRegionNameOffset                = 56;
static const NSUInteger kDWTWaveRegnRegionSize                      = 88;


@interface DWTWaveRegnRegion ()
{
    uint64_t mStart;
    uint64_t mEnd;
    uint64_t mSyncPoint;
    uint64_t mUserTimeStamp;
    uint64_t mOriginalTimeStamp;
    NSString* mName;
}
@end

@implementation DWTWaveRegnRegion

@synthesize start = mStart;
@synthesize end = mEnd;
@synthesize syncPoint = mSyncPoint;
@synthesize userTimeStamp = mUserTimeStamp;
@synthesize originalTimeStamp = mOriginalTimeStamp;
@synthesize name = mName;

- (id) init
{
    self = [super init];
    NSLog(@"Wrong DWTWaveRegnRegion initializer called");
    [self release];
    self = nil;
    return self;
}

- (id) initWithData:(NSData*)data
{
    if ((self = [super init])) {
        if ([data length] != kDWTWaveRegnRegionSize) {
            [self release];
            self = nil;
        } else {
            mStart              = [data readUint64AtOffset:kDWTWaveRegnRegionStartOffset];
            mEnd                = [data readUint64AtOffset:kDWTWaveRegnRegionEndOffset];
            mSyncPoint          = [data readUint64AtOffset:kDWTWaveRegnRegionSyncPointOffset];
            mUserTimeStamp      = [data readUint64AtOffset:kDWTWaveRegnRegionUserTimeStampOffset];
            mOriginalTimeStamp  = [data readUint64AtOffset:kDWTWaveRegnRegionOriginalTimeStampOffset];
            mName               = [[data readPascalStringAtOffset:kDWTWaveRegnRegionNameOffset] retain];
        }
    }
    return self;
}

- (void) dealloc
{
    [mName release];
    mName = nil;
    [super dealloc];
}

@end

#pragma mark -

@interface DWTWaveRegnChunk ()
{
    NSArray* mRegions;
}
@end

#pragma mark -

@implementation DWTWaveRegnChunk

#pragma mark Properties

- (NSString*) moreInfo
{
    NSString* formatString = DWTLocalizedString(@"%lu regions", @"format string for number of regions");
    return [NSString stringWithFormat:formatString, [mRegions count]];
}

@synthesize regions = mRegions;

- (NSUInteger) countOfRegions
{
    return [mRegions count];
}

- (DWTWaveRegnRegion*) objectInRegionsAtIndex:(NSUInteger)index
{
    return (DWTWaveRegnRegion*)[mRegions objectAtIndex:index];
}

- (void) getRegions:(DWTWaveRegnRegion**)buffer range:(NSRange)inRange
{
    [mRegions getObjects:buffer range:inRange];
}

#pragma mark - Lifecycle

+ (NSString*) defaultChunkID
{
    return @"regn";
}

+ (NSData*) emptyChunkData
{
    static unsigned char s_emptyChunkBytes[] = {
        'r', 'e', 'g', 'n', 4, 0, 0, 0,
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
        NSUInteger regionCount = (NSUInteger)[directData readUint32AtOffset:0];
        if ([directData length] != (sizeof(uint32_t) + regionCount * kDWTWaveRegnRegionSize)) {
            [self release];
            self = nil;
        } else {
            NSMutableArray* regions = [[NSMutableArray alloc] initWithCapacity:regionCount];
            for (NSUInteger regionIndex = 0; regionIndex < regionCount; ++regionIndex) {
                NSUInteger offset = sizeof(uint32_t) + regionIndex * kDWTWaveRegnRegionSize;
                NSData* regionData = [directData subdataWithRange:NSMakeRange(offset, kDWTWaveRegnRegionSize)];
                DWTWaveRegnRegion* region = [[DWTWaveRegnRegion alloc] initWithData:regionData];
                [regions addObject:region];
                [region release];
            }
            mRegions = [[NSArray alloc] initWithArray:regions];
            [regions release];
        }
    }
    return self;
}

- (void) dealloc
{
    [mRegions release];
    mRegions = nil;
    [super dealloc];
}

#pragma mark -

+ (NSUInteger) autoProcessSubchunkOffset
{
    return NSUIntegerMax;
}

+ (BOOL) canHandleChunkWithData:(NSData*)data
{
    BOOL canHandle = NO;
    if ([data length] >= kDWTWaveChunkHeaderSize + sizeof(uint32_t)) {
        uint32_t regionCount = [data readUint32AtOffset:kDWTWaveChunkHeaderSize];
        NSUInteger regionsSize = regionCount * kDWTWaveRegnRegionSize;
        NSUInteger correctSize = kDWTWaveChunkHeaderSize + sizeof(uint32_t) + regionsSize;
        if ([data length] == correctSize) {
            canHandle = YES;
        }
    }
    return canHandle;
}

@end
