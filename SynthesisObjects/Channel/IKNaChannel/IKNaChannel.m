#import "IKNaChannel.h"

@implementation IKNaChannel


- (void) initializeWithCellType:(SIMType *)type
{
    [super initializeWithCellType:type];
}


- (void) updateVariableIndexes
{
    [super updateVariableIndexes];
    G = [self indexOfVariable:@"G"];
    NA = [self indexOfVariable:@"NA"];
}

- (void) setInitialValuesForState: (SIMState *) element
{
    [super setInitialValuesForState: element];
    element->CHANNEL[G].state.doubleValue = 0.0;
    element->CHANNEL[NA].state.doubleValue = sodiumEquilibrium;
}

- (oneway void) updateParameters
{    
    [super updateParameters];
    
    gPeak = [self floatForKey:@"gPeak"];
    Erev = [self floatForKey:@"Erev"];
    sodiumInfluxPeak = [self floatForKey:@"SodiumInfluxPeak"];
    sodiumThresholdSlope = [self floatForKey:@"SodiumThresholdSlope"];
    sodiumThreshold = [self floatForKey:@"SodiumThreshold"];
    sodiumEquilibrium = [self floatForKey:@"SodiumEquilibrium"];
        
    sodiumTimeConstant = [self floatForKey:@"SodiumTimeConstant"];
}

- (void) updateState: (SIMState *) element
            dt: (float) dt
            time:(float)time
{
    [super updateState:element dt:dt time:time];
    double Na_i = element->CHANNEL[NA].state.doubleValue;
    double w_inf = 1.0/(1.0+pow(0.25/Na_i,3.5));

    element->CHANNEL[G].state.doubleValue = -gPeak * w_inf;
}

- (void)evaluateDerivatives:(SIMStateValue *)dy initialValues:(SIMStateValue *)y time:(float)t context:(SIMState *)state
{
    double Na_i = y[NA].state.doubleValue;
    //double Na_i3 = Na_i*Na_i*Na_i;
    double Vm = [state->type membranePotential:state];
    float sodiumInflux = 1./(1+exp(-(Vm-sodiumThreshold)/sodiumThresholdSlope));
    //float sodiumEfflux = (Na_i3)/(Na_i3 + .003375);
   // float sodiumEfflux = pow(Na_i,3)/(pow(Na_i,3) + .003375)- pow(sodiumEquilibrium,3)/(pow(sodiumEquilibrium,3) + .003375);

    dy[NA].state.doubleValue =  sodiumInfluxPeak*sodiumInflux - (Na_i*(1-sodiumEquilibrium))/sodiumTimeConstant;
    
}

- (double) channelCurrent: (SIMState *)element forCellModel:(SIMCell *)cellModel
/*"
    Use the conductance to calculate the current output.
"*/
{
    element->CHANNEL[OUTPUT_INDEX].state.doubleValue = element->CHANNEL[G].state.doubleValue * ([cellModel membranePotential:element] - Erev);
    return element->CHANNEL[OUTPUT_INDEX].state.doubleValue;
}


@end
