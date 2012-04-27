/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/SIMInputChannel.h>
#import <SynthesisCore/SIMCategories.h>
#import <SynthesisCore/SIMType.h>

int indexOfNextTime(NSMutableValueArray *array,DelayedInput *val)
{
    const DelayedInput *bytes = [array bytes];
    int index = -1,i,c = [array count];
    val->time = FLT_MAX;
    for(i=0;i<c;i++){
        if(bytes[i].time < val->time){index = i;val->time = bytes[i].time;val->strength = bytes[i].strength;}
    }
    return index;
}

@implementation SIMInputChannel

/*"
    SIMInputChannel extends SIMChannel to handle input through connections.  These connections may have a strength, latency and
    channel type associated with them.  When a connection is updated, the method updateFrom:to:withConnection:dt:time: is invoked.
    The SIMInputChannel gathers all input for the current time step before processing and transforming it into a channel response 
    (or output current).
"*/

- init
/*"
    Initializes the channel.  After calling init for the superclass,
    this method extracts the delay parameter dictionary from the main dictionary.
"*/
{
    [super init];
    [self _delaySetup];
    return self;
}

- initWithDescription:(NSDictionary *)dict
{
    [super initWithDescription:dict];
    [self _delaySetup];
    return self;
}

- (void)_delaySetup
{
    delayDictionary = [mainDictionary objectForKey:SIMDelayKey];
    if(delayDictionary){
        delayDictionary = [delayDictionary mutableCopy];
        [mainDictionary setObject:delayDictionary forKey:SIMDelayKey];
    }
}

- (void) updateVariableIndexes
{
    [super updateVariableIndexes];
    INPUT_INDEX = [self indexOfVariable:@"INPUT"];
    
    if(INPUT_STATISTICS){
        INPUT_COUNT = [self indexOfVariable:@"INPUT_COUNT"];
        INPUT_WEIGHT = [self indexOfVariable:@"INPUT_WEIGHT"];
        INPUT_LATENCY = [self indexOfVariable:@"INPUT_LATENCY"];

        if((INPUT_COUNT == NSNotFound) || (INPUT_WEIGHT == NSNotFound) || (INPUT_LATENCY == NSNotFound)){
            NSMutableDictionary *variables = [[mainDictionary objectForKey:SIMVariablesKey] mutableCopy];
            NSNumber *index1 = [NSNumber numberWithInt:[self numVariables]];
            NSNumber *index2 = [NSNumber numberWithInt:[self numVariables]+1];
            NSNumber *index3 = [NSNumber numberWithInt:[self numVariables]+2];
            NSMutableDictionary *varDesc1 = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"int",SIMTypeKey,index1,SIMIndexKey,nil];
            NSMutableDictionary *varDesc2 = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"double",SIMTypeKey,index2,SIMIndexKey,nil];
            NSMutableDictionary *varDesc3 = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"double",SIMTypeKey,index3,SIMIndexKey,nil];
            [variables setObject:varDesc1 forKey:@"INPUT_COUNT"];
            [variables setObject:varDesc2 forKey:@"INPUT_WEIGHT"];
            [variables setObject:varDesc3 forKey:@"INPUT_LATENCY"];
            [mainDictionary setObject:variables forKey:SIMVariablesKey];
            INPUT_COUNT = [self indexOfVariable:@"INPUT_COUNT"];
            INPUT_WEIGHT = [self indexOfVariable:@"INPUT_WEIGHT"];
            INPUT_LATENCY = [self indexOfVariable:@"INPUT_LATENCY"];
        }
    }

    if(DELAY){
        [self setRandomNumberSeed:1];
        INPUT_QUEUE = [self indexOfVariable: SIMChannelInputQueue];
        if(INPUT_QUEUE == NSNotFound){
            NSMutableDictionary *variables = [[mainDictionary objectForKey:SIMVariablesKey] mutableCopy];
            NSNumber *queueIndex = [NSNumber numberWithInt:[self numVariables]];
            NSMutableDictionary *varDesc = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"id",SIMTypeKey,queueIndex,SIMIndexKey,nil];
            [variables setObject:varDesc forKey:SIMChannelInputQueue];
            [mainDictionary setObject:variables forKey:SIMVariablesKey];
            INPUT_QUEUE = [self indexOfVariable:SIMChannelInputQueue];
        }
    }
}

- (void) setRandomNumberSeed:(int)seed
{
    [super setRandomNumberSeed:seed];
    
    if (_chanRandomDelayGenerator) [_chanRandomDelayGenerator release];
    _chanRandomDelayGenerator = [[PRNGenerator gaussianGenerator] retain];
    [_chanRandomDelayGenerator setMean:meanDelay];
    [_chanRandomDelayGenerator setStd:stdDelay];
    [_chanRandomDelayGenerator setSeed: seed+1];
}


- (void) setRandomValuesForState: (SIMState *) element
/*"
    Sets state variables (input and output potential) in element to
    random values with a uniform distribution (using %stateGenerator).
    Subclasses that define additional variables should implement as appropriate.
"*/
{
//    element->INPUTCHANNEL[OUTPUT_INDEX].state.doubleValue = [stateGenerator uniformDeviate];
//    element->INPUTCHANNEL[INPUT_INDEX].state.doubleValue = [stateGenerator uniformDeviate];
}

- (void) setNullValuesForState: (SIMState *) element
/*"
    Sets state variables (input and output potential) in element to zero.
    Subclasses that define additional variables should implement as appropriate.
"*/
{
    element->INPUTCHANNEL[INPUT_INDEX].state.doubleValue = 0.0;
    element->INPUTCHANNEL[OUTPUT_INDEX].state.doubleValue = 0.0;
    
    if(INPUT_STATISTICS){
        element->INPUTCHANNEL[INPUT_COUNT].state.intValue = 0;
        element->INPUTCHANNEL[INPUT_WEIGHT].state.doubleValue = 0.0;
        element->INPUTCHANNEL[INPUT_LATENCY].state.doubleValue = 0.0;
    }

    if(DELAY){
        [element->INPUTCHANNEL[INPUT_QUEUE].state.objectValue removeAllObjects];
    }
}

- (void) setInitialValuesForState: (SIMState *) element
{
/*"
    Initialises state variables (input and output potential) in element
    by setting them to zero.  Subclasses that define additional variables
    should implement as appropriate.
"*/
    element->INPUTCHANNEL[INPUT_INDEX].state.doubleValue = 0.0;
    element->INPUTCHANNEL[OUTPUT_INDEX].state.doubleValue = 0.0;

    if(DELAY){
        [element->INPUTCHANNEL[INPUT_QUEUE].state.objectValue removeAllObjects];
    }
}

- (oneway void) updateParameters
/*"
    This method retrieves parameter values for the channel.  If the object has a delay
"*/
{
    [super updateParameters];
    delayDictionary = [mainDictionary objectForKey:SIMDelayKey];
    
    INPUT_STATISTICS = [self boolForKey:SIMInputStatisticsFlag];
    
    if(delayDictionary){
        DELAY = [delayDictionary boolForKey:SIMActiveKey];
    }
    if(DELAY){
        meanDelay = [delayDictionary floatForKey:SIMMeanKey];
        stdDelay = [delayDictionary floatForKey:SIMStdKey];

		//if((meanDelay <= 0.0) && (stdDelay <= 0.0)){DELAY = NO; return;}

        [_chanRandomDelayGenerator setMean: meanDelay];
        [_chanRandomDelayGenerator setStd: stdDelay];
    }
}

- (void) initUserState
{
/*"
    Allocates a local state useful for calculations.  Needs to be called
    during initialisation by any subclass that uses one of the
    #{updateStateUsingXXX:dt:time:} methods instead of #{updateState:dt:time:}.
"*/
    int n = [self numVariables];

    if (!userState.inputChannel) {
        userState.inputChannel = NSZoneCalloc([self zone],(_assignedIndex+1),sizeof(SIMStateValue *));
        [self allocState:&userState];  
    }
    
    dym = calloc(n,sizeof(SIMStateValue));
    dyt = calloc(n,sizeof(SIMStateValue));
    yt = calloc(n,sizeof(SIMStateValue));

}

- (void) initializeConnection:(SIMConnection *)connection toState:(SIMState *)element
{
    if(INPUT_STATISTICS){
        if(INPUT_COUNT != 0) // be sure these are not zero.
            element->INPUTCHANNEL[INPUT_COUNT].state.intValue++;
        if(INPUT_WEIGHT != 0) // be sure these are not zero.
            element->INPUTCHANNEL[INPUT_WEIGHT].state.doubleValue += (double)connection->strength;    
        if(INPUT_LATENCY != 0) // be sure these are not zero.
            element->INPUTCHANNEL[INPUT_LATENCY].state.doubleValue += (double)connection->latency;
    }
}

- (double) doubleValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	int index;
	if((index = [self indexOfVariable:var])!= NSNotFound)
		return state->INPUTCHANNEL[index].state.doubleValue;
	else return (double)SIM_UndefinedState;
}

- (float) floatValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	int index;
	if((index = [self indexOfVariable:var])!= NSNotFound)
		return state->INPUTCHANNEL[index].state.floatValue;
	else return (float)SIM_UndefinedState;
}

- (int) intValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	int index;
	if((index = [self indexOfVariable:var])!= NSNotFound)
		return state->INPUTCHANNEL[index].state.intValue;
	else return (int)SIM_UndefinedState;
}

- (SIMActivityStateValue) activityValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	int index;
	if((index = [self indexOfVariable:var])!= NSNotFound)
		return state->INPUTCHANNEL[index].state.activityValue;
	else return SIM_UndefinedState;
}


- (int) totalNumberOfInputs:(SIMState *)element
{
    return (INPUT_STATISTICS)?element->INPUTCHANNEL[INPUT_COUNT].state.intValue:0;
}

- (float) totalWeightOfInputs:(SIMState *)element
{
    return (INPUT_STATISTICS)?element->INPUTCHANNEL[INPUT_WEIGHT].state.doubleValue:0.0;
}

- (float) totalLatencyOfInputs:(SIMState *)element
{
    return (INPUT_STATISTICS)?element->INPUTCHANNEL[INPUT_LATENCY].state.doubleValue:0.0;
}

- (void) updateFrom:(SIMState *)from to:(SIMState *)to 
	withConnection:(SIMConnection *)connection dt:(float)dt time:(float)t
/*"
    All input arrives at a channel via this routine. The %from variable
    contains the state of the projecting element.  The variable,
    %to, contains the state of the receiving element.
    This method is completed by a subclass which defines a new
    Channel model.  The Network object calls this when a cell
    is in the Firing or Spiking state.  If this channel has a delay the
    current input value is added to the queue for the current time + a delay.
    The input value is then reset to 0.  If the SynthesisCore framework is compiled with
    CONNECTION_LATENCIES defined to be true then the latency assigned to each connection will be used as the fixed latency.
"*/
{
    if(DELAY){
        DelayedInput input;
        float delay = (float)[_chanRandomDelayGenerator nextDouble];

        input.time = t;
        
        // If we're using connection latencies, take the delay directly from that.
        input.time += floor(connection->latency/dt +.5)*dt;

        // Note: called only when from is firing.
        // adjust delay by amount distributed according to _chanRandomDelayGenerator

        // Delays are in units of dt
        input.time += floor(delay/dt +.5)*dt; //should round to nearest multiple of dt

        input.strength = to->INPUTCHANNEL[INPUT_INDEX].state.doubleValue;
        [self _addToQueue:&input forElement: to];
        to->INPUTCHANNEL[INPUT_INDEX].state.doubleValue = 0.0;
    }
}

- (void) updateState: (SIMState *) element dt: (float) dt  time: (float) time;
/*"
    If delays are active for this channel, the current value of the input state variable
    is updated with any events in the queue for the current time step.  This should be called
    by any subclasses that wish to support delays.
"*/
{
    if(DELAY){
        DelayedInput input;
        // while there's something in the INPUT_QUEUE -- add the value to the channel input
        while ([self _nextQueueValue:&input forElement: element atTime:time]){
            // "fire"
            element->INPUTCHANNEL[INPUT_INDEX].state.doubleValue += input.strength;
        }
    }
    [super updateState:element dt:dt time:time];
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
        userState.INPUTCHANNEL, element->INPUTCHANNEL,time,element);

    for(i=0;i<numEqs;i++){
        if((element->INPUTCHANNEL[i].type < SIMObjectType) && (userState.INPUTCHANNEL[i].state.doubleValue != 0))
            element->INPUTCHANNEL[i].state.doubleValue += dt*userState.INPUTCHANNEL[i].state.doubleValue;
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

    evaluateDerivatives(self,@selector(evaluateDerivatives:initialValues:time:context:),userState.INPUTCHANNEL,element->INPUTCHANNEL,time,element);
    evaluateRungeKutta4 (numEqs, time, dt, element->INPUTCHANNEL,userState.INPUTCHANNEL,element->INPUTCHANNEL, dym, dyt, yt, evaluateDerivatives, self, @selector(evaluateDerivatives:initialValues:time:context:), element);
}


- (double) channelCurrent: (SIMState *)element forCellModel:(SIMCell *)cellModel
/*"
    The default implementation of this returns the output as a double.
    In subclasses this could be updated to calculate the current using the membrane potential
    of the cell at the given index.  This allows conductance-based channel channels.
"*/
{
    return element->INPUTCHANNEL[OUTPUT_INDEX].state.doubleValue;
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
	return @"SIMInputChannel";
}

- (void) archiveState:(SIMState *)element withCoder:(NSCoder *)coder
{
    int index,count = [self numVariables];
    for(index = 0; index < count;index++){
        [coder encodeStateValue:&element->INPUTCHANNEL[index]];
    }
}

- (void) unarchiveState:(SIMState *)element withCoder:(NSCoder *)coder
{
    int index,count = [self numVariables];
    for(index = 0; index < count;index++){
        [coder decodeStateValue:&element->INPUTCHANNEL[index]];
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
    element->INPUTCHANNEL = (SIMStateValue *) NSZoneCalloc ([self zone], count, sizeof(SIMStateValue));

    for (i=0; i < count; i++){
        NSString *varName = [self variableAtIndex:i];
        element->INPUTCHANNEL[i].type = [self typeForVariable:varName];
    }

    if(DELAY){
        NSMutableArray *obj = [[NSMutableValueArray valueArrayWithObjCType: @encode (DelayedInput)] retain];
        element->INPUTCHANNEL[INPUT_QUEUE].state.objectValue = obj;
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
    element->INPUTCHANNEL = (SIMStateValue *) NSZoneRealloc ([self zone], element->INPUTCHANNEL, count * sizeof(SIMStateValue));

    for (i=0; i < count; i++){
        NSString *varName = [self variableAtIndex:i];
        element->INPUTCHANNEL[i].type = [self typeForVariable:varName];
    }

 //   if(DELAY){
 //       element->INPUTCHANNEL[INPUT_QUEUE].state.objectValue = [[NSMutableValueArray valueArrayWithObjCType: @encode (DelayedInput)] retain];
 //   }
}


- (void) deallocState: (SIMState *) element
/*"
    Deallocates the memory used to store state variables in the SIMState
    element.  The default implementation frees the memory that has been
    allocated for %{element.INPUTCHANNEL[]}.

    If anything other than the state variables (sizeof(double)) is
    to be stored inside this structure, this method must be overridden and the
    extra space deallocated.
"*/
{
	// each subclass that stores anything extra inside the state struct
	// must deallocate it itself.

    if(DELAY){
        if (element->INPUTCHANNEL[INPUT_QUEUE].state.objectValue)[element->INPUTCHANNEL[INPUT_QUEUE].state.objectValue release];
        element->INPUTCHANNEL[INPUT_QUEUE].state.objectValue = nil;
    }
    
    if (element->type != SIM_UndefinedType)
            NSZoneFree ([self zone], element->INPUTCHANNEL);

}

- (id)initWithCoder:(NSCoder *)coder
/*"
    Initializes a new instance of this class from coder.
"*/
{
    self = [super initWithCoder:coder];
    [self _delaySetup];
    return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
    [super encodeWithCoder:coder];
}

@end

@implementation SIMInputChannel(SIMChannelDelayExtension)


- (void) _addToQueue: (DelayedInput *) input forElement: (SIMState *) element
{
        NSMutableValueArray *q = element->INPUTCHANNEL[INPUT_QUEUE].state.objectValue;
        int i,c,index = -1;

        assert(q);
        c = [q count];
        DelayedInput *bytes = (DelayedInput *)[q mutableBytes];

        for(i = 0; i < c; i++){ // Assume that queue entries tend to be later in time
            if(bytes[i].time == input->time) {index = i;break;}
        }
        if(index < 0){
            [q addValue:input]; // If no event at this same time add a new one
        }
        else bytes[index].strength += input->strength; // otherwise accumulate the input
}

- (BOOL) _nextQueueValue:(DelayedInput *)val forElement: (SIMState *) element atTime:(float)t
{
        // returns the value at head of INPUT_QUEUE; if it is <= 0 removes it
        NSMutableValueArray *q = element->INPUTCHANNEL[INPUT_QUEUE].state.objectValue;
		
		assert (q);

		int c = [q count];
        if (c > 0){
            int index = indexOfNextTime(q,val);
            if ((index >= 0) && (val->time <= t)){
                [q removeValueAtIndex:index];
                return YES;
            }
        }
        return NO;
}

@end

