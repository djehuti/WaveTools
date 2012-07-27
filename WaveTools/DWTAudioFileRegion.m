//
//  DWTAudioFileRegion.m
//  WaveTools
//
//  Created by Ben Cox on 7/26/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "DWTAudioFileRegion.h"
#import "WaveToolsLocalization.h"


@interface DWTAudioFileRegion ()
{
@protected
    NSUInteger mStart;
    NSUInteger mEnd;
    NSString* mName;
}
@end

@implementation DWTAudioFileRegion

@synthesize start = mStart;
@synthesize end = mEnd;
@synthesize name = mName;

- (NSUInteger) length
{
    return mEnd - mStart;
}

- (id) initWithStart:(NSUInteger)start end:(NSUInteger)end name:(NSString *)name
{
    if ((self = [super init])) {
        if (mStart > mEnd) {
            NSException* exc = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:DWTLocalizedString(@"start cannot be later than end", @"start > end message")
                                                     userInfo:[NSDictionary dictionary]];
            @throw exc;
        }
        mStart = start;
        mEnd = end;
        mName = [name retain];
    }
    return self;
}

- (void) dealloc
{
    [mName release];
    mName = nil;
    [super dealloc];
}

- (id) copyWithZone:(NSZone*)zone
{
    return [[[self class] alloc] initWithStart:mStart end:mEnd name:mName];
}

- (id) mutableCopyWithZone:(NSZone*)zone
{
    return [[DWTMutableAudioFileRegion alloc] initWithStart:mStart end:mEnd name:mName];
}

@end


@implementation DWTMutableAudioFileRegion

- (void) setStart:(NSUInteger)start
{
    if (start != mStart) {
        if (start > mEnd) {
            [self willChangeValueForKey:@"end"];
            mEnd = start;
            [self didChangeValueForKey:@"end"];
        }
        mStart = start;
    }
}

- (void) setEnd:(NSUInteger)end
{
    if (end != mEnd) {
        if (end < mStart) {
            [self willChangeValueForKey:@"start"];
            mStart = end;
            [self didChangeValueForKey:@"start"];
        }
        mEnd = end;
    }
}

@end
