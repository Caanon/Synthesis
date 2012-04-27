/*  
 *   by Sean Hill
 *   (c) 2003 All rights reserved.
 *   Usage and/or disclosure of this source code is restricted to authorized persons only.
 *
 *   CellDataAgent.h created by shill on Thu 06-Jan-1999
 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMAgent.h>
#import <SynthesisCore/SIMNetworkStatistics.h>

#define SIM_FILENAME	@"Filename"
#define SIM_MODEL	@"Model"
#define SIM_VARIABLE	@"Variable"
#define SIM_POSITION_X	@"Position_x"
#define SIM_POSITION_Y	@"Position_y"
#define SIM_LAYER	@"Layer"
#define SIM_RADIUS	@"Radius"
#define SIM_DATATYPE	@"DataType"
#define SIM_BUFFERSIZE	@"BufferSize"
#define SIM_UPDATEINTERVAL @"UpdateInterval"
#define SIM_SAVETOFILE	@"SaveToFile"

#define SIM_DATATYPE_AverageMembranePotential	@"AverageMembranePotential"
#define SIM_DATATYPE_AverageFieldPotential	@"AverageFieldPotential"
#define SIM_DATATYPE_MembranePotential		@"MembranePotential"
#define SIM_DATATYPE_SummedChannelCurrent	@"SummedChannelCurrent"
#define SIM_DATATYPE_CellModelVariable		@"CellModelVariable"
#define SIM_DATATYPE_ChannelModelVariable	@"ChannelModelVariable"

typedef enum { 
    SIM_AverageMembranePotential,
    SIM_AverageFieldPotential,
    SIM_MembranePotential,
    SIM_SummedChannelCurrent,
    SIM_ChannelModelVariable, 
    SIM_CellModelVariable 
} CellDataAgentType;

@interface CellDataAgent : SIMAgent
{
    id miniActivityView;
    CellDataAgentType dataType;
    FILE *fout;
    NSString *filename;
    SIMPosition pos;
    NSMutableValueArray *buffer,*times;
    int modelIndex,variableIndex;
    float radius;
    float updateInterval;
    int bufferSize;
    BOOL saveToFileFlag;
}

- (void) gatherData;
- (NSValueArray *)dataBuffer;
- (NSValueArray *)times;
- (float)dt;

@end
