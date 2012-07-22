//
//  DWTWavePlaylistChunk.h
//  WaveTools
//
//  Created by Ben Cox on 7/22/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import <WaveTools/WaveTools.h>


@interface DWTWavePlaylistSegment : NSObject

@property (nonatomic, readwrite, assign) uint32_t cuePointID;
@property (nonatomic, readwrite, assign) uint32_t length;
@property (nonatomic, readwrite, assign) uint32_t repeatCount;

- (id) init; // DI
- (id) initWithData:(NSData*)data offset:(NSUInteger)offset; // Alternate DI.

- (void) readFromData:(NSData*)data offset:(NSUInteger)offset;
- (void) writeToData:(NSMutableData*)data offset:(NSUInteger)offset;

- (NSUInteger) byteLength; // Returns 12.

@end

#pragma mark -

@interface DWTWavePlaylistChunk : DWTWaveChunk

@property (nonatomic, readwrite, copy) NSArray* segments;

// segments property accessor methods.

- (NSUInteger) countOfSegments;
- (DWTWavePlaylistSegment*) objectInSegmentsAtIndex:(NSUInteger)index;
- (void) getSegments:(DWTWavePlaylistSegment**)buffer range:(NSRange)inRange;

- (void) insertObject:(DWTWavePlaylistSegment*)object inSegmentsAtIndex:(NSUInteger)index;
- (void) removeObjectFromSegmentsAtIndex:(NSUInteger)index;
- (void) replaceObjectInSegmentsAtIndex:(NSUInteger)index withObject:(DWTWavePlaylistSegment*)object;

- (void) appendSegment:(DWTWavePlaylistSegment*)segment;

@end
