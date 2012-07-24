//
//  DWTWaveRegnChunk.h
//  WaveTools
//
//  Created by Ben Cox on 7/22/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import <WaveTools/WaveTools.h>


// NOTE: We only support reading 'regn' chunks, not writing.


@interface DWTWaveRegnRegion : NSObject

// All of these are expressed as sample index from the start of the file.
@property (nonatomic, readonly, assign) uint64_t start;
@property (nonatomic, readonly, assign) uint64_t end;
@property (nonatomic, readonly, assign) uint64_t syncPoint;
// These are expressed as sample index relative to 00:00:00.00.
// I.e., 00:00:02.00 in a 44.1kHz file, is expressed as 88200.
@property (nonatomic, readonly, assign) uint64_t userTimeStamp;
@property (nonatomic, readonly, assign) uint64_t originalTimeStamp;
@property (nonatomic, readonly, retain) NSString* name;

- (id) initWithData:(NSData*)data; // DI.

@end

#pragma mark -

@interface DWTWaveRegnChunk : DWTWaveChunk

@property (nonatomic, readonly, retain) NSArray* regions;

// regions property accessor methods.

- (NSUInteger) countOfRegions;
- (DWTWaveRegnRegion*) objectInRegionsAtIndex:(NSUInteger)index;
- (void) getRegions:(DWTWaveRegnRegion**)buffer range:(NSRange)inRange;

@end
