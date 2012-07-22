//
//  DWTWaveChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/12/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


// Found a bunch of useful info here: http://www.sonicspot.com/guide/wavefiles.html
// Including format of most of the chunks.

// Also here, for the text chunks in the LIST-INFO chunk:
// http://www.digitizationguidelines.gov/audio-visual/documents/core_doc_help.html


#import "DWTWaveChunk.h"
#import "DWTWaveUnknownChunk.h"
#import "WaveToolsBundleUtils.h"
#import "WaveToolsLocalization.h"
#import <CoreFoundation/CoreFoundation.h>
#import "NSData+WaveToolsExtensions.h"


const NSUInteger kDWTWaveChunkHeaderSize = 8;
const NSUInteger kDWTWaveChunkIDSize = 4;
const NSUInteger kDWTWaveChunkDataDumpLimit = 512;


#pragma mark Utility Registration

static NSMutableDictionary* s_registeredChunkClasses = nil;
static dispatch_once_t s_registeredChunkOnce;


#pragma mark -

@interface DWTWaveChunk ()
{
    NSString* mChunkID;
    NSUInteger mChunkDataSize;
    DWTWaveChunk* mParentChunk;
    NSMutableArray* mSubchunks;
    NSData* mDirectData;
}

+ (NSString*) p_chunkTypeFromData:(NSData*)data;
+ (NSUInteger) p_chunkLengthFromData:(NSData*)data;
+ (void) p_registerChunkClass:(Class)chunkClass forType:(NSString*)chunkType;

@end


#pragma mark -

@implementation DWTWaveChunk

#pragma mark Properties

@synthesize chunkDataSize = mChunkDataSize;
@synthesize parentChunk = mParentChunk;

- (NSString*) chunkID
{
    return mChunkID;
}

- (void) setChunkID:(NSString*)chunkID
{
    if (chunkID != mChunkID) {
        if (chunkID != nil && [chunkID length] != kDWTWaveChunkIDSize) {
            NSException* exc = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:DWTLocalizedString(@"Invalid chunk ID length.", @"Invalid chunk ID length.")
                                                     userInfo:[NSDictionary dictionary]];
            @throw exc;
        }
        [chunkID retain];
        [mChunkID release];
        mChunkID = chunkID;
    }
}

- (NSArray*) subchunks
{
    return [NSArray arrayWithArray:mSubchunks];
}

- (void) setSubchunks:(NSArray*)subchunks
{
    [mSubchunks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        DWTWaveChunk* chunk = (DWTWaveChunk*)obj;
        chunk.parentChunk = nil;
    }];
    [mSubchunks removeAllObjects];
    if (subchunks) {
        [subchunks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
            if (![obj isKindOfClass:[DWTWaveChunk class]]) {
                NSException* exc = [NSException exceptionWithName:NSInvalidArgumentException
                                                           reason:DWTLocalizedString(@"Invalid object in subchunk array.", @"Invalid object in subchunk array.")
                                                         userInfo:[NSDictionary dictionary]];
                @throw exc;
            }
            DWTWaveChunk* chunk = (DWTWaveChunk*)obj;
            chunk.parentChunk = self;
        }];
        [mSubchunks addObjectsFromArray:subchunks];
    }
    [self recalculateDataSize];
}

- (NSUInteger) countOfSubchunks
{
    return [mSubchunks count];
}

- (DWTWaveChunk*) objectInSubchunksAtIndex:(NSUInteger)index
{
    return (DWTWaveChunk*)[mSubchunks objectAtIndex:index];
}

- (void) getSubchunks:(DWTWaveChunk**)buffer range:(NSRange)inRange
{
    [mSubchunks getObjects:buffer range:inRange];
}

- (void) insertObject:(DWTWaveChunk*)object inSubchunksAtIndex:(NSUInteger)index
{
    object.parentChunk = self;
    [mSubchunks insertObject:object atIndex:index];
    [self recalculateDataSize];
}

- (void) removeObjectFromSubchunksAtIndex:(NSUInteger)index
{
    DWTWaveChunk* exChunk = [mSubchunks objectAtIndex:index];
    exChunk.parentChunk = nil;
    [mSubchunks removeObjectAtIndex:index];
    [self recalculateDataSize];
}

- (void) replaceObjectInSubchunksAtIndex:(NSUInteger)index withObject:(DWTWaveChunk*)object
{
    DWTWaveChunk* exChunk = [mSubchunks objectAtIndex:index];
    if (exChunk != object) {
        exChunk.parentChunk = nil;
        object.parentChunk = self;
        [mSubchunks replaceObjectAtIndex:index withObject:object];
        [self recalculateDataSize];
    }
}

- (void) appendSubchunk:(DWTWaveChunk*)subchunk
{
    subchunk.parentChunk = self;
    [mSubchunks addObject:subchunk];
    [self recalculateDataSize];
}

- (NSString*) moreInfo
{
    return DWTLocalizedString(@"RIFF Chunk", @"RIFF Chunk description");
}

- (NSData*) directData
{
    return mDirectData;
}

- (void) setDirectData:(NSData*)directData
{
    if (directData != mDirectData) {
        [mDirectData release];
        mDirectData = [directData retain];
        [self recalculateDataSize];
    }
}

- (NSString*) dataDump
{
    NSMutableString* dumpString = [[[NSMutableString alloc] init] autorelease];
    NSUInteger dataIndex = 0;
    NSUInteger dumpLimit = MIN([mDirectData length], kDWTWaveChunkDataDumpLimit);
    if (dumpLimit > 0) {
        unsigned char const* dataBytes = (unsigned char const*)[mDirectData bytes];
        while (dataIndex < dumpLimit) {
            if ((dataIndex % 16) == 0) {
                [dumpString appendFormat:@"%08lx:", dataIndex];
            } else if ((dataIndex % 8) == 0) {
                [dumpString appendString:@" "];
            }
            [dumpString appendFormat:@" %02x", dataBytes[dataIndex]];
            if ((dataIndex % 16) == 15 && dataIndex < (dumpLimit - 1)) {
                [dumpString appendString:@"\n"];
            }
            ++dataIndex;
        }
        [dumpString appendString:@"\n"];
    }
    return dumpString;
}

#pragma mark - Lifecycle

+ (NSString*) defaultChunkID
{
    return @"RIFF";
}

+ (NSData*) emptyChunkData
{
    unsigned char emptyChunkBytes[] = { 'R', 'I', 'F', 'F', 0, 0, 0, 0 };
    NSData* emptyChunkData = nil;
    [[[self defaultChunkID] dataUsingEncoding:NSISOLatin1StringEncoding] getBytes:&emptyChunkBytes[0] length:kDWTWaveChunkIDSize];
    emptyChunkData = [NSData dataWithBytes:&emptyChunkBytes[0] length:sizeof(emptyChunkBytes)];
    return emptyChunkData;
}

- (id) init
{
    return [self initWithData:[[self class] emptyChunkData]];
}

- (id) initWithData:(NSData*)data
{
    if ((self = [super init])) {
        if ([data length] < kDWTWaveChunkHeaderSize) {
            [self release];
            self = nil;
        } else {
            mChunkDataSize = [[self class] p_chunkLengthFromData:data];
            if ([data length] != mChunkDataSize + kDWTWaveChunkHeaderSize) {
                [self release];
                self = nil;
            } else {
                mChunkID = [[[self class] p_chunkTypeFromData:data] retain];
                mSubchunks = [[NSMutableArray alloc] init];
                NSUInteger subchunkOffset = [[self class] autoProcessSubchunkOffset];
                if (subchunkOffset == NSUIntegerMax) {
                    if (mChunkDataSize > 0) {
                        NSRange subdataRange = NSMakeRange(kDWTWaveChunkHeaderSize, mChunkDataSize);
                        mDirectData = [[data subdataWithRange:subdataRange] retain];
                    }
                } else {
                    // Gotta be enough data for at least one subchunk header in there.
                    if ([data length] > (subchunkOffset + kDWTWaveChunkHeaderSize)) {
                        NSRange subdataRange = NSMakeRange(kDWTWaveChunkHeaderSize, subchunkOffset);
                        mDirectData = [[data subdataWithRange:subdataRange] retain];
                        NSData* subchunkData = [data subdataWithRange:NSMakeRange(kDWTWaveChunkHeaderSize + subchunkOffset, mChunkDataSize - subchunkOffset)];
                        NSArray* subchunks = [[self class] processChunksInData:subchunkData];
                        [subchunks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
                            ((DWTWaveChunk*)obj).parentChunk = self;
                        }];
                        [mSubchunks addObjectsFromArray:subchunks];
                    } else if (mChunkDataSize > 0) {
                        // We're not making any subchunks. Just grab the data as direct.
                        NSRange subdataRange = NSMakeRange(kDWTWaveChunkHeaderSize, mChunkDataSize);
                        mDirectData = [[data subdataWithRange:subdataRange] retain];
                    }
                }
            }
        }
    }
    return self;
}

- (void) dealloc
{
    [mChunkID release];
    mChunkID = nil;
    mChunkDataSize = 0;
    [mSubchunks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        DWTWaveChunk* chunk = (DWTWaveChunk*)obj;
        chunk.parentChunk = nil;
    }];
    [mSubchunks release];
    mSubchunks = nil;
    [mDirectData release];
    mDirectData = nil;
    [super dealloc];
}

#pragma mark - Misc.

- (void) recalculateDataSize
{
    NSUInteger newSize = [mDirectData length];
    for (DWTWaveChunk* chunk in mSubchunks) {
        newSize += kDWTWaveChunkHeaderSize + [chunk chunkDataSize];
    }
    mChunkDataSize = newSize;
    if (mParentChunk) {
        [mParentChunk recalculateDataSize];
    }
}

- (NSData*) data
{
    [self recalculateDataSize];
    NSUInteger dataLength = kDWTWaveChunkHeaderSize + mChunkDataSize;
    NSMutableData* data = [[NSMutableData alloc] initWithLength:dataLength];
    if (![self writeDataToBytes:[data mutableBytes] available:dataLength]) {
        [data release];
        data = nil;
    }
    return [data autorelease];
}

- (BOOL) writeDataToBytes:(void *)bytes available:(NSUInteger)availableSpace
{
    BOOL result = NO;
    [self recalculateDataSize];
    if ((availableSpace >= kDWTWaveChunkHeaderSize + mChunkDataSize) && (mChunkDataSize < UINT32_MAX)) {
        void* buffer = bytes;
        // 1. Write chunk ID to data.
        NSData* chunkIDData = [mChunkID dataUsingEncoding:NSISOLatin1StringEncoding];
        if ([chunkIDData length] == kDWTWaveChunkIDSize) {
            [chunkIDData getBytes:buffer length:kDWTWaveChunkIDSize];
            buffer += kDWTWaveChunkIDSize;
            availableSpace -= kDWTWaveChunkIDSize;
            uint32_t chunkLength = (uint32_t)mChunkDataSize;
            *((uint32_t*)buffer) = CFSwapInt32HostToLittle(chunkLength);
            buffer += sizeof(uint32_t);
            availableSpace -= sizeof(uint32_t);
            [mDirectData getBytes:buffer length:availableSpace];
            buffer += [mDirectData length];
            availableSpace -= [mDirectData length];
            BOOL ok = YES;
            for (DWTWaveChunk* subchunk in mSubchunks) {
                ok = [subchunk writeDataToBytes:buffer available:availableSpace];
                if (!ok) break;
                NSUInteger bytesWritten = kDWTWaveChunkHeaderSize + [subchunk chunkDataSize];
                buffer += bytesWritten;
                availableSpace -= bytesWritten;
            }
            if (ok) {
                result = YES;
            }
        }
    }
    return result;
}

#pragma mark - Registration

+ (DWTWaveChunk*) chunkForData:(NSData*)data
{
    DWTWaveChunk* result = nil;
    NSString* chunkType = [self p_chunkTypeFromData:data];
    if (chunkType) {
        Class chunkClass = Nil;
        NSArray* classesForType = [s_registeredChunkClasses objectForKey:chunkType];
        if (classesForType) {
            for (Class candidateClass in classesForType) {
                if ([candidateClass canHandleChunkWithData:data]) {
                    chunkClass = candidateClass;
                    break;
                }
            }
        }
        if (chunkClass == Nil) {
            chunkClass = [DWTWaveUnknownChunk class];
        }
        result = [[[chunkClass alloc] initWithData:data] autorelease];
    }
    return result;
}

+ (void) registerChunkClasses
{
    //NSLog(@"Loading chunk classes...");
    NSUInteger chunkTypeCount = 0;
    NSUInteger chunkClassCount = 0;
    NSUInteger chunkClassOK = 0;
    NSString* dictPath = [DWTWaveToolsBundle() pathForResource:@"DWTWaveChunkClasses" ofType:@"plist"];
    NSDictionary* chunkDict = [NSDictionary dictionaryWithContentsOfFile:dictPath];
    for (id<NSObject> chunkTypeKey in [chunkDict allKeys]) {
        if (![chunkTypeKey isKindOfClass:[NSString class]]) {
            NSLog(@"Bad key %@ in class dictionary", chunkTypeKey);
            continue;
        }
        NSString* chunkType = (NSString*)chunkTypeKey;
        ++chunkTypeCount;
        id<NSObject> chunkMapObject = [chunkDict objectForKey:chunkTypeKey];
        NSArray* chunkClasses = nil;
        if ([chunkMapObject isKindOfClass:[NSArray class]]) {
            chunkClasses = (NSArray*)chunkMapObject;
        }
        else if ([chunkMapObject isKindOfClass:[NSString class]]) {
            chunkClasses = [NSArray arrayWithObject:chunkMapObject];
        }
        else {
            NSLog(@"Bad object %@ in class dictionary for chunk type '%@'", chunkMapObject, chunkType);
            continue;
        }
        for (id<NSObject> chunkClassObject in chunkClasses) {
            if (![chunkClassObject isKindOfClass:[NSString class]]) {
                NSLog(@"Bad object %@ in class name list for chunk type '%@'", chunkClassObject, chunkType);
                continue;
            }
            ++chunkClassCount;
            NSString* chunkClassName = (NSString*)chunkClassObject;
            Class chunkClass = NSClassFromString(chunkClassName);
            if (chunkClass) {
                [self p_registerChunkClass:chunkClass forType:chunkType];
                //NSLog(@"Registered class '%@' for chunk type '%@'.", chunkClassName, chunkType);
                ++chunkClassOK;
            } else {
                NSLog(@"Failed to load class '%@' for chunk type '%@'.", chunkClassName, chunkType);
            }
        }
    }
    //NSLog(@"Registered %lu chunk classes (of %lu attempted) for %lu chunk types.", chunkClassOK, chunkClassCount, chunkTypeCount);
}

+ (BOOL) canHandleChunkWithData:(NSData*)data
{
    return YES;
}

#pragma mark - Utility

+ (NSArray*) processChunksInData:(NSData*)data
{
    NSMutableArray* chunks = [NSMutableArray array];
    NSUInteger dataProcessed = 0;
    if ([data length] >= kDWTWaveChunkHeaderSize) {
        while (dataProcessed < ([data length] - kDWTWaveChunkHeaderSize)) {
            NSUInteger dataRemaining = [data length] - dataProcessed;
            // Create a temporary NSData that extends to the rest of the data.
            NSData* chunkData = [data subdataWithRange:NSMakeRange(dataProcessed, dataRemaining)];
            NSUInteger chunkDataLength = [self p_chunkLengthFromData:chunkData];
            if (chunkDataLength > dataRemaining) {
                NSLog(@"Error processing data stream: Chunk size %lu, with only %lu bytes remaining in stream.", chunkDataLength, dataRemaining);
                // Just stop now.
                break;
            }
            // Now create one with the real chunk length.
            chunkData = [data subdataWithRange:NSMakeRange(dataProcessed, chunkDataLength + kDWTWaveChunkHeaderSize)];
            DWTWaveChunk* chunk = [self chunkForData:chunkData];
            [chunks addObject:chunk];
            dataProcessed += (((chunkDataLength + kDWTWaveChunkHeaderSize) + 1) & ~1);
        }
    }
    return chunks;
}

+ (NSUInteger) autoProcessSubchunkOffset
{
    return 4;
}

#pragma mark - Debugging

- (NSString*) descriptionWithIndent:(NSUInteger)indent
{
    NSString* indentString = [@"" stringByPaddingToLength:indent withString:@" " startingAtIndex:0];
    NSMutableString* description = [NSMutableString stringWithFormat:@"%@<%@ %p>: %@ (%lu bytes, %lu subchunks)%@",
                                    indentString, NSStringFromClass([self class]), self,
                                    mChunkID, mChunkDataSize, [mSubchunks count],
                                    [self additionalDebugInfo]];
    if ([mSubchunks count] > 0) {
        [description appendFormat:@"\n%@Subchunks: {\n", indentString];
        for (DWTWaveChunk* chunk in mSubchunks) {
            [description appendFormat:@"%@\n", [chunk descriptionWithIndent:indent+2]];
        }
        [description appendFormat:@"%@}", indentString];
    }
    return description;
}

- (NSString*) description
{
    return [self descriptionWithIndent:0];
}

- (NSString*) additionalDebugInfo
{
    return @"";
}

#pragma mark - Private Methods

+ (NSString*) p_chunkTypeFromData:(NSData*)data
{
    return [data read4CharAtOffset:0];
}

+ (NSUInteger) p_chunkLengthFromData:(NSData*)data
{
    return [data readUint32AtOffset:kDWTWaveChunkIDSize];
}

+ (void) p_registerChunkClass:(Class)chunkClass forType:(NSString*)chunkType
{
    dispatch_once(&s_registeredChunkOnce, ^{
        s_registeredChunkClasses = [[NSMutableDictionary alloc] init];
    });
    NSMutableArray* classesForType = [s_registeredChunkClasses objectForKey:chunkType];
    if (!classesForType) {
        classesForType = [[NSMutableArray alloc] init];
        [s_registeredChunkClasses setObject:classesForType forKey:chunkType];
    }
    if (![classesForType containsObject:chunkClass]) {
        [classesForType addObject:chunkClass];
    } else {
        NSLog(@"Duplicate class %@ specified for chunk type '%@'", NSStringFromClass(chunkClass), chunkType);
    }
}

@end
