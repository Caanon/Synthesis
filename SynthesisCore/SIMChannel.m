/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/SIMChannel.h>
#import <SynthesisCore/SIMCategories.h>

@implementation SIMChannel

- init
/*"
    Initializes the channel.  After calling init for the superclass,
    this method extracts the delay parameter dictionary from the main dictionary.
"*/
{
    [super init];
    return self;
}

- initWithDescription:(NSDictionary *)dict
{
    [super initWithDescription:dict];
    return self;
}


- (void) updateVariableIndexes
{
    [super updateVariableIndexes];
    
    OUTPUT_INDEX = [self indexOfVariable:@"OUTPUT"];
}

- (void) setRandomNumberSeed:(int)seed
{
    [super setRandomNumberSeed:seed];
}

- (void) initUserState
{
/*"
    Allocates a local state useful for calculations.  Needs to be called
    during initialisation by any subclass that uses one of the
    #{updateStateUsingXXX:dt:time:} methods instead of #{updateState:dt:time:}.
"*/
    int n = [self numVariables];

    if (!userState.channel) {
        userState.channel = NSZoneCalloc([self zone],(_assignedIndex+1),sizeof(SIMStateValue *));
        [self allocState:&userState];  
    }
    
    dym = calloc(n,sizeof(SIMStateValue));
    dyt = calloc(n,sizeof(SIMStateValue));
    yt = calloc(n,sizeof(SIMStateValue));
}

- (void) setRandomValuesForState: (SIMState *) element
/*"
    Sets state variables (input and output potential) in element to
    random values with a uniform distribution (using %stateGenerator).
    Subclasses that define additional variables should implement as appropriate.
"*/
{
//    element->CHANNEL[OUTPUT_INDEX].state.doubleValue = [stateGenerator uniformDeviate];
}

- (void) setNullValuesForState: (SIMState *) element
/*"
    Sets state variables (input and output potential) in element to zero.
    Subclasses that define additional variables should implement as appropriate.
"*/
{
    element->CHANNEL[OUTPUT_INDEX].state.doubleValue = 0.0;
}

- (void) setInitialValuesForState: (SIMState *) element
{
/*"
    Initialises state variables (input and output potential) in element
    by setting them to zero.  Subclasses that define additional variables
    should implement as appropriate.
"*/
    element->CHANNEL[OUTPUT_INDEX].state.doubleValue = 0.0;
}

- (oneway void) updateParameters
/*"
    This method retrieves parameter values for the channel.  If the object has a delay
"*/
{
    [super updateParameters];
}



- (void)updateStateUsingForwardEuler:(SIMState *)element dt:(float)dt time:(float)time
/*"
    Used to solve the differential equations described by overriding the
    method #{evaluateDerivatives: initialValues: time: context} via the
    %{Forward Euler} method.  For this method all that involves is scaling each
    derivative by the timestep before adding it to the previous value.  This is a
    simple, crude and error-prone (due to its instability) method of solving nonlinear
    differential equations.
"*/
{
    int i;
    int numEqs = [self numVariables];

    evaluateDerivatives(self, @selector(evaluateDerivatives:initialValues:time:context:), 			
        userState.CHANNEL, element->CHANNEL,time,element);

    for(i=0;i<numEqs;i++){
        if((element->CHANNEL[i].type < SIMObjectType) && userState.CHANNEL[i].state.doubleValue != 0)
            element->CHANNEL[i].state.doubleValue += dt*userState.CHANNEL[i].state.doubleValue;
    }
}

- (void)updateStateUsingRungeKutta4thOrder:(SIMState *)element dt:(float)dt time:(float)time
/*"
    Used to solve the differential equations described by overriding the
    method #{evaluateDerivatives: initialValues: time: context} via the
    %{Runge-Kutta Fehlberg} method.
"*/
{
    int numEqs = [self numVariables];

    evaluateDerivatives(self,@selector(evaluateDerivatives:initialValues:time:context:),userState.CHANNEL,element->CHANNEL,time,element);
    evaluateRungeKutta4 (numEqs, time, dt, element->CHANNEL,userState.CHANNEL,element->CHANNEL, dym, dyt, yt, evaluateDerivatives, self, @selector(evaluateDerivatives:initialValues:time:context:), element);
}


- (void) updateState: (SIMState *) element dt: (float) dt  time: (float) time;
/*"
"*/
{
    [super updateState:element dt:dt time:time];
}

- (double) channelCurrent: (SIMState *)element forCellModel:(SIMCell *)cellModel
/*"
    The default implementation of this returns the output as a double.
    In subclasses this could be updated to calculate the current using the membrane potential
    of the cell at the given index.  This allows conductance-based channel channels.
"*/
{
    return element->CHANNEL[OUTPUT_INDEX].state.doubleValue;
}

- (double) doubleValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	int index;
	if((index = [self indexOfVariable:var])!= NSNotFound)
		return state->CHANNEL[index].state.doubleValue;
	else return (double)SIM_UndefinedState;
}

- (float) floatValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	int index;
	if((index = [self indexOfVariable:var])!= NSNotFound)
		return state->CHANNEL[index].state.floatValue;
	else return (float)SIM_UndefinedState;
}

- (int) intValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	int index;
	if((index = [self indexOfVariable:var])!= NSNotFound)
		return state->CHANNEL[index].state.intValue;
	else return (int)SIM_UndefinedState;
}

- (SIMActivityStateValue) activityValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	int index;
	if((index = [self indexOfVariable:var])!= NSNotFound)
		return state->CHANNEL[index].state.activityValue;
	else return SIM_UndefinedState;
}


- (NSString *)inspectorClassName
{
    return @"";
}

- (NSString *)iconName
/*"
    Returns "SIMChannel", the name of an icon used to represent 
	this class in a graphical user-interface.
"*/

{
	return @"SIMChannel";
}

- (void) archiveState:(SIMState *)element withCoder:(NSCoder *)coder
{
    int index,count = [self numVariables];
    for(index = 0; index < count;index++){
        [coder encodeStateValue:&element->CHANNEL[index]];
    }
}

- (void) unarchiveState:(SIMState *)element withCoder:(NSCoder *)coder
{
    int index,count = [self numVariables];
    for(index = 0; index < count;index++){
        [coder decodeStateValue:&element->CHANNEL[index]];
    }
}

- (void) archiveRemoteState:(SIMState *)element withCoder:(NSCoder *)coder
/*" Used for lightweight network transport of information between nodes "*/
/*" No information is needed, in general, about the channels of the presynaptic cell "*/
{
}

- (void) unarchiveRemoteState:(SIMState *)element withCoder:(NSCoder *)coder
/*" Used for lightweight network transport of information between nodes "*/
/*" No information is needed, in general, about the channels of the presynaptic cell "*/
{
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
    element->CHANNEL = (SIMStateValue *) NSZoneCalloc ([self zone], count, sizeof(SIMStateValue));

    for (i=0; i < count; i++){
        NSString *varName = [self variableAtIndex:i];
        element->CHANNEL[i].type = [self typeForVariable:varName];
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
    element->CHANNEL = (SIMStateValue *) NSZoneRealloc ([self zone], element->CHANNEL, count * sizeof(SIMStateValue));

    for (i=0; i < count; i++){
        NSString *varName = [self variableAtIndex:i];
        element->CHANNEL[i].type = [self typeForVariable:varName];
    }
}


- (void) deallocState: (SIMState *) element
/*"
    Deallocates the memory used to store state variables in the SIMState
    element.  The default implementation frees the memory that has been
    allocated for %{element.CHANNEL[]}.

    If anything other than the state variables (sizeof(double)) is
    to be stored inside this structure, this method must be overridden and the
    extra space deallocated.
"*/
{
	// each subclass that stores anything extra inside the state struct
	// must deallocate it itself, then call [super deallocState: element].

    if (element->type != SIM_UndefinedType)
            NSZoneFree ([self zone], element->CHANNEL);
}

- (id)initWithCoder:(NSCoder *)coder
/*"
    Initializes a new instance of this class from coder.
"*/
{
    self = [super initWithCoder:coder];
    return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
    [super encodeWithCoder:coder];
}

@end

