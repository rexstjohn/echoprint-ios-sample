//
//  FPGenerator.m
//  Echoprint
//
//  Created by Виктор Полевой on 04.03.14.
//
//

#import "FPGenerator.h"

@implementation FPGenerator

+ (NSString*) generateFingerprintForFile:(NSString*)fullFileName
{
    char *filename = (char*) [fullFileName cStringUsingEncoding:NSASCIIStringEncoding];
    CFURLRef audioFileURL = CFURLCreateFromFileSystemRepresentation(NULL,(const UInt8*)filename, strlen(filename), false);
	ExtAudioFileRef outExtAudioFile;
	int err = ExtAudioFileOpenURL(audioFileURL, &outExtAudioFile);
	if (err) {
        NSLog(@"open failed");
	}
    
	
	CAStreamBasicDescription clientFormat;
	clientFormat.mSampleRate = 11025;
	clientFormat.mFormatID = kAudioFormatLinearPCM;
	clientFormat.mChannelsPerFrame = 2;
	clientFormat.mBitsPerChannel = 32;
	clientFormat.mBytesPerPacket = clientFormat.mBytesPerFrame = 4 * clientFormat.mChannelsPerFrame;
	clientFormat.mFramesPerPacket = 1;
	clientFormat.mFormatFlags =  kAudioFormatFlagsNativeFloatPacked;// | kAudioFormatFlagIsNonInterleaved;
	
	int size = sizeof(clientFormat);
	err = ExtAudioFileSetProperty(outExtAudioFile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat);
	if (err)
        NSLog(@"err on set format %d", err);
	
	int seconds_to_decode = 30;
	int bytes_for_bigbuf = sizeof(float)*11025*seconds_to_decode;
	float *bigBuf = (float*) malloc(bytes_for_bigbuf);
	if(bigBuf == NULL) {
        NSLog(@"Error mallocing bigbuf");
	}
	NSUInteger totalFrames = 0;
	while (1) {
		AudioBufferList fillBufList;
		fillBufList.mNumberBuffers = 1;
		UInt32 bufferByteSize = 11025 * 4 * 2; // 1s of audio
		char srcBuffer[bufferByteSize];
		UInt32 numFrames = clientFormat.BytesToFrames(bufferByteSize); // (bufferByteSize / clientFormat.mBytesPerFrame);
        
		fillBufList.mBuffers[0].mNumberChannels = clientFormat.NumberChannels();
		fillBufList.mBuffers[0].mDataByteSize = bufferByteSize;
		fillBufList.mBuffers[0].mData = srcBuffer;
		err = ExtAudioFileRead(outExtAudioFile, &numFrames, &fillBufList);
		if (err) {
            NSLog(@"err on read %d", err);
			totalFrames = 0;
			break;
		}
		if (!numFrames)
			break;
		
		float mono_version[numFrames];
		float* float_buf = (float*) fillBufList.mBuffers[0].mData;
		for(int i=0;i<numFrames;i++)
			mono_version[i] = (float_buf[i*2] + float_buf[i*2 + 1]) / 2.0;
		
		int bytesLeftInBuffer = bytes_for_bigbuf - (totalFrames * sizeof(float));
		
		if (numFrames * sizeof(float) > bytesLeftInBuffer) {
			memcpy(bigBuf + totalFrames, mono_version, bytesLeftInBuffer);
			totalFrames = totalFrames + (bytesLeftInBuffer/4);
			break;
		} else {
			memcpy(bigBuf + totalFrames, mono_version, numFrames * sizeof(float));
			totalFrames = totalFrames + numFrames;
		}
	}
    
    NSString *fingerprint;
	if(totalFrames > 11025) {
        NSLog(@"Doing codegen on %d samples...", totalFrames);
        
		CodeGenWrapper *wrapper = [[CodeGenWrapper alloc] initWithPCM:bigBuf numberOfSamples:totalFrames startOffset:0];
        
        fingerprint = [wrapper codeString];
        
        NSLog(@"Done with codegen");
	}
	free(bigBuf);
    
	return fingerprint;
}
@end
