//
//  DWTWaveStringChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/17/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveStringChunk.h"


@interface DWTWaveStringChunk ()
{
    NSString* mStringValue;
}
@end

#pragma mark -

@implementation DWTWaveStringChunk

#pragma mark Properties

- (NSString*) stringValue
{
    return mStringValue;
}

- (void) setStringValue:(NSString*)stringValue
{
    if (stringValue != mStringValue && ![stringValue isEqualToString:mStringValue]) {
        [mStringValue release];
        mStringValue = [stringValue retain];
        NSData* stringData = [mStringValue dataUsingEncoding:NSISOLatin1StringEncoding];
        NSMutableData* newData = [NSMutableData dataWithCapacity:[stringData length] + 1];
        [newData appendData:stringData];
        unsigned char const zero = 0;
        [newData appendBytes:(const void *)&zero length:1];
        self.directData = newData;
    }
}

#pragma mark - Lifecycle

- (id) initWithData:(NSData*)data
{
    if ((self = [super initWithData:data])) {
        if ([self.directData length] > 0) {
            const void* bytes = [self.directData bytes];
            mStringValue = [[NSString alloc] initWithBytes:bytes length:([self.directData length] - 1) encoding:NSISOLatin1StringEncoding];
        } else {
            mStringValue = [[NSString alloc] init];
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

#pragma mark -

+ (NSUInteger) autoProcessSubchunkOffset
{
    return NSUIntegerMax;
}

- (NSString*) additionalDebugInfo
{
    if ([mStringValue length] > 0) {
        return [NSString stringWithFormat:@" \"%@\"", mStringValue];
    } else {
        return [super additionalDebugInfo];
    }
}

- (NSString*) moreInfo
{
    return mStringValue ? mStringValue : @"";
}

@end
