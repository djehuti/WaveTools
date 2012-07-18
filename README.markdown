# WaveTools

WaveTools is a framework for manipulating audio files; WAVE files (.wav) in particular.

## DWTWaveChunk

The `DWTWaveChunk` family of classes provides information about the chunks
in a RIFF WAVE file. To read a WAVE file, use

    NSData* fileData = [NSData dataWithContentsOfFile:@"myfile.wav"];
    NSArray* chunks = [[DWTWaveChunk class] processChunksInData:fileData];
    NSAssert([chunks count] == 1, @"A valid WAV file has only one chunk");
    DWTWaveChunk* firstChunk = [chunks objectAtIndex:0];
    NSAssert([firstChunk.chunkID isEqualToString:@"RIFF"], @"expected a RIFF chunk");

You can then use the RIFF chunk (which is `firstChunk` in the above code
snippet) and its subchunks to explore the contents of the WAVE file.

## Math functions

There are a few miscellaneous math functions available in `DWTMath.h`.

## Future Functionality

I plan to add sample rate conversion, dithering, and more chunk types.
The goal of the chunk types is to be able to read region definitions from
the file, and possibly adjust them when sample rate converting the file.
