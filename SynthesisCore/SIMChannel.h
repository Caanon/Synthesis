/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMModel.h>

/*"
    SIMChannel is used to provide input to a SIMCell.  A subclass of SIMChannel (SIMInputChannel) allows input from other cells
    through connections.  SIMChannel is primarily for adding intrinsic properties, injecting current directly, or providing patterned stimuli
    intracellularly (i.e. not through synaptic channels).

    OUTPUT_INDEX is reserved for the channel output current.  The model gets the number of channel states
    and their indices from the template file.  Be sure to include entries for this state before any additional
    state variables.  See the SIMChannel.template file for an example.
"*/

#define CHANNEL	channel[_assignedIndex]
/*"
    The state of a channel should always be accessed by using element->CHANNEL[] rather than
    element->channel[][].  This guarantees that you will access the state variables
    at the appropriate internal index for this model.
"*/

@interface SIMChannel: SIMModel
{
    SIMStateValue *dym, *dyt, *yt; // memory needed for Runge-Kutta solver
    unsigned int OUTPUT_INDEX;
}

- (double) channelCurrent: (SIMState *)element forCellModel:(SIMCell *)cellModel;
- (void) setInitialValuesForState: (SIMState *) element;
- (void) setRandomValuesForState: (SIMState *) element;
- (void) setNullValuesForState: (SIMState *) element;
- (void) updateStateUsingForwardEuler:(SIMState *)element dt:(float)dt time:(float)time;
- (void) updateStateUsingRungeKutta4thOrder:(SIMState *)element dt:(float)dt time:(float)time;
- (void) allocState: (SIMState *) element;
- (void) reallocState:(SIMState *)state;
- (void) deallocState: (SIMState *) element;

@end
