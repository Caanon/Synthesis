#import "GABAbChannel.h"

@implementation GABAbChannel


- (void) initializeWithCellType:(SIMType *)type
{
    [super initializeWithCellType:type];
    
    input = 0;
}


- (void) updateVariableIndexes
{
    [super updateVariableIndexes];
    g_index = [self indexOfVariable:GABABCHANNEL_g];
    G_index = [self indexOfVariable:GABABCHANNEL_G];
    R_index = [self indexOfVariable:GABABCHANNEL_R];
}

- (void) setInitialValuesForState: (SIMState *) element
{
    [super setInitialValuesForState: element];
    element->INPUTCHANNEL[g_index].state.doubleValue = 0.0;
    element->INPUTCHANNEL[G_index].state.doubleValue = 0.0;
    element->INPUTCHANNEL[R_index].state.doubleValue = 0.0;
}

- (oneway void) updateParameters
{    
    [super updateParameters];
    
    K1 = [self doubleForKey:GABABCHANNEL_TIMECONSTANT1];
    K2 = [self doubleForKey:GABABCHANNEL_TIMECONSTANT2];
    K3 = [self doubleForKey:GABABCHANNEL_TIMECONSTANT3];
    K4 = [self doubleForKey:GABABCHANNEL_TIMECONSTANT4];
    n = [self doubleForKey:GABABCHANNEL_N];
    Erev = [self doubleForKey:GABABCHANNEL_EK];
    gmax = [self doubleForKey:GABABCHANNEL_GMAX];
    KD = [self doubleForKey:GABABCHANNEL_KD];
}

- (void) updateFrom: (SIMState *) from
                to: (SIMState *) to
                withConnection: (SIMConnection *) connection
                    dt: (float) dt
                  time: (float) time
{
	to->INPUTCHANNEL[INPUT_INDEX].state.doubleValue += connection->strength;
        [super updateFrom:from to:to withConnection:connection dt:dt time:time];
}

- (void) updateState: (SIMState *) element
            dt: (float) dt
            time:(float)time
{
    [super updateState:element dt:dt time:time];

    double Gn = pow(element->INPUTCHANNEL[G_index].state.doubleValue,n);
    element->INPUTCHANNEL[g_index].state.doubleValue = gmax *( Gn / (Gn + KD));
    element->INPUTCHANNEL[INPUT_INDEX].state.doubleValue = 0.0; // clear input for next update
}

- (void)evaluateDerivatives:(SIMStateValue *)dy initialValues:(SIMStateValue *)y time:(float)t context:(SIMState *)state
{
    double G = y[G_index].state.doubleValue;
    double R = y[R_index].state.doubleValue;

    input = state->INPUTCHANNEL[INPUT_INDEX].state.doubleValue;
    
    dy[R_index].state.doubleValue = K1 * input * (1 - R) - K2 * R;
    dy[G_index].state.doubleValue = K3 * R - K4 * G; 
}

- (double) channelCurrent: (SIMState *)element forCellModel:(SIMCell *)cellModel
/*"
    Use the conductance to calculate the current output.
"*/
{
    double g = element->INPUTCHANNEL[g_index].state.doubleValue;
    element->INPUTCHANNEL[OUTPUT_INDEX].state.doubleValue = g * (Erev - [cellModel membranePotential:element]);
    return element->INPUTCHANNEL[OUTPUT_INDEX].state.doubleValue;
}


@end
