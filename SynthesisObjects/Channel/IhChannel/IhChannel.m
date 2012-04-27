#import "IhChannel.h"

@implementation IhChannel


- (void) initializeWithCellType:(SIMType *)type
{
    [super initializeWithCellType:type];
}


- (void) updateVariableIndexes
{
    [super updateVariableIndexes];
    G = [self indexOfVariable:@"G"];
    M = [self indexOfVariable:@"M"];
}

- (void) setInitialValuesForState: (SIMState *) element
{
    [super setInitialValuesForState: element];
    element->CHANNEL[G].state.doubleValue = 0.0;
    element->CHANNEL[M].state.doubleValue = 0.0;
}

- (oneway void) updateParameters
{    
    [super updateParameters];
    
    gPeak = [self doubleForKey:@"gPeak"];
    Erev = [self doubleForKey:@"Erev"];
    Vthreshold = [self doubleForKey:@"Vthreshold"];
}

- (void) updateState: (SIMState *) element
            dt: (float) dt
            time:(float)time
{
    [super updateState:element dt:dt time:time];

    element->CHANNEL[G].state.doubleValue = gPeak * element->CHANNEL[M].state.doubleValue;
}

- (void)evaluateDerivatives:(SIMStateValue *)dy initialValues:(SIMStateValue *)y time:(float)t context:(SIMState *)state
{
    double v = [(SIMType *)state->type membranePotential:state];

    double tau_m = 1.0/(expx(-14.59 - 0.086 * v) + expx(-1.87 + 0.0701 * v)); // replace with table
    double m = 1.0/(1.0 + expx((v - Vthreshold)/5.5));
    
    dy[M].state.doubleValue = (m - y[M].state.doubleValue)/tau_m;
}

- (double) channelCurrent: (SIMState *)element forCellModel:(SIMCell *)cellModel
/*"
    Use the conductance to calculate the current output.
"*/
{
    element->CHANNEL[OUTPUT_INDEX].state.doubleValue = - element->CHANNEL[G].state.doubleValue * ([cellModel membranePotential:element] - Erev);
    return element->CHANNEL[OUTPUT_INDEX].state.doubleValue;
}


@end
