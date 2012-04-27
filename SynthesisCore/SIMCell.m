/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/SIMCell.h>
#import <SynthesisCore/SIMChannel.h>
#import <SynthesisCore/SIMCategories.h>
#import <Desiderata/NSValueArray.h>

@implementation SIMCell
/*"
    The abstract superclass for all cell models.  This class (and its
    subclasses) are responsible for modeling the activity (calculating the state
    variables) of any type of cell model.  This class contains utilities for solving
    nonlinear differential equations with %{Runge-Kutta 4th-order} and
    %{Forward Euler} methods.

    Subclasses typically override three methods to completely define a new model.  In
    addition, they must complete a template file (see SIMCell.template) which
    describes the state variables and parameters used by the model.

    Typically the three methods which are overridden are:
    #{- setInitialValuesForState:},
    #{- updateState: dt: time:} and
    #{- updateParameters}.
    A fourth method:
    #{- evaluateDerivatives: initialValues: time: context:}
    should be overridden if the modeller wishes to take advantage
    of the differential equation solving abilities built into the SIMModel and SIMCell
    objects.

    See the source code for FitzHughNagumo.cell for an example of implementing a neuron
    which implements both #{updateState:dt:time:} and
    #{evaluateDerivatives: initialValues: time: context}.

"*/


- (void) initUserState
{
/*"
    Allocates a local state useful for calculations.  This is called automatically during initModelWithNetwork:
    if the model is setup to use any of the differential equation solving facilities.
"*/
    int n = [self numVariables];

    if (!userState.cell) {
        userState.cell = NSZoneCalloc([self zone],(_assignedIndex+1),sizeof(SIMStateValue *));
        [self allocState:&userState]; 
    }

    dym = calloc(n,sizeof(SIMStateValue));
    dyt = calloc(n,sizeof(SIMStateValue));
    yt = calloc(n,sizeof(SIMStateValue));

}

- (void) setRandomValuesForState: (SIMState *) element
/*"
	Uses the models random number generator %{stateGenerator} to set the
	value of element->CELL[CELL_STATE_INDEX] to a uniform random number between 0
	and 1. Subclasses should override this to initialize other variables.
"*/
{
	[super setRandomValuesForState:element];
// This should be corrected to set the values to be a SIMActivityStateValue.
//    element->CELL[CELL_STATE_INDEX].state.activityValue = [stateGenerator uniformDeviate];
//    element->CELL[CELL_POTENTIAL_INDEX].state.doubleValue = [stateGenerator uniformDeviate];
}

- (void) setNullValuesForState: (SIMState *) element
/*"	
	Sets the value of element->CELL[CELL_STATE_INDEX] to %SIM_RestingState
	and the value of element->CELL[CELL_POTENTIAL_INDEX] to zero.
	Subclasses should override this to initialize other variables.
"*/
{
	[super setNullValuesForState:element];
    element->CELL[CELL_STATE_INDEX].state.doubleValue = 0.0;
    element->CELL[CELL_POTENTIAL_INDEX].state.doubleValue = 0.0;
}

- (void) setInitialValuesForState: (SIMState *) element
/*"
	Used to initialize the state variables stored in the element structure.
	The default implementation sets all state variables to 0.0.
	Subclasses should override this to initialize other variables.
"*/
{
	[super setInitialValuesForState:element];
    element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_RestingState;
    element->CELL[CELL_POTENTIAL_INDEX].state.doubleValue = 0.0;
}

- (void)updateStateUsingForwardEuler:(SIMState *)element dt:(float)dt time:(float)time
/*"
    Used to solve the differential equations described by overriding the
    method #{evaluateDerivatives: initialValues: time: context} via the
    %{Forward Euler} method.  For this method all that involves is scaling each
    derivative by the timestep before adding it to the previous value.  This is a
    simple, crude and error-prone (due to its instability) method of solving nonlinear
    differential equations.  As long as the derivatives are set to zero for the states
    not being updated by differential equations, this update should work fine.  The update
    method assumes double sized state values.
"*/

{
    int i;
    int numEqs = [self numVariables];

    evaluateDerivatives(self, @selector(evaluateDerivatives:initialValues:time:context:),userState.CELL, element->CELL,time,element);

    for(i=0;i<numEqs;i++){
        if((element->CELL[i].type < SIMObjectType) && userState.CELL[i].state.doubleValue != 0)
            element->CELL[i].state.doubleValue += dt*userState.CELL[i].state.doubleValue;
    }
}

- (void)updateStateUsingRungeKutta4thOrder:(SIMState *)element dt:(float)dt time:(float)time
/*"
    Used to solve the differential equations described by overriding the
    method #{evaluateDerivatives: initialValues: time: context} via the
    %{Runge-Kutta 4th order} method.
"*/
{
    int numEqs = [self numVariables];

    evaluateDerivatives(self,@selector(evaluateDerivatives:initialValues:time:context:),userState.CELL,element->CELL,time,element);
    evaluateRungeKutta4 (numEqs, time, dt, element->CELL,userState.CELL, element->CELL, dym, dyt, yt, evaluateDerivatives, self, @selector(evaluateDerivatives:initialValues:time:context:), element);

}

- (void) updateState: (SIMState *) element dt: (float) dt  time: (float) t;
/*"
    This method is implemented by the SIMCell and SIMChannel subclasses.
"*/
{
    [super updateState:element dt:dt time:t];
}

- (double) summedChannelCurrents:(SIMState *)element
{
    return [(SIMType *)element->type summedChannelCurrents:element forCellModel:self];
}

- (double) summedInputChannelCurrents:(SIMState *)element
{
    return [(SIMType *)element->type summedInputChannelCurrents:element forCellModel:self];
}

- (double) inputCurrent:(SIMState *)element forChannel:(NSString *)key
{
    return [(SIMType *)element->type inputChannelCurrent:element forKey:key forCellModel:self];
}

- (double) inputCurrent:(SIMState *)element forChannelAtIndex:(int)index
{
    return [(SIMType *)element->type inputChannelCurrent:element atIndex:index forCellModel:self];
}

- (double) summedIntrinsicChannelCurrents:(SIMState *)element
{
    return [(SIMType *)element->type summedIntrinsicChannelCurrents:element forCellModel:self];
}

- (double) intrinsicCurrent:(SIMState *)element forChannel:(NSString *)key
{
    return [(SIMType *)element->type intrinsicChannelCurrent:element forKey:key forCellModel:self];
}

- (double) intrinsicCurrent:(SIMState *)element forChannelAtIndex:(int)index
{
    return [(SIMType *)element->type intrinsicChannelCurrent:element atIndex:index forCellModel:self];
}

- (double) membranePotential:(SIMState *)element
{
    return element->CELL[CELL_POTENTIAL_INDEX].state.doubleValue;
}

- (BOOL) shouldCellUpdateConnections:(SIMState *)state
{
    return (state->CELL[CELL_STATE_INDEX].state.activityValue & SIM_SpikingState)? YES:NO;
}

- (double) doubleValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	int index;
	if((index = [self indexOfVariable:var])!= NSNotFound)
		return state->CELL[index].state.doubleValue;
	else return (double)SIM_UndefinedState;
}

- (float) floatValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	int index;
	if((index = [self indexOfVariable:var])!= NSNotFound)
		return state->CELL[index].state.floatValue;
	else return (float)SIM_UndefinedState;
}

- (int) intValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	int index;
	if((index = [self indexOfVariable:var])!= NSNotFound)
		return state->CELL[index].state.intValue;
	else return (int)SIM_UndefinedState;
}

- (SIMActivityStateValue) activityValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	int index;
	if((index = [self indexOfVariable:var])!= NSNotFound)
		return state->CELL[index].state.activityValue;
	else return SIM_UndefinedState;
}

- (NSString *)inspectorClassName
{
    return @"";
}

- (NSString *)iconName
/*"
	Returns "SIMCell", the name of an icon to use to represent this class in a graphical 
	user-interface.
"*/
{
	return @"SIMCell";
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
    [super encodeWithCoder:coder];
}

- (void) archiveState:(SIMState *)element withCoder:(NSCoder *)coder
{
    int index,count = [self numVariables];
    for(index = 0; index < count;index++){
        [coder encodeStateValue:&element->CELL[index]];
    }
}

- (void) unarchiveState:(SIMState *)element withCoder:(NSCoder *)coder
{
    int index,count = [self numVariables];
    for(index = 0; index < count;index++){
        [coder decodeStateValue:&element->CELL[index]];
    }
}

- (void) archiveRemoteState:(SIMState *)element withCoder:(NSCoder *)coder
/*" Used for lightweight network transport of information between nodes "*/
{
// default is to archive only the membrane potential.
        [coder encodeStateValue:&element->CELL[CELL_POTENTIAL_INDEX]];
#if 0
    int index,count = 2; // unarchive state and membrane potential information only
    for(index = 0; index < count;index++){
        [coder encodeStateValue:&element->CELL[index]];
    }
#endif
}

- (void) unarchiveRemoteState:(SIMState *)element withCoder:(NSCoder *)coder
/*" Used for lightweight network transport of information between nodes "*/
{
// default is to archive only the membrane potential.
        [coder decodeStateValue:&element->CELL[CELL_POTENTIAL_INDEX]];
#if 0
    int index,count = 2; // unarchive state and membrane potential information only
    for(index = 0; index < count;index++){
        [coder decodeStateValue:&element->CELL[index]];
    }
#endif
}


- (void) allocState: (SIMState *) element
/*"
	Allocates the memory necessary to store state variables in the SIMState
	element.  The default implementation counts the number of state variables
	listed in the SIMCell.template file and allocates enough space for each of
	them according to their type.
"*/
{
    int i, count = [self numVariables];
    element->CELL = (SIMStateValue *) NSZoneCalloc ([self zone], count, sizeof(SIMStateValue));
    for (i=0; i < count; i++){
        NSString *varName = [self variableAtIndex:i];
        element->CELL[i].type = [self typeForVariable:varName];
    }
}

- (void) reallocState: (SIMState *) element
/*"
	Allocates the memory necessary to store state variables in the SIMState
	element.  The default implementation counts the number of state variables
	listed in the SIMCell.template file and allocates enough space for each of
	them according to their type.
"*/
{
    int i, count = [self numVariables];
    element->CELL = (SIMStateValue *) NSZoneRealloc ([self zone], element->CELL, count*sizeof(SIMStateValue));
    for (i=0; i < count; i++){
        NSString *varName = [self variableAtIndex:i];
        element->CELL[i].type = [self typeForVariable:varName];
    }
}

- (void) deallocState: (SIMState *) element
/*"
    Deallocates the memory used to store state variables in the SIMState
    element.  The default implementation frees the memory that has been
    allocated for %{element.CELL[]}.

    If anything other than the state variables (sizeof(double)) is
    to be stored inside this structure, this method must be overridden and the
    extra space deallocated.
"*/

{
	// each subclass that stores anything extra inside the state struct
	// must deallocate it itself, then call [super deallocState: element].
	if (element->type != SIM_UndefinedType)
        NSZoneFree ([self zone], element->CELL);
}

@end
