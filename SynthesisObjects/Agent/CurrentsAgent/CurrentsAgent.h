/*  
 *   by Sean Hill
 *   (c) 2003 All rights reserved.
 *   Usage and/or disclosure of this source code is restricted to authorized persons only.
 *
 *   CurrentsAgent.h created by shill on Thu 06-Jan-1999
 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMAgent.h>
#import <SynthesisCore/SIMNetworkStatistics.h>

#define SIM_FILENAME	@"Filename"
#define SIM_LAYER	@"Layer"
#define SIM_POSITION_X	@"Position_x"
#define SIM_POSITION_Y	@"Position_y"
#define SIM_TYPES	@"Types"
#define SIM_SAMPLEINTERVAL @"SampleInterval"

@interface CurrentsAgent : SIMAgent
{
    FILE *fout;
    NSArray *typesArray;
    NSString *filename;
    SIMPosition pos;
    NSString *currentType;
    float sampleInterval;
}

- (void) gatherData;

@end
