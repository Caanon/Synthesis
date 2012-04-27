/*  
 *   by Sean Hill
 *   (c) 2003 All rights reserved.
 *   Usage and/or disclosure of this source code is restricted to authorized persons only.
 *
 *   DataAgent.m created by shill on Thu 06-Jan-1999
 */

#import "DataAgent.h"
#import <SynthesisCore/SIMNetworkInfo.h>

@implementation DataAgent

- init
{
    [super init];
    fout = (FILE *)nil;
    return self;
}

- (void) gatherData
{
    NSString *layerKey;
    NSEnumerator *layerEnum = [layerArray objectEnumerator];
    float t = [network time];
    float dt = [network dt];

    if(!fout)NSLog(@"ERROR: Data file not open.");
    if(0==fmod(floor(t/dt+.5)*dt,sampleinterval*dt)) {
        fwrite(&t,sizeof(float),1,fout);
        while(layerKey = [layerEnum nextObject]){
            if([type isEqual:SIM_DATATYPE_AverageMembranePotential]){
                float val;
                pos.z = [network indexForLayerWithKey:layerKey];
                val = [network averageMembranePotentialAroundCell:&pos radius:radius];
                fwrite(&val,sizeof(float),1,fout);
            }
            else if([type isEqual:SIM_DATATYPE_AverageFieldPotential]){
                float val;
                pos.z = [network indexForLayerWithKey:layerKey];
                val = [network localFieldPotentialForCell:&pos radius:radius];
                fwrite(&val,sizeof(float),1,fout);
            }
            else if([type isEqual:SIM_DATATYPE_ActualMembranePotential]){
                NSArray *cells = [posDictionary objectForKey:layerKey];
                NSData *data = [[network membranePotentialForCells:cells] retain];  // get membrane potential for cells in array
                const float *bytes = [data bytes];
                fwrite(bytes,sizeof(float),[data length]/sizeof(float),fout);
                [data release];
            }
            else if([type isEqual:SIM_DATATYPE_SummedChannelCurrent]){
                NSArray *cells = [posDictionary objectForKey:layerKey];
                NSData *data = [[network localFieldPotentialForCells:cells radius:0.0] retain];  // get synaptic output for cells in array
                const float *bytes = [data bytes];
                fwrite(bytes,sizeof(float),[data length]/sizeof(float),fout);
                [data release];
            }
        }
    }
    // fflush(fout);
}

- (void) updateParameters
{
    NSEnumerator *layerEnum;
    NSString *layerKey;
    int size;

    [super updateParameters];

    if(filename)[filename autorelease];
    filename = [[self filePathForKey:@"Filename"] retain];

    if(!posDictionary)posDictionary = [[NSMutableDictionary dictionary] retain];
    else [posDictionary removeAllObjects];

    layerArray = [self objectForKey:SIM_LAYERS];
    size = [self intForKey:SIM_SIZE];
    radius = [self intForKey:SIM_RADIUS];

    type = [self objectForKey:SIM_TYPE];
    sampleinterval = [self floatForKey:SIM_SAMPLEINTERVAL];
    if(0.0==sampleinterval) {
        sampleinterval = 1.0;
    }

    pos.x = [self floatForKey:SIM_POSITION_X]; pos.y = [self floatForKey:SIM_POSITION_Y];

    layerEnum = [layerArray objectEnumerator];
    if(network){
        while(layerKey = [layerEnum nextObject]){
            pos.z = [network indexForLayerWithKey:layerKey];
            [posDictionary setObject:[network squareArrayOfCellsAtPosition:&pos size:size] forKey:layerKey];
        }
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
