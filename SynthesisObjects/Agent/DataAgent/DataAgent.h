/*  
 *   by Sean Hill
 *   (c) 2003 All rights reserved.
 *   Usage and/or disclosure of this source code is restricted to authorized persons only.
 *
 *   DataAgent.h created by shill on Thu 06-Jan-1999
 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMAgent.h>
#import <SynthesisCore/SIMNetworkStatistics.h>

#define SIM_FILENAME	@"Filename"
#define SIM_LAYERS	@"Layers"
#define SIM_POSITION_X	@"Position_x"
#define SIM_POSITION_Y	@"Position_y"
#define SIM_SIZE	@"Size"
#define SIM_RADIUS	@"Radius"
#define SIM_TYPE	@"Type"
#define SIM_SAMPLEINTERVAL @"Sampleinterval"

#define SIM_DATATYPE_AverageMembranePotential	@"AverageMembranePotential"
#define SIM_DATATYPE_AverageFieldPotential	@"AverageFieldPotential"
#define SIM_DATATYPE_ActualMembranePotential	@"ActualMembranePotential"
#define SIM_DATATYPE_SummedChannelCurrent	@"SummedChannelCurrent"

@interface DataAgent : SIMAgent
{
    FILE *fout;
    NSMutableDictionary *posDictionary;
    NSArray *layerArray;
    NSString *filename;
    NSString *type;
    SIMPosition pos;
    float radius;
    float sampleinterval;
}

- (void) gatherData;

@end
