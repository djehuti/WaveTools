//
//  NSData+WaveToolsExtensions.m
//  WaveTools
//
//  Created by Ben Cox on 7/21/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "NSData+WaveToolsExtensions.h"
#import <WaveTools/WaveTools.h>
#import "WaveToolsLocalization.h"
#import <CoreFoundation/CoreFoundation.h>


static void DWTThrowRangeException(NSString* reason, NSDictionary* userInfo)
{
    NSException* exc = [NSException exceptionWithName:NSRangeException
                                               reason:reason
                                             userInfo:userInfo];
    @throw exc;
}

static void DWTNotEnoughData(void)
{
    NSString* reason = DWTLocalizedString(@"Not enough data", @"Not enough data");
    DWTThrowRangeException(reason, [NSDictionary dictionary]);
}

#pragma mark -

@implementation NSData (WaveToolsExtensions)

- (uint8_t) readUint8AtOffset:(NSUInteger)offset
{
    if ([self length] < (offset + sizeof(uint8_t))) {
        DWTNotEnoughData();
    }
    uint8_t* valuePointer = (uint8_t*) ([self bytes] + offset);
    return *valuePointer;
}

- (uint16_t) readUint16AtOffset:(NSUInteger)offset
{
    if ([self length] < (offset + sizeof(uint16_t))) {
        DWTNotEnoughData();
    }
    uint16_t* valuePointer = (uint16_t*) ([self bytes] + offset);
    return CFSwapInt16LittleToHost(*valuePointer);
}

- (uint32_t) readUint32AtOffset:(NSUInteger)offset
{
    if ([self length] < (offset + sizeof(uint32_t))) {
        DWTNotEnoughData();
    }
    uint32_t* valuePointer = (uint32_t*) ([self bytes] + offset);
    return CFSwapInt32LittleToHost(*valuePointer);
}

- (uint64_t) readUint64AtOffset:(NSUInteger)offset
{
    if ([self length] < (offset + sizeof(uint64_t))) {
        DWTNotEnoughData();
    }
    uint64_t* valuePointer = (uint64_t*) ([self bytes] + offset);
    return CFSwapInt64LittleToHost(*valuePointer);
}

- (NSString*) read4CharAtOffset:(NSUInteger)offset
{
    if ([self length] < (offset + kDWTWaveChunkIDSize)) {
        DWTNotEnoughData();
    }
    return [[[NSString alloc] initWithBytes:([self bytes] + offset) length:kDWTWaveChunkIDSize encoding:NSISOLatin1StringEncoding] autorelease];
}

- (NSString*) readNulTerminatedStringAtOffset:(NSUInteger)offset
{
    if ([self length] < offset) {
        DWTNotEnoughData();
    }
    if ([self length] > (offset + 1)) {
        NSData* subdata = [self subdataWithRange:NSMakeRange(offset, [self length] - 1 - offset)];
        return [[[NSString alloc] initWithData:subdata encoding:NSISOLatin1StringEncoding] autorelease];
    } else {
        return @"";
    }
}

- (NSString*) readPascalStringAtOffset:(NSUInteger)offset
{
    uint8_t stringLength = [self readUint8AtOffset:offset];
    if (stringLength > 0) {
        if ([self length] < (offset + sizeof(uint8_t) + stringLength)) {
            DWTNotEnoughData();
        }
        NSData* subdata = [self subdataWithRange:NSMakeRange(offset + sizeof(uint8_t), stringLength)];
        return [[[NSString alloc] initWithData:subdata encoding:NSISOLatin1StringEncoding] autorelease];
    } else {
        return @"";
    }
}

@end

#pragma mark -

@implementation NSMutableData (WaveToolsExtensions)

- (void) writeUint8:(uint8_t)value atOffset:(NSUInteger)offset
{
    if ([self length] < (offset + sizeof(uint8_t))) {
        [self setLength:(offset + sizeof(uint8_t))];
    }
    [self replaceBytesInRange:NSMakeRange(offset, sizeof(uint8_t)) withBytes:&value length:sizeof(uint8_t)];
}

- (void) writeUint16:(uint16_t)value atOffset:(NSUInteger)offset
{
    if ([self length] < (offset + sizeof(uint16_t))) {
        [self setLength:(offset + sizeof(uint16_t))];
    }
    uint16_t littleEndianValue = CFSwapInt16HostToLittle(value);
    [self replaceBytesInRange:NSMakeRange(offset, sizeof(uint16_t)) withBytes:&littleEndianValue length:sizeof(uint16_t)];
}

- (void) writeUint32:(uint32_t)value atOffset:(NSUInteger)offset
{
    if ([self length] < (offset + sizeof(uint32_t))) {
        [self setLength:(offset + sizeof(uint32_t))];
    }
    uint32_t littleEndianValue = CFSwapInt32HostToLittle(value);
    [self replaceBytesInRange:NSMakeRange(offset, sizeof(uint32_t)) withBytes:&littleEndianValue length:sizeof(uint32_t)];
}

- (void) writeUint64:(uint64_t)value atOffset:(NSUInteger)offset
{
    if ([self length] < (offset + sizeof(uint64_t))) {
        [self setLength:(offset + sizeof(uint64_t))];
    }
    uint64_t littleEndianValue = CFSwapInt64HostToLittle(value);
    [self replaceBytesInRange:NSMakeRange(offset, sizeof(uint64_t)) withBytes:&littleEndianValue length:sizeof(uint64_t)];
}

- (void) write4Char:(NSString*)value atOffset:(NSUInteger)offset
{
    if ([self length] < (offset + kDWTWaveChunkIDSize)) {
        [self setLength:(offset + kDWTWaveChunkIDSize)];
    }
    NSRange replaceRange = NSMakeRange(offset, kDWTWaveChunkIDSize);
    if ([value length] == 0) {
        [self resetBytesInRange:replaceRange];
    } else {
        NSData* stringData = [value dataUsingEncoding:NSISOLatin1StringEncoding];
        if ([stringData length] != kDWTWaveChunkIDSize) {
            NSException* exc = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:DWTLocalizedString(@"Invalid chunk ID length.", @"Invalid chunk ID length.")
                                                     userInfo:[NSDictionary dictionary]];
            @throw exc;
        }
        [self replaceBytesInRange:replaceRange withBytes:[stringData bytes] length:kDWTWaveChunkIDSize];
    }
}

- (void) writeNulTerminatedString:(NSString*)value atOffset:(NSUInteger)offset
{
    NSData* stringData = [value dataUsingEncoding:NSISOLatin1StringEncoding];
    [self setLength:offset];
    [self appendData:stringData];
    unsigned char zero = 0;
    [self appendBytes:&zero length:1];
}

- (void) writePascalString:(NSString*)value atOffset:(NSUInteger)offset
{
    NSData* stringData = [value dataUsingEncoding:NSISOLatin1StringEncoding];
    if ([stringData length] > UINT8_MAX) {
        NSException* exc = [NSException exceptionWithName:NSInvalidArgumentException
                                                   reason:DWTLocalizedString(@"String too long to be encoded as a Pascal string.", @"Pascal string >255 bytes message.")
                                                 userInfo:[NSDictionary dictionary]];
        @throw exc;
    }
    uint8_t stringLength = [stringData length];
    if ([self length] < (offset + sizeof(uint8_t) + stringLength)) {
        [self setLength:(offset + sizeof(uint8_t) + stringLength)];
    }
    [self writeUint8:stringLength atOffset:offset];
    [self replaceBytesInRange:NSMakeRange(offset + sizeof(uint8_t), stringLength) withBytes:[stringData bytes] length:stringLength];
}

@end
