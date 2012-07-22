//
//  DWTWaveCueChunk.h
//  WaveTools
//
//  Created by Ben Cox on 7/21/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import <WaveTools/WaveTools.h>


@interface DWTWaveCuePoint : NSObject

@property (nonatomic, readwrite, assign) uint32_t cuePointID;
@property (nonatomic, readwrite, assign) uint32_t position;
@property (nonatomic, readwrite, retain) NSString* dataChunkID;
@property (nonatomic, readwrite, assign) uint32_t chunkStart;
@property (nonatomic, readwrite, assign) uint32_t blockStart;
@property (nonatomic, readwrite, assign) uint32_t sampleOffset;

- (id) init; // DI
- (id) initWithData:(NSData*)data offset:(NSUInteger)offset; // Alternate DI.

- (void) readFromData:(NSData*)data offset:(NSUInteger)offset;
- (void) writeToData:(NSMutableData*)data offset:(NSUInteger)offset;

- (NSUInteger) byteLength; // Returns 24.

@end

#pragma mark -

@interface DWTWaveCueChunk : DWTWaveChunk

@property (nonatomic, readwrite, copy) NSArray* cuePoints;

// cuePoints property accessor methods.

- (NSUInteger) countOfCuePoints;
- (DWTWaveCuePoint*) objectInCuePointsAtIndex:(NSUInteger)index;
- (void) getCuePoints:(DWTWaveCuePoint**)buffer range:(NSRange)inRange;

- (void) insertObject:(DWTWaveCuePoint*)object inCuePointsAtIndex:(NSUInteger)index;
- (void) removeObjectFromCuePointsAtIndex:(NSUInteger)index;
- (void) replaceObjectInCuePointsAtIndex:(NSUInteger)index withObject:(DWTWaveCuePoint*)object;

- (void) appendCuePoint:(DWTWaveCuePoint*)cuePoint;

@end
