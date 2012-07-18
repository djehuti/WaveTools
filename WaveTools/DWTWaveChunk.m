//
//  DWTWaveChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/12/12.
//  Copyright 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveChunk.h"
#import "DWTWaveUnknownChunk.h"
#import "WaveToolsBundleUtils.h"
#import "WaveToolsLocalization.h"


#define kDWTWaveChunkHeaderSizeCompileTimeConstant 8
const NSUInteger kDWTWaveChunkHeaderSize = kDWTWaveChunkHeaderSizeCompileTimeConstant;
const NSUInteger kDWTWaveChunkIDSize = 4;


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
        // TODO: Validate that [chunkID length] == kDWTWaveChunkIDSize.
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
    return [mSubchunks getObjects:buffer range:inRange];
}

- (void) insertObject:(DWTWaveChunk*)object inSubchunksAtIndex:(NSUInteger)index
{
    object.parentChunk = self;
    [mSubchunks insertObject:object atIndex:index];
}

- (void) removeObjectFromSubchunksAtIndex:(NSUInteger)index
{
    DWTWaveChunk* exChunk = [mSubchunks objectAtIndex:index];
    exChunk.parentChunk = nil;
    [mSubchunks removeObjectAtIndex:index];
}

- (void) replaceObjectInSubchunksAtIndex:(NSUInteger)index withObject:(DWTWaveChunk*)object
{
    DWTWaveChunk* exChunk = [mSubchunks objectAtIndex:index];
    if (exChunk != object) {
        exChunk.parentChunk = nil;
        object.parentChunk = self;
        [mSubchunks replaceObjectAtIndex:index withObject:object];
    }
}

- (void) appendSubchunk:(DWTWaveChunk*)subchunk
{
    subchunk.parentChunk = self;
    [mSubchunks addObject:subchunk];
}

- (NSString*) moreInfo
{
    return DWTLocalizedString(@"RIFF Chunk", @"RIFF Chunk description");
}

#pragma mark Lifecycle

- (id) init
{
    static unsigned char s_emptyChunkData[kDWTWaveChunkHeaderSizeCompileTimeConstant] = { 'R', 'I', 'F', 'F', 0, 0, 0, 0 };
    
    NSMutableData* emptyChunkData = [NSMutableData dataWithBytesNoCopy:&s_emptyChunkData[0] length:sizeof(s_emptyChunkData) freeWhenDone:NO];
    return [self initWithData:emptyChunkData];
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
                // Gotta be enough data for at least one subchunk header in there.
                if (subchunkOffset != NSUIntegerMax && [data length] > (subchunkOffset + kDWTWaveChunkHeaderSize)) {
                    const void* bytes = [data bytes];
                    const void* base = bytes + subchunkOffset + kDWTWaveChunkHeaderSize;
                    NSData* subchunkData = [[NSData alloc] initWithBytesNoCopy:(void*)base length:(mChunkDataSize - subchunkOffset) freeWhenDone:NO];
                    NSArray* subchunks = [[self class] processChunksInData:subchunkData];
                    [subchunks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
                        ((DWTWaveChunk*)obj).parentChunk = self;
                    }];
                    [mSubchunks addObjectsFromArray:subchunks];
                    [subchunkData release];
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
    self.subchunks = nil;
    [super dealloc];
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
    NSLog(@"Loading chunk classes...");
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
            NSString* chunkClassName = (NSString*)[chunkDict objectForKey:chunkType];
            Class chunkClass = NSClassFromString(chunkClassName);
            if (chunkClass) {
                [self p_registerChunkClass:chunkClass forType:chunkType];
                NSLog(@"Registered class '%@' for chunk type '%@'.", chunkClassName, chunkType);
                ++chunkClassOK;
            } else {
                NSLog(@"Failed to load class '%@' for chunk type '%@'.", chunkClassName, chunkType);
            }
        }
    }
    NSLog(@"Registered %lu chunk classes (of %lu attempted) for %lu chunk types.", chunkClassOK, chunkClassCount, chunkTypeCount);
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
        const void* bytes = [data bytes];
        while (dataProcessed < ([data length] - kDWTWaveChunkHeaderSize)) {
            NSUInteger dataRemaining = [data length] - dataProcessed;
            const void* base = bytes + dataProcessed;
            // Create a temporary NSData that extends to the rest of the data.
            NSData* chunkData = [[NSData alloc] initWithBytesNoCopy:(void*)base length:dataRemaining freeWhenDone:NO];
            NSUInteger chunkDataLength = [self p_chunkLengthFromData:chunkData];
            if (chunkDataLength > dataRemaining) {
                NSLog(@"Error processing data stream: Chunk size %lu, with only %lu bytes remaining in stream.", chunkDataLength, dataRemaining);
                // Just stop now.
                break;
            }
            [chunkData release];
            // Release the temporary data and create one with the real chunk length.
            chunkData = [[NSData alloc] initWithBytesNoCopy:(void*)base length:(chunkDataLength + kDWTWaveChunkHeaderSize) freeWhenDone:NO];
            DWTWaveChunk* chunk = [self chunkForData:chunkData];
            [chunkData release];
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

+ (NSString*) read4CharFromData:(NSData*)data atOffset:(NSUInteger)offset
{
    NSString* result = nil;
    if ([data length] >= (offset + kDWTWaveChunkIDSize)) {
        const void* bytes = [data bytes];
        result = [[[NSString alloc] initWithBytes:(bytes + offset) length:kDWTWaveChunkIDSize encoding:NSISOLatin1StringEncoding] autorelease];
    }
    return result;
}

+ (uint32_t) readUint32FromData:(NSData*)data atOffset:(NSUInteger)offset
{
    uint32_t result = 0;
    if ([data length] >= (offset + sizeof(uint32_t))) {
        uint32_t* pUint = (uint32_t*)([data bytes] + offset);
#if __DARWIN_BYTE_ORDER == __DARWIN_LITTLE_ENDIAN
        result = *pUint;
#else
        result = OSSwapInt32(*pUint);
#endif
    }
    return result;
}

+ (uint16_t) readUint16FromData:(NSData*)data atOffset:(NSUInteger)offset
{
    uint16_t result = 0;
    if ([data length] >= (offset + sizeof(uint16_t))) {
        uint16_t* pUint = (uint16_t*)([data bytes] + offset);
#if __DARWIN_BYTE_ORDER == __DARWIN_LITTLE_ENDIAN
        result = *pUint;
#else
        result = OSSwapInt16(*pUint);
#endif
    }
    return result;
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
    return [self read4CharFromData:data atOffset:0];
}

+ (NSUInteger) p_chunkLengthFromData:(NSData*)data
{
    return (NSUInteger)[self readUint32FromData:data atOffset:kDWTWaveChunkIDSize];
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
