#import "PoissonNeuronTMS.h"
#include <math.h>

/*"
    This neuron's firing probability at each time step is determined
    by the summed synaptic input.  It has an absolute and a refractory
    period.
"*/

@implementation PoissonNeuronTMS

- (void) initializeWithCellType:(SIMType *)type
{
    [super initializeWithCellType:type];
    [self setRandomNumberSeed:1];
}

- (void) setRandomNumberSeed:(int)seed
{
    [super setRandomNumberSeed:seed];
    if (generator) [generator release];
    generator = [[PRNGenerator uniformGenerator] retain];
    [generator setSeed:seed+1];
}


- (void) updateVariableIndexes
{
    [super updateVariableIndexes];
    refractory = [self indexOfVariable: Refractory];

    [self setRandomNumberSeed:1];
}

- (double) firingProbability: (SIMState *) element dt: (float) dt 
{
    /*"
        The firing rate is given by the mean rate parameter modulated
        by the summed synaptic input, and also by the absolute and
        relative refractory periods.
	If the summed synaptic input ranges over [-1,1], then the
	modulation is between 0 and 2 * the mean rate parameter. 
    "*/
    if (relativeRefractoryPeriod) {
        double temp = element->CELL[refractory].state.doubleValue / relativeRefractoryPeriod;
        if (temp > 6.0)
            // avoid exp()
            return meanFiringRate * dt
                * (1 + [self summedChannelCurrents:element]);
        else
            return meanFiringRate * dt
                * (1 + [self summedChannelCurrents:element])
                	* (1 - exp (-temp));
    }
    return meanFiringRate * dt
        * (1 + [self summedChannelCurrents:element]);
}

- (void) updateState: (SIMState *) element dt: (float) dt time:(float)time
{	
	if(element->CELL[CELL_STATE_INDEX].state.activityValue == SIM_SpikingState+3){
		if (([generator uniformDeviate] < [self firingProbability: element dt: dt]) &&
			((element->CELL[refractory].state.doubleValue += dt) >= 0)){
			//Spike and TMS
			element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_SpikingState+2;
			element->CELL[refractory].state.doubleValue = -absoluteRefractoryPeriod;
		}
		else {
			//Just TMS
			element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_SpikingState+1;
		}
		return;
	}
	if((element->CELL[CELL_STATE_INDEX].state.activityValue == SIM_SpikingState+1) 
			|| (element->CELL[CELL_STATE_INDEX].state.activityValue == SIM_SpikingState+2)){
		element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_RestingState;
	}

    if ((element->CELL[refractory].state.doubleValue += dt) < 0) {
        // refractory -- can't fire
        element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_RefractoryState;
        return;
    }
    else if ([generator uniformDeviate] < [self firingProbability: element dt: dt])
        // fire
        element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_SpikingState;
    else {
        element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_RestingState;
    }	

    if (element->CELL[CELL_STATE_INDEX].state.activityValue == SIM_SpikingState) {
        element->CELL[refractory].state.doubleValue = -absoluteRefractoryPeriod;
    }
}

- (void) updateParameters
{
    [super updateParameters];
    // reload parameters
    absoluteRefractoryPeriod = [self floatForKey: AbsoluteRefractoryPeriod];
    relativeRefractoryPeriod = [self floatForKey: RelativeRefractoryPeriod];
    meanFiringRate = [self floatForKey: MeanFiringRate] / 1000.;  // ms

}

- (void)setTMSState:(SIMState *)element
{
	element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_SpikingState+3;
}

- (void) dealloc
{
    [generator release];
    [super dealloc];
}
@end
