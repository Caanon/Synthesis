/*  
 *   by Sean Hill
 *   (c) 2003 All rights reserved.
 *   Usage and/or disclosure of this source code is restricted to authorized persons only.
 *
 *   CellDataAgent.m created by shill on Thu 06-Jan-1999
 */

#import "CellDataAgent.h"
#import <SynthesisCore/SIMNetworkInfo.h>

@implementation CellDataAgent

- initWithDescription:(NSDictionary *)desc forNetwork:(SIMNetwork *)net
{
    [super initWithDescription:desc forNetwork:net];
    buffer = [[NSMutableValueArray valueArrayWithObjCType:@encode(float)] retain];
    times = [[NSMutableValueArray valueArrayWithObjCType:@encode(float)] retain];
    fout = (FILE *)nil;
    updateInterval = 100.0;
    return self;
}

- (NSValueArray *)dataBuffer
{
    return (NSValueArray *)buffer;
}

- (NSValueArray *)times
{
    return (NSValueArray *)times;
}

- (float) dt
{
    return [network dt];
}

- (void)clearBuffer
{
    [buffer removeAllObjects];
    [times removeAllObjects];
}

- (void) gatherData
{
    float value,time;
    
    switch (dataType){
        case SIM_AverageMembranePotential:
            value = [network averageMembranePotentialAroundCell:&pos radius:radius];
            break;
        case SIM_AverageFieldPotential:
            value = [network localFieldPotentialForCell:&pos radius:radius];
            break;
        case SIM_MembranePotential:
            value = [network averageMembranePotentialAroundCell:&pos radius:0];
            break;
        case SIM_SummedChannelCurrent:
            value = [network summedInputChannelCurrentsForCell:&pos];
            break;
        case SIM_ChannelModelVariable:
            value = [[network valueForInputChannel:modelIndex atIndex:variableIndex forCell:&pos] floatValue];
            break;
        case SIM_CellModelVariable:
            value = [[network valueForCellCompartment:modelIndex atIndex:variableIndex forCell:&pos] floatValue];
            break;
        default:
            return;
    }

    time = [network time];
    [buffer addValue:&value];
    [times addValue:&time];
    
    while([buffer count] > bufferSize){
        [buffer removeValueAtIndex:0];
        [times removeValueAtIndex:0];
    }
    
    if(!fout && saveToFileFlag) fout = fopen([filename UTF8String],"ab");
    if(saveToFileFlag && fout)fwrite(&value,sizeof(float),1,fout);
    
    if(fmod(time,updateInterval) == 0.0)
        [[NSNotificationCenter defaultCenter] postNotificationName:SIMNetworkUpdateIntervalNotification object:self];
}

- (void) updateParameters
{
    NSString *layerKey,*dataTypeString, *variableString, *modelString, *typeString;
    int intDT = 1/[network dt];

    [super updateParameters];

    if(filename)[filename autorelease];
    filename = [[self filePathForKey:@"Filename"] retain];

    layerKey = [self objectForKey:SIM_LAYER];
    pos.x = [self floatForKey:SIM_POSITION_X]; pos.y = [self floatForKey:SIM_POSITION_Y];
    pos.z = [network indexForLayerWithKey:layerKey];
    typeString = [network typeForCell:pos];
    
    variableString = [self objectForKey:SIM_VARIABLE];
    modelString = [self objectForKey:SIM_MODEL];
        
    dataTypeString = [self objectForKey:SIM_DATATYPE];
    
    if([dataTypeString isEqual:SIM_DATATYPE_AverageMembranePotential])
        dataType = SIM_AverageMembranePotential;
    else if([dataTypeString isEqual:SIM_DATATYPE_AverageFieldPotential])
        dataType = SIM_AverageFieldPotential;
    else if([dataTypeString isEqual:SIM_DATATYPE_MembranePotential])
        dataType = SIM_MembranePotential;
    else if([dataTypeString isEqual:SIM_DATATYPE_SummedChannelCurrent])
        dataType = SIM_SummedChannelCurrent;
    else if([dataTypeString isEqual:SIM_DATATYPE_CellModelVariable]){
        dataType = SIM_CellModelVariable;
        variableIndex = [network indexForCellVariable:variableString inModel:modelString inType:typeString layer:layerKey];
    }
    else if([dataTypeString isEqual:SIM_DATATYPE_ChannelModelVariable]){
        dataType = SIM_ChannelModelVariable;
        variableIndex = [network indexForInputChannelVariable:variableString inModel:modelString inType:typeString layer:layerKey];
    }
    
    radius = [self intForKey:SIM_RADIUS];
    
    bufferSize = [self intForKey:SIM_BUFFERSIZE] * intDT;
    updateInterval = [self floatForKey:SIM_UPDATEINTERVAL];
    saveToFileFlag = [self boolForKey:SIM_SAVETOFILE];
}

- (void) startAgent
{
    [super startAgent];

	[self createDataDirectory];

    if(!buffer)buffer = [[NSMutableValueArray valueArrayWithObjCType:@encode(float)] retain];
    if(!times)times = [[NSMutableValueArray valueArrayWithObjCType:@encode(float)] retain];

    if(fout){fclose(fout);fout = (FILE *)nil;}
    if(!saveToFileFlag)return;
    if(!(fout = fopen([filename UTF8String],"ab"))){
        NSLog(@"Could not open file %@.",filename);
    }
}

- (void) stopAgent
{
    [super stopAgent];

    if(fout){fclose(fout);fout = (FILE *)nil;}
}

- (void) dealloc
{
    [buffer release];
    [times release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder
/*"
    Initializes a new instance of this class from coder.
"*/
{
    self = [super initWithCoder:coder];
    
    buffer = [[coder decodeObject] retain];
    times = [[coder decodeObject] retain];

    return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
/*"
    Encodes the current object with coder, see NSCoding.
"*/
{
    [coder encodeObject:buffer];
    [coder encodeObject:times];
}


@end
