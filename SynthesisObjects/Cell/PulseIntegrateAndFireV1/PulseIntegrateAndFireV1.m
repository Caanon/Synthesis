/*   PulseIntegrateAndFireV1
 *   by Sean Hill
 *   (c) 2003 All rights reserved.
 *   Usage and/or disclosure of this source code is restricted to authorized persons only.
 *
 */

#import "PulseIntegrateAndFireV1.h"

@implementation PulseIntegrateAndFireV1

- (void) initializeWithCellType:(SIMType *)type
{
    [super initializeWithCellType:type];
    network = [type network];
}

- (void) updateVariableIndexes
{
    [super updateVariableIndexes];
    Vm = [self indexOfVariable:MEMBRANE_POTENTIAL];
    Th = [self indexOfVariable:THRESHOLD];
    lastSpike = [self indexOfVariable:LASTSPIKE];
    VP = [self indexOfVariable:VESICLEPOOL_VARIABLE];
}

- (void) setInitialValuesForState: (SIMState *) element
{
    [super setInitialValuesForState: element];
    element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_RestingState;
    element->CELL[Vm].state.doubleValue =  E_Threshold - 10.0;  // start at threshold minus 10mv
    element->CELL[Th].state.doubleValue =  E_Threshold;
    element->CELL[VP].state.doubleValue =  vesiclePeak; // start with the full vesicle pool
    element->CELL[lastSpike].state.floatValue = -10000.0;
}

- (void)updateState:(SIMState *)element dt:(float)dt time:(float)time
{
    float t = time - element->CELL[lastSpike].state.floatValue;
    double miniProb = 0.0;

    [super updateState:element dt:dt time:time];
	
	//if(element->CELL[CELL_STATE_INDEX].state.activityValue == SIM_PlasticState) 
	//	element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_RestingState;

	if(element->CELL[CELL_STATE_INDEX].state.activityValue == SIM_SpikingState+1){
		element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_SpikingState;
		return;
	}
	if(element->CELL[CELL_STATE_INDEX].state.activityValue == SIM_RestingState-2){
		element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_RestingState;
		return;
	}

    if(peakMiniRate) miniProb = ((1./(1.+expx(-(element->CELL[VP].state.doubleValue-miniThreshold)*40.))))*(peakMiniRate*dt*.001);        
    
    if((element->CELL[CELL_STATE_INDEX].state.activityValue >= SIM_FiringState)){ // should change this to support different action potential durations
        if(element->CELL[CELL_STATE_INDEX].state.activityValue == SIM_MiniSpikeState)
            element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_RestingState;
        else {
            if(t > 0.) element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_FiringState;
            if(t >= spikeDuration){ // action potential duration is determined by the spikeDuration variable
                element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_RestingState;
            }
        }
    }
    if ((element->CELL[CELL_STATE_INDEX].state.activityValue == SIM_RestingState) && (element->CELL[Vm].state.doubleValue > element->CELL[Th].state.doubleValue)) {
        element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_SpikingState;
        element->CELL[Vm].state.doubleValue = E_Na;
        element->CELL[Th].state.doubleValue = E_Na;
        element->CELL[lastSpike].state.floatValue = time;
    }
    else if ((element->CELL[CELL_STATE_INDEX].state.activityValue == SIM_RestingState) && 
        ([stateGenerator nextDouble] < miniProb)) {
        element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_MiniSpikeState;
    }
}

- (void)evaluateDerivatives:(SIMStateValue *)dy initialValues:(SIMStateValue *)y time:(float)time context:(SIMState *)state
{
    double currents = [self summedChannelCurrents:state];
    double v = y[Vm].state.doubleValue;
    double vp = y[VP].state.doubleValue;
    float spike = (state->CELL[CELL_STATE_INDEX].state.activityValue == SIM_SpikingState)?1.0:0.0;
    float fire = (state->CELL[CELL_STATE_INDEX].state.activityValue == SIM_FiringState) || 
                (state->CELL[CELL_STATE_INDEX].state.activityValue == SIM_SpikingState)?1.0:0.0;
        
    // when the cell fires, the pool of available synaptic vesicles is depleted quickly.  The recovery rate is slow.
    
    dy[Th].state.doubleValue = -(y[Th].state.doubleValue - E_Threshold)/tcTh;
    dy[Vm].state.doubleValue = (-gKLeak*(v - E_K) - gNaLeak*(v - E_Na)  + currents)/tcV - fire*(v - E_K)/tcSpike;
    dy[VP].state.doubleValue = -(spike*vesicleRelease*vp) + (vesiclePeak - vp)/vesicleRecoveryTC;
}

- (BOOL) shouldCellUpdateConnections:(SIMState *)state
// Override to be sure that if there are no available vesicles, we don't waste time updating, 
// although the spike still occurs normally.
{
    //BOOL shouldFire = [super shouldCellUpdateConnections:state];
    return ((state->CELL[CELL_STATE_INDEX].state.activityValue > SIM_FiringState) && (state->CELL[VP].state.doubleValue >= 0.01))?YES:NO;
}

- (double) membranePotential:(SIMState *)element
{
    return element->CELL[Vm].state.doubleValue;
}

- (void)updateParameters
{
    [super updateParameters];

    E_Leak =  [self floatForKey:INTANDFIRE_LeakReversalPotential];
    E_Threshold = [self floatForKey:INTANDFIRE_RestingThreshold];
    tcV = [self floatForKey:INTANDFIRE_MembraneTimeConstant];
    E_K = [self floatForKey:INTANDFIRE_PotassiumReversalPotential];
    E_Na = [self floatForKey:INTANDFIRE_SodiumReversalPotential];
    tcTh = [self floatForKey:INTANDFIRE_ThresholdTimeConstant];
    spikeDuration = [self floatForKey:INTANDFIRE_SpikeDuration];
    gKLeak = [self floatForKey:INTANDFIRE_PotassiumLeakConductance];
    gNaLeak = [self floatForKey:INTANDFIRE_SodiumLeakConductance];

    tcSpike = [self floatForKey:INTANDFIRE_SpikeTimeConstant];
    
    miniThreshold = [self floatForKey:INTANDFIRE_MiniThreshold];
    peakMiniRate = [self floatForKey:INTANDFIRE_PeakMiniRate];
    vesiclePeak = [self floatForKey:INTANDFIRE_VesiclePeak];
    vesicleRelease = [self floatForKey:INTANDFIRE_VesicleRelease];
    vesicleRecoveryTC = [self floatForKey:INTANDFIRE_VesicleRecoveryTimeConstant];
	
}


@end
