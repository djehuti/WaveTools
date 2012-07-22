//
//  DWTWaveSilentChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/21/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveSilentChunk.h"
#import "NSData+WaveToolsExtensions.h"
#import "WaveToolsLocalization.h"


@interface DWTWaveSilentChunk ()
{
    uint32_t mNumberOfSilentSamples;
}
@end

#pragma mark -

@implementation DWTWaveSilentChunk

#pragma mark Properties

- (NSString*) moreInfo
{
    NSString* formatString = DWTLocalizedString(@"%lu silent samples", @"silent sample count for slnt chunk");
    return [NSString stringWithFormat:formatString, mNumberOfSilentSamples];
}

- (uint32_t) numberOfSilentSamples
{
    return mNumberOfSilentSamples;
}

- (void) setNumberOfSilentSamples:(uint32_t)numberOfSilentSamples
{
    if (numberOfSilentSamples != mNumberOfSilentSamples) {
        mNumberOfSilentSamples = numberOfSilentSamples;
        NSMutableData* newData = [NSMutableData dataWithLength:sizeof(uint32_t)];
        [newData writeUint32:mNumberOfSilentSamples atOffset:0];
        self.directData = newData;
    }
}

#pragma mark - Lifecycle

+ (NSString*) defaultChunkID
{
    return @"slnt";
}

+ (NSData*) emptyChunkData
{
    static unsigned char s_emptyChunkBytes[] = {
        's', 'l', 'n', 't', 4, 0, 0, 0,
        0, 0, 0, 0 // 0 silent samples
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
        if ([self.directData length] != sizeof(uint32_t)) {
            [self release];
            self = nil;
        } else {
            mNumberOfSilentSamples = [self.directData readUint32AtOffset:0];
        }
    }
    return self;
}

#pragma mark -

+ (BOOL) canHandleChunkWithData:(NSData*)data
{
    return ([data length] == kDWTWaveChunkHeaderSize + sizeof(uint32_t));
}

#pragma mark - Debugging

- (NSString*) additionalDebugInfo
{
    return [NSString stringWithFormat:@" %@", self.moreInfo];
}

@end
