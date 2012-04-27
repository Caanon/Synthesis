#import "ItChannel.h"

@implementation ItChannel


- (void) initializeWithCellType:(SIMType *)type
{
    [super initializeWithCellType:type];
}


- (void) updateVariableIndexes
{
    [super updateVariableIndexes];
    G = [self indexOfVariable:@"G"];
    M = [self indexOfVariable:@"M"];
    H = [self indexOfVariable:@"H"];
}

- (void) setInitialValuesForState: (SIMState *) element
{
    [super setInitialValuesForState: element];
    element->CHANNEL[G].state.doubleValue = 0.0;
    element->CHANNEL[M].state.doubleValue = 0.0;
    element->CHANNEL[H].state.doubleValue = 0.0;
}

- (oneway void) updateParameters
{    
    [super updateParameters];
    
    gPeak = [self doubleForKey:@"gPeak"];
    Erev = [self doubleForKey:@"Erev"];
}

- (void) updateState: (SIMState *) element
            dt: (float) dt
            time:(float)time
{
    [super updateState:element dt:dt time:time];

    element->CHANNEL[G].state.doubleValue = gPeak * element->CHANNEL[M].state.doubleValue * element->CHANNEL[M].state.doubleValue * element->CHANNEL[H].state.doubleValue;;
}

- (void)evaluateDerivatives:(SIMStateValue *)dy initialValues:(SIMStateValue *)y time:(float)t context:(SIMState *)state
{
    double v = [(SIMType *)state->type membranePotential:state];

    double m = 1/(1+exp(-(v+59.0)/6.2));//ITOutputTable(ItMTable,state->CELL[Vm].state.doubleValue);
    double tau_m = 0.22/(exp(-(v + 132.0)/16.7)+exp((v + 16.8)/18.2)) + 0.13;//ITOutputTable(tauMTable,state->CELL[Vm].state.doubleValue);
    double h = 1/(1 + exp((v + 83.0)/4));//ITOutputTable(ItHTable,state->CELL[Vm].state.doubleValue);
    double tau_h = (8.2 + (56.6 + 0.27 * exp((v + 115.2)/5.0))/(1.0 + exp((v + 86.0)/3.2)));//ITOutputTable(tauHTable,state->CELL[Vm].state.doubleValue);
    
    dy[M].state.doubleValue = (m - y[M].state.doubleValue)/tau_m;
    dy[H].state.doubleValue = (h - y[H].state.doubleValue)/tau_h;
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
