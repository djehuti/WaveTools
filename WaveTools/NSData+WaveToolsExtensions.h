//
//  NSData+WaveToolsExtensions.h
//  WaveTools
//
//  Created by Ben Cox on 7/21/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface NSData (WaveToolsExtensions)

- (uint8_t) readUint8AtOffset:(NSUInteger)offset;
- (uint16_t) readUint16AtOffset:(NSUInteger)offset;
- (uint32_t) readUint32AtOffset:(NSUInteger)offset;
- (uint64_t) readUint64AtOffset:(NSUInteger)offset;
- (NSString*) read4CharAtOffset:(NSUInteger)offset;
- (NSString*) readNulTerminatedStringAtOffset:(NSUInteger)offset;
- (NSString*) readPascalStringAtOffset:(NSUInteger)offset;

@end


@interface NSMutableData (WaveToolsExtensions)

- (void) writeUint8:(uint8_t)value atOffset:(NSUInteger)offset;
- (void) writeUint16:(uint16_t)value atOffset:(NSUInteger)offset;
- (void) writeUint32:(uint32_t)value atOffset:(NSUInteger)offset;
- (void) writeUint64:(uint64_t)value atOffset:(NSUInteger)offset;
- (void) write4Char:(NSString*)value atOffset:(NSUInteger)offset;
- (void) writeNulTerminatedString:(NSString*)value atOffset:(NSUInteger)offset;
- (void) writePascalString:(NSString*)value atOffset:(NSUInteger)offset;

@end
