//
//  DWTAudioFileRegion.h
//  WaveTools
//
//  Created by Ben Cox on 7/26/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface DWTAudioFileRegion : NSObject <NSCopying, NSMutableCopying>

// These properties are expressed in samples from the start of the containing audio file.
@property (nonatomic, readonly, assign) NSUInteger start;
@property (nonatomic, readonly, assign) NSUInteger end;
@property (nonatomic, readonly, assign) NSUInteger length;
@property (nonatomic, readonly, retain) NSString* name;

- (id) initWithStart:(NSUInteger)start end:(NSUInteger)end name:(NSString*)name;

@end


@interface DWTMutableAudioFileRegion : DWTAudioFileRegion

// If you assign start > end, it will move end.
// If you assign end < start, it will move start.
@property (nonatomic, readwrite, assign) NSUInteger start;
@property (nonatomic, readwrite, assign) NSUInteger end;
@property (nonatomic, readwrite, retain) NSString* name;

@end
