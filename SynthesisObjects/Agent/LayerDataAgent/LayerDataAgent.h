//
//  LayerDataAgent.h
//  SynthesisObjects
//
//  Created by Sean Hill on Tue May 25 2004.
//  Copyright (c) 2004. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <SynthesisCore/SIMAgent.h>
#import <SynthesisCore/SIMNetworkStatistics.h>

#define SIM_FILENAME	@"Filename"
#define SIM_LAYERS		@"Layers"
#define SIM_TYPE		@"Type"
#define SIM_DATATYPE	@"DataType"
#define SIM_VARIABLE	@"Variable"
#define SIM_SAMPLEINTERVAL @"SampleInterval"

#define SIM_DATATYPE_InputChannel		@"InputChannel"
#define SIM_DATATYPE_IntrinsicChannel   @"IntrinsicChannel"
#define SIM_DATATYPE_CellCompartment	@"CellCompartment"

@interface LayerDataAgent : SIMAgent 
{
    FILE *fout;
    NSString *filename;
    NSString *dataType;
	NSArray *patternArray;
    float sampleInterval;
}

- (void) gatherData;

@end
