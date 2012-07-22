//
//  DWTWaveLabeledTextChunk.m
//  WaveTools
//
//  Created by Ben Cox on 7/22/12.
//  Copyright (c) 2012 Ben Cox. All rights reserved.
//


#import "DWTWaveLabeledTextChunk.h"
#import "WaveToolsLocalization.h"


NSString* const kDWTWaveLabeledTextRegionPurposeID = @"rgn ";


#define kDWTWaveLabeledTextChunkCuePointIDOffset    0
#define kDWTWaveLabeledTextChunkLengthOffset        4
#define kDWTWaveLabeledTextChunkPurposeIDOffset     8
#define kDWTWaveLabeledTextChunkCountryOffset       12
#define kDWTWaveLabeledTextChunkLanguageOffset      14
#define kDWTWaveLabeledTextChunkDialectOffset       16
#define kDWTWaveLabeledTextChunkCodePageOffset      18
#define kDWTWaveLabeledTextChunkStringValueOffset   20
#define kDWTWaveLabeledTextChunkMinimumSize         20


@interface DWTWaveLabeledTextChunk ()
{
    uint32_t mCuePointID;
    uint32_t mLength;
    NSString* mPurposeID;
    uint16_t mCountry;
    uint16_t mLanguage;
    uint16_t mDialect;
    uint16_t mCodePage;
    NSString* mStringValue;
}

- (void) p_fixupData;

@end


@implementation DWTWaveLabeledTextChunk

- (uint32_t) cuePointID
{
    return mCuePointID;
}

- (void) setCuePointID:(uint32_t)cuePointID
{
    if (cuePointID != mCuePointID) {
        mCuePointID = cuePointID;
        [self p_fixupData];
    }
}

- (uint32_t) length
{
    return mLength;
}

- (void) setLength:(uint32_t)length
{
    if (length != mLength) {
        mLength = length;
        [self p_fixupData];
    }
}

- (NSString*) purposeID
{
    return mPurposeID;
}

- (void) setPurposeID:(NSString*)purposeID
{
    if (purposeID != mPurposeID) {
        [mPurposeID release];
        mPurposeID = [purposeID retain];
        [self p_fixupData];
    }
}

- (uint16_t) country
{
    return mCountry;
}

- (void) setCountry:(uint16_t)country
{
    if (country != mCountry) {
        mCountry = country;
        [self p_fixupData];
    }
}

- (uint16_t) language
{
    return mLanguage;
}

- (void) setLanguage:(uint16_t)language
{
    if (language != mLanguage) {
        mLanguage = language;
        [self p_fixupData];
    }
}

- (uint16_t) dialect
{
    return mDialect;
}

- (void) setDialect:(uint16_t)dialect
{
    if (dialect != mDialect) {
        mDialect = dialect;
        [self p_fixupData];
    }
}

- (uint16_t) codePage
{
    return mCodePage;
}

- (void) setCodePage:(uint16_t)codePage
{
    if (codePage != mCodePage) {
        mCodePage = codePage;
        [self p_fixupData];
    }
}

- (NSString*) stringValue
{
    return mStringValue;
}

- (void) setStringValue:(NSString*)stringValue
{
    if (stringValue != mStringValue) {
        [mStringValue release];
        mStringValue = [stringValue retain];
        [self p_fixupData];
    }
}

- (NSString*) moreInfo
{
    NSString* formatString = DWTLocalizedString(@"Cue Point ID: %lu, length %lu, purpose=\"%@\", name=\"%@\"", @"ltxt chunk moreInfo format string");
    return [NSString stringWithFormat:formatString, mCuePointID, mLength, mPurposeID, mStringValue ? mStringValue : DWTLocalizedString(@"(null)", @"null placeholder string")];
}

#pragma mark -

+ (NSString*) defaultChunkID
{
    return @"ltxt";
}

+ (NSData*) emptyChunkData
{
    static unsigned char s_emptyChunkBytes[] = {
        'l', 't', 'x', 't', 20, 0, 0, 0,
        1, 0, 0, 0, // Cue point 1 (not really valid on its own without a cue chunk)
        0, 0, 0, 0, // Length 0
        'r', 'g', 'n', ' ', // "rgn "
        0, 0, // country=0
        0, 0, // language=0
        0, 0, // dialect=0
        0, 0, // codePage=0
    };
    static NSData* s_emptyChunkData = nil;
    static dispatch_once_t s_emptyChunkOnce;
    dispatch_once(&s_emptyChunkOnce, ^{
        s_emptyChunkData = [[NSData alloc] initWithBytesNoCopy:&s_emptyChunkBytes[0] length:sizeof(s_emptyChunkBytes) freeWhenDone:NO];
    });
    return s_emptyChunkData;
}

+ (NSUInteger) autoProcessSubchunkOffset
{
    return NSUIntegerMax;
}

+ (BOOL) canHandleChunkWithData:(NSData*)data
{
    return ([data length] >= (kDWTWaveChunkHeaderSize + kDWTWaveLabeledTextChunkMinimumSize));
}

- (id) initWithData:(NSData*)data
{
    if ((self = [super initWithData:data])) {
        NSData* directData = self.directData;
        mCuePointID = [directData readUint32AtOffset:kDWTWaveLabeledTextChunkCuePointIDOffset];
        mLength     = [directData readUint32AtOffset:kDWTWaveLabeledTextChunkLengthOffset];
        mPurposeID  = [[directData read4CharAtOffset:kDWTWaveLabeledTextChunkPurposeIDOffset] retain];
        mCountry    = [directData readUint16AtOffset:kDWTWaveLabeledTextChunkCountryOffset];
        mLanguage   = [directData readUint16AtOffset:kDWTWaveLabeledTextChunkLanguageOffset];
        mDialect    = [directData readUint16AtOffset:kDWTWaveLabeledTextChunkDialectOffset];
        mCodePage   = [directData readUint16AtOffset:kDWTWaveLabeledTextChunkCodePageOffset];
        mStringValue = [[directData readNulTerminatedStringAtOffset:kDWTWaveLabeledTextChunkStringValueOffset] retain];
    }
    return self;
}

#pragma mark - Private Methods

- (void) p_fixupData
{
    NSMutableData* newData = [NSMutableData dataWithCapacity:kDWTWaveLabeledTextChunkMinimumSize];
    [newData writeUint32:mCuePointID atOffset:kDWTWaveLabeledTextChunkCuePointIDOffset];
    [newData writeUint32:mLength atOffset:kDWTWaveLabeledTextChunkLengthOffset];
    [newData write4Char:mPurposeID atOffset:kDWTWaveLabeledTextChunkPurposeIDOffset];
    [newData writeUint16:mCountry atOffset:kDWTWaveLabeledTextChunkCountryOffset];
    [newData writeUint16:mLanguage atOffset:kDWTWaveLabeledTextChunkLanguageOffset];
    [newData writeUint16:mDialect atOffset:kDWTWaveLabeledTextChunkDialectOffset];
    [newData writeUint16:mCodePage atOffset:kDWTWaveLabeledTextChunkCodePageOffset];
    [newData writeNulTerminatedString:mStringValue atOffset:kDWTWaveLabeledTextChunkStringValueOffset];
    self.directData = newData;
}

@end
