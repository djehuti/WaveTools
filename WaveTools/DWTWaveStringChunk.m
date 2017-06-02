//
//  DWTWaveStringChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/17/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveStringChunk.h"
#import "NSData+WaveToolsExtensions.h"


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
        NSMutableData* newData = [NSMutableData dataWithLength:0];
        [newData writeNulTerminatedString:mStringValue atOffset:0];
        
        // check for the correct padding
        // An odd byte length chunks exists that is not immediately followed by a NULL byte.
        // This could cause problems in reading subsequent chunks in some systems so add one more byte.
        if (newData.length % 2 != 0) {
            [newData writeNulTerminatedString:@"" atOffset:newData.length];
        }
        self.directData = newData;
    }
}

#pragma mark - Lifecycle

- (id) initWithData:(NSData*)data
{
    if ((self = [super initWithData:data])) {
        mStringValue = [[self.directData readNulTerminatedStringAtOffset:0] retain];
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
