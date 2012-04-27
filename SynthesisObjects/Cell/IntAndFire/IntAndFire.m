#import "IntAndFire.h"

/*  State variables could be defined for convenience in the following manner:
    #define voltage element->CELL[V].state.doubleValue
    #define threshold element->CELL[Th].state.doubleValue
*/

@implementation IntAndFire


- (void) updateVariableIndexes
{
    [super updateVariableIndexes];

    state = CELL_STATE_INDEX;
    V = CELL_POTENTIAL_INDEX;
    Th = [self indexOfVariable:THRESHOLD];
    lastSpike = [self indexOfVariable:LASTSPIKE];
}

- (void) setInitialValuesForState: (SIMState *) element
{
    [super setInitialValuesForState: element];
    element->CELL[V].state.doubleValue =  ([stateGenerator uniformDeviate] - 0.5) * (Th0 - E0) + E0;
    element->CELL[Th].state.doubleValue = Th0;
    element->CELL[lastSpike].state.floatValue = -1000.0;
}

- (void) setRandomValuesForState: (SIMState *) element
{
    [super setRandomValuesForState: element];
    element->CELL[V].state.doubleValue =  ([stateGenerator uniformDeviate] * (Th0 - E0)) + E0;
}

- (void)updateState:(SIMState *)element dt:(float)dt time:(float)time
{
    [super updateState:element dt:dt time:time];

    if (element->CELL[CELL_STATE_INDEX].state.activityValue == SIM_RefractoryState) {  // Decay from sodium reversal to potassium reversal potential
        float t = time - element->CELL[lastSpike].state.floatValue;
        element->CELL[V].state.doubleValue = EK;
        if(t >= .5){ // should change this to support different action potential durations
            element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_RestingState;
        }
    }
    else
    if (element->CELL[CELL_STATE_INDEX].state.activityValue >= SIM_FiringState) {  // Grow towards sodium reversal potential
        float t = time - element->CELL[lastSpike].state.floatValue;
        element->CELL[V].state.doubleValue = ENa;
        if(t > 0)element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_FiringState;
        if(t >= .5){ // should change this to support different action potential durations
            element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_RefractoryState;
            element->CELL[lastSpike].state.floatValue = time;
        }
    }
    else
    if (element->CELL[V].state.doubleValue > element->CELL[Th].state.doubleValue) {
        element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_SpikingState;
        element->CELL[lastSpike].state.floatValue = time;
    }

}

- (void)evaluateDerivatives:(SIMStateValue *)dy initialValues:(SIMStateValue *)y time:(float)time context:(SIMState *)context
{
    float A = [self summedChannelCurrents:context];

    dy[Th].state.doubleValue = (-(y[Th].state.doubleValue - Th0) + d * (y[V].state.doubleValue - E0))/tcTh;
    dy[V].state.doubleValue = (A + E0 - y[V].state.doubleValue)/tcV;

}

- (oneway void)updateParameters
{
    [super updateParameters];

    E0 =  [self floatForKey:INTANDFIRE_RestingPotential];
    tcV = [self floatForKey:INTANDFIRE_VoltageTimeConstant];
    Th0 = [self floatForKey:INTANDFIRE_RestingThreshold];
    EK = [self floatForKey:INTANDFIRE_PotassiumReversalPotential];
    ENa = [self floatForKey:INTANDFIRE_SodiumReversalPotential];
    c = [self floatForKey:INTANDFIRE_ThresholdVoltageCoefficient];
    d = [self floatForKey:INTANDFIRE_SpikeActivation];
    tcTh = [self floatForKey:INTANDFIRE_ThresholdTimeConstant];
}

@end
