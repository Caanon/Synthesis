/*   PulseIntegrateAndFire
 *   by Sean Hill
 *   (c) 2003 All rights reserved.
 *   Usage and/or disclosure of this source code is restricted to authorized persons only.
 *
 */

#import "PulseIntegrateAndFire.h"

@implementation PulseIntegrateAndFire

- (void) updateVariableIndexes
{
    [super updateVariableIndexes];
    Vm = [self indexOfVariable:MEMBRANE_POTENTIAL];
    Th = [self indexOfVariable:THRESHOLD];
    lastSpike = [self indexOfVariable:LASTSPIKE];
    lastPlastic = [self indexOfVariable:@"LastPlasticTime"];
}

- (void) setInitialValuesForState: (SIMState *) element
{
    [super setInitialValuesForState: element];
    element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_RestingState;
    element->CELL[Vm].state.doubleValue =  E_Threshold - 10.0;  // start at threshold minus 10mv
    element->CELL[Th].state.doubleValue =  E_Threshold;
    element->CELL[lastSpike].state.floatValue = -10000.0;
    element->CELL[lastPlastic].state.floatValue = -10000.0;
}

- (void)updateState:(SIMState *)element dt:(float)dt time:(float)time
{
    float t = time - element->CELL[lastSpike].state.floatValue;

    [super updateState:element dt:dt time:time];
	    
    if((element->CELL[CELL_STATE_INDEX].state.activityValue & SIM_FiringState)){ // should change this to support different action potential durations
		if(t > 0.){
			element->CELL[CELL_STATE_INDEX].state.activityValue &= ~SIM_SpikingState;
			if(plasticityFlag) element->CELL[CELL_STATE_INDEX].state.activityValue &= ~SIM_PlasticState;
		}
		if(t >= spikeDuration){ // action potential duration is determined by the spikeDuration variable
			element->CELL[CELL_STATE_INDEX].state.activityValue |= SIM_RestingState;
			element->CELL[CELL_STATE_INDEX].state.activityValue &= ~SIM_FiringState;
		}
    }
    if ((element->CELL[CELL_STATE_INDEX].state.activityValue & SIM_RestingState) && (element->CELL[Vm].state.doubleValue > element->CELL[Th].state.doubleValue)) {
		element->CELL[CELL_STATE_INDEX].state.activityValue &= ~SIM_RestingState; // Not resting
        element->CELL[CELL_STATE_INDEX].state.activityValue |= SIM_SpikingState; // Set spiking flag
        if(plasticityFlag) element->CELL[CELL_STATE_INDEX].state.activityValue |= SIM_PlasticState; // Set plasticity flag
        element->CELL[CELL_STATE_INDEX].state.activityValue |= SIM_FiringState; // Set firing flag
        element->CELL[Vm].state.doubleValue = E_Na;
        element->CELL[Th].state.doubleValue = E_Na;
        element->CELL[lastSpike].state.floatValue = time;
    }
	
    if((element->CELL[CELL_STATE_INDEX].state.activityValue & SIM_PlasticState)){
				element->CELL[lastPlastic].state.floatValue = time;
	}

}

- (void)evaluateDerivatives:(SIMStateValue *)dy initialValues:(SIMStateValue *)y time:(float)time context:(SIMState *)state
{
    double currents = [self summedChannelCurrents:state];
    double v = y[Vm].state.doubleValue;
    float fire = (state->CELL[CELL_STATE_INDEX].state.activityValue & SIM_FiringState) || 
                (state->CELL[CELL_STATE_INDEX].state.activityValue & SIM_SpikingState)?1.0:0.0;
            
    dy[Th].state.doubleValue = -(y[Th].state.doubleValue - E_Threshold)/tcTh;
    dy[Vm].state.doubleValue = (-gKLeak*(v - E_K) - gNaLeak*(v - E_Na)  + currents)/tcV - fire*(v - E_K)/tcSpike;
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
    tcSpike = [self floatForKey:INTANDFIRE_SpikeTimeConstant];
    spikeDuration = [self floatForKey:INTANDFIRE_SpikeDuration];
    gKLeak = [self floatForKey:INTANDFIRE_PotassiumLeakConductance];
    gNaLeak = [self floatForKey:INTANDFIRE_SodiumLeakConductance];
	plasticityFlag=[self boolForKey:@"Plasticity"];

}


@end
