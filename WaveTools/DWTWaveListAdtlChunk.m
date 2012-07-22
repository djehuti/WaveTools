//
//  DWTWaveListAdtlChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/21/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveListAdtlChunk.h"
#import "NSData+WaveToolsExtensions.h"
#import "WaveToolsLocalization.h"


@implementation DWTWaveListAdtlChunk

+ (NSData*) emptyChunkData
{
    static unsigned char s_emptyChunkBytes[] = {
        'l', 'l', 's', 't', 4, 0, 0, 0,
        'a', 'd', 't', 'l'
    };
    static NSData* s_emptyChunkData = nil;
    static dispatch_once_t s_emptyChunkOnce;
    dispatch_once(&s_emptyChunkOnce, ^{
        s_emptyChunkData = [[NSData alloc] initWithBytesNoCopy:&s_emptyChunkBytes[0] length:sizeof(s_emptyChunkBytes) freeWhenDone:NO];
    });
    return s_emptyChunkData;
}

+ (BOOL) canHandleChunkWithData:(NSData*)data
{
    NSString* subtype = [data read4CharAtOffset:kDWTWaveChunkHeaderSize];
    return ([subtype caseInsensitiveCompare:@"adtl"] == NSOrderedSame);
}

+ (NSUInteger) autoProcessSubchunkOffset
{
    // The first bit is 'adtl' and then subchunks.
    return 4;
}

- (NSString*) moreInfo
{
    return DWTLocalizedString(@"Associated data list chunk", @"list-adtl chunk subtype");
}

@end
