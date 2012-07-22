//
//  DWTWaveChunk.h
//  WaveTools
//
//  Created by Ben Cox on 7/12/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import <Foundation/Foundation.h>


extern const NSUInteger kDWTWaveChunkHeaderSize;    // This is 8.
extern const NSUInteger kDWTWaveChunkIDSize;        // This is 4.


@interface DWTWaveChunk : NSObject

@property (nonatomic, readwrite, retain) NSString* chunkID;
@property (nonatomic, readwrite, assign) NSUInteger chunkDataSize;
@property (nonatomic, readwrite, assign) DWTWaveChunk* parentChunk; // Unretained backpointer.
@property (nonatomic, readwrite, copy) NSArray* subchunks;
@property (nonatomic, readonly, retain) NSString* moreInfo;
// This property contains the data that belongs directly to this chunk (not to the subchunks).
// For example, for the RIFF chunk, this is 4 bytes containing {'W','A','V','E'}.
@property (nonatomic, readwrite, retain) NSData* directData;
@property (nonatomic, readonly, retain) NSString* dataDump;

// Subchunk property accessor methods.

- (NSUInteger) countOfSubchunks;
- (DWTWaveChunk*) objectInSubchunksAtIndex:(NSUInteger)index;
- (void) getSubchunks:(DWTWaveChunk**)buffer range:(NSRange)inRange;

- (void) insertObject:(DWTWaveChunk*)object inSubchunksAtIndex:(NSUInteger)index;
- (void) removeObjectFromSubchunksAtIndex:(NSUInteger)index;
- (void) replaceObjectInSubchunksAtIndex:(NSUInteger)index withObject:(DWTWaveChunk*)object;

- (void) appendSubchunk:(DWTWaveChunk*)subchunk;

// Lifecycle

+ (NSString*) defaultChunkID;
+ (NSData*) emptyChunkData;
- (id) initWithData:(NSData*)data; // Designated Initializer.

// Misc.

// Recalculate data size from directData and subchunks.
// (Call this after contents are changed.)
// This propagates up the tree; the parent will recalculate also.
// Chunk classes should call this whenever they change their direct data.
- (void) recalculateDataSize;

// This method regenerates the data from this and all subchunks.
- (NSData*) data;
// This method writes the data for this chunk into the given memory location.
// (It is called by -data.)
- (BOOL) writeDataToBytes:(void*)bytes available:(NSUInteger)availableSpace;

// Registration

+ (DWTWaveChunk*) chunkForData:(NSData*)data;
+ (void) registerChunkClasses;
// If a class wants more info about a chunk than just its type and length before deciding
// to handle it, it can override this method to examine the data and return NO if it wants
// to pass the buck. The base class implementation just returns YES.
// This way you can build multiple classes to handle different variants of a single chunk type.
+ (BOOL) canHandleChunkWithData:(NSData*)data;

// Utility
+ (NSArray*) processChunksInData:(NSData*)data;
// If this returns a value other than NSUIntegerMax, we will automatically process subchunks
// in -initWithData:, beginning at the given offset within the chunk data.
// Do not include this chunk's header type ID and size; this is an offset within the chunk data.
// For example, the base class returns 0.
+ (NSUInteger) autoProcessSubchunkOffset;

// Debugging
- (NSString*) additionalDebugInfo;

@end
