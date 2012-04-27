/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMType.h>
#import <SynthesisCore/SIMModel.h>
#import <PseudoRandomNum/PRNGenerator.h>


enum { CELL_STATE_INDEX,CELL_POTENTIAL_INDEX };
/*"
    These indices (CELL_STATE_INDEX, CELL_POTENTIAL_INDEX) should correspond to the
    first two variables used in a cell model.  The value at CELL_POTENTIAL_INDEX is
    reserved for the membrane potential.  The model gets the number of cell states
    and their indices from the template file.  Be sure to include entries for these two
    states before any additional state variables.  See the SIMCell.template file for an
    example.
"*/

#define CELL	cell[_assignedIndex]
/*"
	The state of a cell should always be accessed by using element->CELL[] or CELL_XXX_VALUE(element) rather than
	element->cell[][].  This guarantees that you will access the state variables
	at the appropriate index for this model.
"*/

/*"
    The default random number generator seed value is contained in the SIMModel.template.  To override this place an entry
    like "STATE_GENERATOR_SEED = 2001;" in the parameter dictionary for the model.
"*/


@interface SIMCell:SIMModel
{
    SIMStateValue *dym, *dyt, *yt; // memory needed for Runge-Kutta solver
}

- (void) setInitialValuesForState: (SIMState *) element;
- (void) setRandomValuesForState: (SIMState *) element;
- (void) setNullValuesForState: (SIMState *) element;

- (double) summedChannelCurrents:(SIMState *)element;
- (double) summedInputChannelCurrents:(SIMState *)element;
- (double) summedIntrinsicChannelCurrents:(SIMState *)element;

- (double) inputCurrent:(SIMState *)element forChannel:(NSString *)key;
- (double) inputCurrent:(SIMState *)element forChannelAtIndex:(int)index;
- (double) intrinsicCurrent:(SIMState *)element forChannel:(NSString *)key;
- (double) intrinsicCurrent:(SIMState *)element forChannelAtIndex:(int)index;

- (BOOL) shouldCellUpdateConnections:(SIMState *)state;
- (double) membranePotential:(SIMState *)element;
- (void) updateStateUsingForwardEuler:(SIMState *)element dt:(float)dt time:(float)time;
- (void) updateStateUsingRungeKutta4thOrder:(SIMState *)element dt:(float)dt time:(float)time;
- (void) allocState: (SIMState *) element;
- (void) reallocState:(SIMState *)state;
- (void) deallocState: (SIMState *) element;


@end
