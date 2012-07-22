//
//  DWTWaveLabelChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/21/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveLabelChunk.h"
#import "WaveToolsLocalization.h"
#import <CoreFoundation/CoreFoundation.h>
#import "NSData+WaveToolsExtensions.h"


@interface  DWTWaveLabelChunk ()
{
    uint32_t mCuePointID;
    NSString* mStringValue;
}

- (void) p_setupData;

@end

#pragma mark -

@implementation DWTWaveLabelChunk

#pragma mark Properties

- (uint32_t) cuePointID
{
    return mCuePointID;
}

- (void) setCuePointID:(uint32_t)cuePointID
{
    if (cuePointID != mCuePointID) {
        mCuePointID = cuePointID;
        [self p_setupData];
    }
}

- (NSString*) stringValue
{
    return mStringValue;
}

- (void) setStringValue:(NSString*)stringValue
{
    if (stringValue != mStringValue && ![stringValue isEqualToString:mStringValue]) {
        [mStringValue release];
        mStringValue = [stringValue retain];
        [self p_setupData];
    }
}

#pragma mark - Lifecycle

+ (NSString*) defaultChunkID
{
    return @"labl";
}

+ (NSData*) emptyChunkData
{
    static unsigned char s_emptyChunkBytes[] = {
        'l', 'a', 'b', 'l', 4, 0, 0, 0,
        0, 0, 0, 0 // cue point ID
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
        if ([self.directData length] < sizeof(uint32_t)) {
            [self release];
            self = nil;
        } else {
            mCuePointID = [self.directData readUint32AtOffset:0];
            if ([self.directData length] > sizeof(uint32_t)) {
                const void* bytes = [self.directData bytes];
                mStringValue = [[NSString alloc] initWithBytes:bytes length:([self.directData length] - 1) encoding:NSISOLatin1StringEncoding];
            } else {
                mStringValue = [[NSString alloc] init];
            }
        }
    }
    return self;
}

- (void) dealloc
{
    [mStringValue release];
    mStringValue = nil;
    [super dealloc];
}

+ (BOOL) canHandleChunkWithData:(NSData*)data
{
    return ([data length] >= (kDWTWaveChunkHeaderSize + sizeof(uint32_t)));
}

#pragma mark -

+ (NSUInteger) autoProcessSubchunkOffset
{
    return NSUIntegerMax;
}

- (NSString*) additionalDebugInfo
{
    return [NSString stringWithFormat:@" %@", [self moreInfo]];
}

- (NSString*) moreInfo
{
    NSString* formatString = nil;
    if ([mStringValue length] > 0) {
        formatString = DWTLocalizedString(@"Cue Point ID: %lu, label \"%@\"", @"label chunk format string with label");
    } else {
        formatString = DWTLocalizedString(@"Cue Point ID: %lu, no label", @"label chunk format string without label");
    }
    return [NSString stringWithFormat:formatString, (NSUInteger)mCuePointID, mStringValue];
}

#pragma mark - Private Methods

- (void) p_setupData
{
    NSData* stringData = [mStringValue dataUsingEncoding:NSISOLatin1StringEncoding];
    NSMutableData* newData = [NSMutableData dataWithCapacity:sizeof(uint32_t) + [stringData length] + 1];
    uint32_t extCuePointId = CFSwapInt32HostToLittle(mCuePointID);
    [newData appendBytes:&extCuePointId length:sizeof(extCuePointId)];
    [newData appendData:stringData];
    unsigned char const zero = 0;
    [newData appendBytes:(const void *)&zero length:1];
    self.directData = newData;
}

@end
