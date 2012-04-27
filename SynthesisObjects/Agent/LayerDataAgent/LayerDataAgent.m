//
//  LayerDataAgent.m
//  SynthesisObjects
//
//  Created by Sean Hill on Tue May 25 2004.
//  Copyright (c) 2004. All rights reserved.
//

#import "LayerDataAgent.h"
#import <SynthesisCore/SIMNetworkInfo.h>
#import <SynthesisCore/SIMNetworkStatistics.h>


@implementation LayerDataAgent

- init
{
    [super init];
    fout = (FILE *)nil;
    return self;
}

- (void) gatherData
{
	NSData *data = nil;
    NSString *patternString;
    NSEnumerator *patternEnum = [patternArray objectEnumerator];
    float t = [network time];
    float dt = [network dt];
    size_t confirmWrite = 0;

    if(!fout)NSLog(@"ERROR: Data file not open.");
    if(0==fmod(floor(t/dt+.5)*dt,sampleInterval*dt)) {
		confirmWrite = fwrite(&t,sizeof(float),1,fout);
        while(patternString = [patternEnum nextObject]){
		//NSLog(patternString);
            if([dataType isEqual:SIM_DATATYPE_InputChannel]){
				data = [[network summedStateVariablesForModelOfType:SIM_InputChannelType matchingPattern:patternString] retain];
            }
            else if([dataType isEqual:SIM_DATATYPE_IntrinsicChannel]){
				data = [[network summedStateVariablesForModelOfType:SIM_IntrinsicChannelType matchingPattern:patternString] retain];
            }
            else if([dataType isEqual:SIM_DATATYPE_CellCompartment]){
				data = [[network summedStateVariablesForModelOfType:SIM_CellCompartmentType matchingPattern:patternString] retain];
            }
			if(!data) return;
			const float *bytes = [data bytes];
			//NSLog(@"%d\n",[data length]/sizeof(float));
			confirmWrite = fwrite(bytes,sizeof(float),[data length]/sizeof(float),fout);
			[data release];
        }
    }
    fflush(fout);
}

- (void) updateParameters
{
    [super updateParameters];

    if(filename)[filename autorelease];
    filename = [[self filePathForKey:@"Filename"] retain];

    patternArray = [self objectForKey:@"Pattern"];
		
    dataType = [self objectForKey:SIM_DATATYPE];

    sampleInterval = [self floatForKey:SIM_SAMPLEINTERVAL];
    if(0.0==sampleInterval) {
        sampleInterval = 1.0;
    }

}

- (void) startAgent
{
    [super startAgent];

	[self createDataDirectory];

    if(fout){fclose(fout);fout = (FILE *)nil;}
    if(!(fout = fopen([filename UTF8String],"ab"))){
        NSLog(@"Could not open file %@.",filename);
    }
}

- (void) stopAgent
{
    [super stopAgent];

    if(fout){fclose(fout);fout = (FILE *)nil;}
}

@end
