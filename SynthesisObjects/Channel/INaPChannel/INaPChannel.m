#import "INaPChannel.h"

@implementation INaPChannel


- (void) initializeWithCellType:(SIMType *)type
{
    [super initializeWithCellType:type];
}


- (void) updateVariableIndexes
{
    [super updateVariableIndexes];
    G = [self indexOfVariable:@"G"];
}

- (void) setInitialValuesForState: (SIMState *) element
{
    [super setInitialValuesForState: element];
    element->CHANNEL[G].state.doubleValue = 0.0;
}

- (oneway void) updateParameters
{    
    [super updateParameters];
    
    gPeak = [self doubleForKey:@"gPeak"];
    Erev = [self doubleForKey:@"Erev"];
    threshold = [self doubleForKey:@"Threshold"];
    slope = [self doubleForKey:@"Slope"];
}

// INaP = gNaP*m^3*(V-VNa)

- (void) updateState: (SIMState *) element
            dt: (float) dt
            time:(float)time
{
    double v = [(SIMType *)element->type membranePotential:element];
   // double m;

    [super updateState:element dt:dt time:time];
    
   // m = (1/(1+exp(-(v - threshold)/slope)));

    element->CHANNEL[G].state.doubleValue = gPeak *(1/(1+exp(-(v - threshold)/slope))); 
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
