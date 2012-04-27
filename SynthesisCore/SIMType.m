/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */


#import <SynthesisCore/SIMType.h>
#import <SynthesisCore/SIMCategories.h>
#import <SynthesisCore/SIMPatternMatch.h>

@implementation SIMType
/*"
	This object encapsulates many operations for accessing and updating the network
	states using the appropriate channel and cell models.  Currently it directly 
	accesses the state structures for speed, but this could be updated to use the
	models instead.  For example, setting the membrane potential for a cell consists
	of taking the state structure and assigning the value to the value at the
	membrane potential index.  However it could be done via a call to the cell
	model, thus giving more control to the model developer.  At this time it is left
	as-is to provide simplicity and speed.
"*/

#define raiseInvalidCellModelException() \
        [NSException raise: NSGenericException \
            format:@"%@: Unable to initialize cell model", \
            [cellDictionary description]];

#define raiseInvalidChannelModelException() \
        [NSException raise: NSGenericException \
            format:@"%@: Unable to initialize channel model", \
            [channelDictionary description]];

+ new
/*"
        Returns a new autoreleased instance of a default SIMType object.
"*/
{
    return [[[SIMType alloc] init] autorelease];
}

- init
// Convenience method for initializing a new Type object without predefining everything.
// All the models will need to be instantiated as they are defined.
{
    return [self initWithDescription:nil];
}

- initWithDescription:(NSDictionary *)typeDescription
{
    return [self initWithDescription:typeDescription usingModelLibrary:nil];
}

- initWithDescription:(NSDictionary *)typeDescription usingModelLibrary:(NSDictionary *)modelDict
/*"
	Initializes the Type object.  This loads a dictionary from the template file
	for SIMType (or its subclass) and adds the entries from typeDescription.
	It then instantiates all the models (channel, cell and connection models) described
	in the dictionary.
"*/
{
    NSString *templatePath;
    NSString *className = NSStringFromClass([self class]);

    if(!modelDict)modelLibraryDict = [[NSDictionary dictionary] retain];
    else modelLibraryDict = [modelDict retain];

    templatePath = [[NSBundle bundleForClass:[self class]]
        pathForResource:className ofType:TEMPLATE_EXTENSION];
    NSAssert1(templatePath,@"Template file must exist in the bundle for the class: %@",className);
    typeDictionary = [[NSMutableDictionary dictionaryWithContentsOfFile:templatePath] retain];
    
    [typeDictionary setObject:className forKey:SIMClassNameKey];
    _assignedIndex = [typeDictionary intForKey:SIMIndexKey];

    cellCompartmentClasses = [[NSMutableSet set] retain];
    inputChannelClasses = [[NSMutableSet set] retain];
    intrinsicChannelClasses = [[NSMutableSet set] retain];
    connectionsClasses = [[NSMutableSet set] retain];
    
    if(typeDescription){
        [typeDictionary addEntriesFromDictionary:typeDescription];
        [self _instantiateModelsWithLibrary:modelDict];
    }
    
    userState = (SIMState *)NSZoneMalloc([self zone],sizeof(SIMState));
        
    [self allocState:userState];
    	
    return self;
}

- (void) initModelsWithNetwork:(SIMNetwork *)net randomSeed:(int)seed
/*"
    Initializes the internal states needed for each channel and cell model
    (See SIMModel method -initModelWithNetwork:).
"*/
{
    int i;
    SIMModel *model;
    NSDictionary *dict,*connectionModels;
    NSEnumerator *modelEnum;
	
	network = net;
    
    for(i = 0; i < numIntrinsicChannels; i++){
        [intrinsicChannels[i] initializeWithCellType:self];
        [intrinsicChannels[i] setRandomNumberSeed:seed++];
    }
    for(i = 0; i < numInputChannels; i++){
		[inputChannels[i] initializeWithCellType:self];
        [inputChannels[i] setRandomNumberSeed:seed++];
    }
    for(i = 0; i < numCellCompartments; i++){
		[cellCompartments[i] initializeWithCellType:self];
        [cellCompartments[i] setRandomNumberSeed:seed++];
    }
    connectionModels = [self efferentConnectionModels];
    modelEnum = [connectionModels objectEnumerator];
    while(dict = [modelEnum nextObject]){
        model = [dict objectForKey:SIMConnectionsModelKey];
		[model initializeWithCellType:self];
        [model setRandomNumberSeed:seed++];
    }
    connectionModels = [self afferentConnectionModels];
    modelEnum = [connectionModels objectEnumerator];
    while(dict = [modelEnum nextObject]){
        model = [dict objectForKey:SIMConnectionsModelKey];
		[model initializeWithCellType:self];
        [model setRandomNumberSeed:seed++];
    }
}

- (SIMNetwork *)network
{
	return network;
}

- (void)setInitialState:(SIMState *)element
/*"
    Sets the states of element to appropriate initial values using each channel and cell model
    It passes the position so that position-based parameters may be set.  
	(See SIMModel method -setInitialValuesForState:).
"*/
{
    int i;
    for(i = 0; i < numIntrinsicChannels; i++){
        [intrinsicChannels[i] setInitialValuesForState:element];
    }
    for(i = 0; i < numInputChannels; i++){
        [inputChannels[i] setInitialValuesForState:element];
    }
    for(i = 0; i < numCellCompartments; i++){
        [cellCompartments[i] setInitialValuesForState:element];
    }
}

- (void)setRandomState:(SIMState *)element
/*"
    Sets the states of element to random values using each channel and cell model
    (See SIMModel method -setRandomValuesForState:).
"*/
{
    int i;
    for(i = 0; i < numIntrinsicChannels; i++){
        [intrinsicChannels[i] setRandomValuesForState:element];
    }
    for(i = 0; i < numInputChannels; i++){
        [inputChannels[i] setRandomValuesForState:element];
    }
    for(i = 0; i < numCellCompartments; i++){
        [cellCompartments[i] setRandomValuesForState:element];
    }
}

- (void)setNullState:(SIMState *)element
/*"
    Sets the states of element to null values using each channel and cell model
    (See SIMModel method -setNullValuesForState:).
"*/
{
    int i;
    for(i = 0; i < numIntrinsicChannels; i++){
        [intrinsicChannels[i] setNullValuesForState:element];
    }
    for(i = 0; i < numInputChannels; i++){
        [inputChannels[i] setNullValuesForState:element];
    }
    for(i = 0; i < numCellCompartments; i++){
        [cellCompartments[i] setNullValuesForState:element];
    }
}

- (void)updateCellState:(SIMState *)element dt:(float)dt time:(float)t
/*"
    Updates the states of element using each cell model
    (See SIMCell method -updateState:dt:time:)
"*/
{
    int i;
    for(i = 0; i < numCellCompartments; i++){
        [cellCompartments[i] updateState:element dt:dt time:t];
    }
}

- (void)updateIntrinsicChannelState:(SIMState *)element dt:(float)dt time:(float)t
/*"
	Updates the states of element using each intrinsicChannel model 
	(See SIMChannel method -updateState:dt:time:)
"*/
{
    int i;
    for(i = 0; i < numIntrinsicChannels; i++){
        [intrinsicChannels[i] updateState:element dt:dt time:t];
    }
}

- (void)updateInputChannelState:(SIMState *)element dt:(float)dt time:(float)t
/*"
	Updates the states of element using each inputChannel model 
	(See SIMChannel method -updateState:dt:time:)
"*/
{
    int i;
    for(i = 0; i < numInputChannels; i++){
        [inputChannels[i] updateState:element dt:dt time:t];
    }
}

- (void)updateConnection:(SIMConnection *)connection fromState:(SIMState *)projectingState 
	toState:(SIMState *)destinationState dt:(float)dt time:(float)currentTime
/*"
	Uses the channel model at the index determined by connection->type to update the
	destinationState using the information from projectingState (if needed).  The
	currentTime and dt (time step) are passed to the channel (See SIMChannel
	method -updateFrom:to:withConnection:dt:time:).
"*/
{
    int i;

//    while(connection->channels[i] != SIM_UndefinedChannel){
    
    for(i = 0; i < connection->channelCount; i++){
        [(SIMInputChannel *)inputChannels[connection->channels[i]] updateFrom:projectingState
            to:destinationState withConnection:connection dt:dt time:currentTime];
    }
}

- (void)initializeConnection:(SIMConnection *)connection toState:(SIMState *)element
{
    int i;
    
    for(i = 0; i < connection->channelCount; i++){
        [(SIMInputChannel *)inputChannels[connection->channels[i]] initializeConnection:connection toState:element];
    }
}

- (double) summedChannelCurrents:(SIMState *)element forCellModel:(SIMCell *)cellModel
/*"
    Returns the summed output currents of each channel represented in element.
    This should be used by all cell models that need a value representing the input
    to a cell.  A subclass could reimplement this method to provide a more sophisticated method of integration.
"*/
{
	int i;
	register double sum = 0.0;
	for(i = 0; i < numIntrinsicChannels; i++){
            sum += [intrinsicChannels[i] channelCurrent:element forCellModel:cellModel];
	}
	for(i = 0; i < numInputChannels; i++){
            sum += [inputChannels[i] channelCurrent:element forCellModel:cellModel];
	}
	return sum;
}

- (double) summedIntrinsicChannelCurrents:(SIMState *)element forCellModel:(SIMCell *)cellModel
/*"
    Returns the summed output currents of each channel represented in element.
    This should be used by all cell models that need a value representing the input
    to a cell.  A subclass could reimplement this method to provide a more sophisticated method of integration.
"*/
{
	int i;
	register double sum = 0.0;
	for(i = 0; i < numIntrinsicChannels; i++){
            sum += [intrinsicChannels[i] channelCurrent:element forCellModel:cellModel];
	}
	return sum;
}

- (double) summedInputChannelCurrents:(SIMState *)element forCellModel:(SIMCell *)cellModel
/*"
    Returns the summed output currents of each channel represented in element.
    This should be used by all cell models that need a value representing the input
    to a cell.  A subclass could reimplement this method to provide a more sophisticated method of integration.
"*/
{
	int i;
	register double sum = 0.0;
	for(i = 0; i < numInputChannels; i++){
            sum += [inputChannels[i] channelCurrent:element forCellModel:cellModel];
	}
	return sum;
}

- (double) summedAbsoluteInputChannelCurrents:(SIMState *)element forCellModel:(SIMCell *)cellModel
/*"
    Returns the summed output currents of each channel represented in element.
    This should be used by all cell models that need a value representing the input
    to a cell.  A subclass could reimplement this method to provide a more sophisticated method of integration.
"*/
{
	int i;
	register double sum = 0.0;
	for(i = 0; i < numInputChannels; i++){
            sum += abs([inputChannels[i] channelCurrent:element forCellModel:cellModel]);
	}
	return sum;
}

- (double) intrinsicChannelCurrent:(SIMState *)element atIndex:(int)index forCellModel:(SIMCell *)cellModel
{
    return [intrinsicChannels[index] channelCurrent:element forCellModel:cellModel];
}

- (double) intrinsicChannelCurrent:(SIMState *)element forKey:(NSString *)key forCellModel:(SIMCell *)cellModel
{
    int index = [self indexOfIntrinsicChannel:key];
    return [intrinsicChannels[index] channelCurrent:element forCellModel:cellModel];
}

- (double) intrinsicChannelCurrent:(SIMState *)element forKey:(NSString *)key compartment:(int)cellIndex
{
	assert(cellIndex < numIntrinsicChannels);
    int index = [self indexOfIntrinsicChannel:key];
    SIMCell *cellModel = [self cellCompartmentAtIndex:cellIndex];
	assert(cellModel != nil);
    return [intrinsicChannels[index] channelCurrent:element forCellModel:cellModel];
}

- (double) inputChannelCurrent:(SIMState *)element atIndex:(int)index forCellModel:(SIMCell *)cellModel
{
    return [inputChannels[index] channelCurrent:element forCellModel:cellModel];
}

- (double) inputChannelCurrent:(SIMState *)element forKey:(NSString *)key forCellModel:(SIMCell *)cellModel
{
    int index = [self indexOfInputChannel:key];
    return [inputChannels[index] channelCurrent:element forCellModel:cellModel];
}

- (double) inputChannelCurrent:(SIMState *)element forKey:(NSString *)key compartment:(int)cellIndex
{
    int index = [self indexOfInputChannel:key];
    SIMCell *cellModel = [self cellCompartmentAtIndex:cellIndex];
    return [inputChannels[index] channelCurrent:element forCellModel:cellModel];
}

/*
- (void) applyInput:(double)val toCell:(SIMState *)element atIndex:(int)index
{
    if((index >= 0) && (index < numCellCompartments))
        [cellCompartments[index] applyInput:val forState:element];
}

- (void) applyInput:(double)val toCell:(SIMState *)element
{
        [cellCompartments[0] applyInput:val forState:element];
}

- (void) applyInput:(double)val toChannel:(SIMState *)element atIndex:(int)index
{
	if((index >= 0) && (index < numChannelModels))
    	[channelModels[index] applyInput:val forState:element];
}

- (void) applyInput:(double)val toChannel:(SIMState *)element
{
        [channelModels[0] applyInput:val forState:element];
}
*/

- (void) setMembranePotential:(double)val forCell:(SIMState *)element
{
    element->cell[0][CELL_POTENTIAL_INDEX].state.doubleValue = val;
}

- (void) setMembranePotential:(double)val forCell:(SIMState *)element atIndex:(int)index
{
    if((index >= 0) && (index < numCellCompartments))
        element->cell[index][CELL_POTENTIAL_INDEX].state.doubleValue = val;
}

- (double) membranePotential:(SIMState *)element
{
/* This could be updated to average all compartments or ... */
    return [cellCompartments[0] membranePotential:element];
}

- (double) membranePotential:(SIMState *)element atIndex:(int)index
/*"
	Returns the membrane potential state variable for the cell at index.
"*/
{
    return 
((index >= 0) && (index < numCellCompartments))? element->cell[index][CELL_POTENTIAL_INDEX].state.doubleValue:FLT_MIN;
}

- (BOOL) shouldCellUpdateConnections:(SIMState *)state
{
    return [cellCompartments[numCellCompartments-1] shouldCellUpdateConnections:state];
    // return (state->cell[numCellCompartments-1][CELL_STATE_INDEX].state.activityValue > SIM_FiringState)? YES:NO;
}

- (BOOL) isCellFiring:(SIMState *)state
/*"
	This method checks to see if the last compartment is firing or spiking.
	In other words, is the state value greater than or equal to #SIM_FiringState.
"*/
{
    return (state->cell[numCellCompartments-1][CELL_STATE_INDEX].state.activityValue & SIM_FiringState)? YES:NO;
}

- (BOOL) isCellSpiking:(SIMState *)state
/*"
    This method checks to see if the cell is spiking (i.e. it's state has been set to
	#SIM_SpikingState ).
"*/
{
    return (state->cell[numCellCompartments-1][CELL_STATE_INDEX].state.activityValue & SIM_SpikingState)? YES:NO;
}

- (BOOL) isCellRefractory:(SIMState *)state
/*"
    This method checks to see if the cell is refractory (i.e. it's state has been set to
    #SIM_RefractoryState ).
"*/
{
    return (state->cell[numCellCompartments-1][CELL_STATE_INDEX].state.activityValue & SIM_RefractoryState)? YES:NO;
}

- (BOOL) isCellMiniSpiking:(SIMState *)state
/*"
    This method checks to see if the cell is resting (i.e. it's state has been set to
    #SIM_MiniSpikeState ).
"*/
{
    return (state->cell[numCellCompartments-1][CELL_STATE_INDEX].state.activityValue & SIM_MiniSpikeState)? YES:NO;
}

- (BOOL) isCellResting:(SIMState *)state
/*"
    This method checks to see if the cell is resting (i.e. it's state has been set to
    #SIM_RestingState ).
"*/
{
    return (state->cell[numCellCompartments-1][CELL_STATE_INDEX].state.activityValue & SIM_RestingState)? YES:NO;
}

- (SIMActivityStateValue) cellActivityStateValue:(SIMState *)state
/*"
	Returns the value of the state of the last compartment model for the cell.  This is
	used to determine if the cell is firing and it should send an action potential to all cells
	to which it is connected.
"*/

{
    return (state->cell[numCellCompartments-1][CELL_STATE_INDEX].state.activityValue);
}

- (float) percentage
/*"
    Returns the percentage of the current layer that this type should be used for.  This is
    used by the Network object when it distributes the types among the cells in the layer.
    The network uses this value to determine the fraction of cells to assign to this type.
"*/
{
    return percentage;
}

- (void) setPercentage:(float)val
/*"
	Sets the percentage of elements in this layer that should be of this type.
"*/
{
    percentage = val;
}

- (int) numCellCompartments
/*"
    Returns the number of cell compartment models used by this type.
"*/
{
	return numCellCompartments;
}

- (int) numInputChannels
/*"
    Returns the number of channel models used by this type.
"*/
{
	return numInputChannels;
}

- (int) numIntrinsicChannels
/*"
    Returns the number of channel models used by this type.
"*/
{
	return numIntrinsicChannels;
}

- (int) totalNumberOfInputs:(SIMState *)element
{
    return [self totalNumberOfInputs:element fromType:@"*"];
}

- (int) totalNumberOfInputs:(SIMState *)element fromLayer:(NSString *)layerName
{
    NSString *typeString = [NSString stringWithFormat:@"%@.*.*",layerName];
    return [self totalNumberOfInputs:element fromType:typeString];
}

- (int) totalNumberOfInputs:(SIMState *)element fromType:(NSString *)typeString
{
    NSArray *types = [NSArray arrayWithObject:typeString];
    return [self totalNumberOfInputs:element fromTypes:types];
}

- (int) totalNumberOfInputs:(SIMState *)element fromTypes:(NSArray *)types
{
    NSEnumerator *typeEnum = [types objectEnumerator];
    NSEnumerator *inputEnum = [[self allInputChannelKeys] objectEnumerator];
    NSString *key;
    NSString *type;
    int count = 0;
    
    while(type = [typeEnum nextObject]){
        while(key = [inputEnum nextObject]){
            if(!SIMPatternMatch([type UTF8String],[key UTF8String],NULL)){
                int index = [self indexOfInputChannel:key];
                count += [inputChannels[index] totalNumberOfInputs:element];
            }
        }
    }
    return count;
}

- (float) totalWeightOfInputs:(SIMState *)element
{
    return [self totalWeightOfInputs:element fromType:@"*"];
}

- (float) totalWeightOfInputs:(SIMState *)element fromLayer:(NSString *)layerName
{
    NSString *typeString = [NSString stringWithFormat:@"%@.*.*",layerName];
    return [self totalWeightOfInputs:element fromType:typeString];
}

- (float) totalWeightOfInputs:(SIMState *)element fromType:(NSString *)typeString
{
    NSArray *types = [NSArray arrayWithObject:typeString];
    return [self totalWeightOfInputs:element fromTypes:types];
}

- (float) totalWeightOfInputs:(SIMState *)element fromTypes:(NSArray *)types
{
    NSEnumerator *typeEnum = [types objectEnumerator];
    NSEnumerator *inputEnum = [[self allInputChannelKeys] objectEnumerator];
    NSString *key;
    NSString *type;
    float weight = 0;
    
    while(type = [typeEnum nextObject]){
        while(key = [inputEnum nextObject]){
            if(!SIMPatternMatch([type UTF8String],[key UTF8String],NULL)){
                int index = [self indexOfInputChannel:key];
                weight += [inputChannels[index] totalWeightOfInputs:element];
            }
        }
    }
    return weight;
}

- (float) totalLatencyOfInputs:(SIMState *)element
{
    return [self totalLatencyOfInputs:element fromType:@"*"];
}

- (float) totalLatencyOfInputs:(SIMState *)element fromLayer:(NSString *)layerName
{
    NSString *typeString = [NSString stringWithFormat:@"%@.*.*",layerName];
    return [self totalLatencyOfInputs:element fromType:typeString];
}

- (float) totalLatencyOfInputs:(SIMState *)element fromType:(NSString *)typeString
{
    NSArray *types = [NSArray arrayWithObject:typeString];
    return [self totalLatencyOfInputs:element fromTypes:types];
}

- (float) totalLatencyOfInputs:(SIMState *)element fromTypes:(NSArray *)types
{
    NSEnumerator *typeEnum = [types objectEnumerator];
    NSEnumerator *inputEnum = [[self allInputChannelKeys] objectEnumerator];
    NSString *key;
    NSString *type;
    float latency = 0;
    
    while(type = [typeEnum nextObject]){
        while(key = [inputEnum nextObject]){
            if(!SIMPatternMatch([type UTF8String],[key UTF8String],NULL)){
                int index = [self indexOfInputChannel:key];
                latency += [inputChannels[index] totalLatencyOfInputs:element];
            }
        }
    }
    return latency;
}

- (NSString *)name
/*"
    Returns the name assigned to this type.
"*/
{
	return typeName;
}

- (void)setName:(NSString *)name
/*"
    Assigns name to this type.
"*/
{
    if(typeName)[typeName release];
    typeName = [name copy];
}

- (SIMCell *)cellCompartmentWithName:(NSString *)name
/*"
    Returns the cell model for key name in the cell model dictionary.
"*/

{
	return [cellCompartmentsDict objectForKey:name];
}

- (SIMCell *) cellCompartmentAtIndex:(int)index
/*"
    Returns the cell model at a particular index in the cell model dictionary.
"*/
{
    return cellCompartments[index];
}

- (void) addIntrinsicChannel:(NSString *)modelKey withDescription:(NSDictionary *)descDict
{   
	NSMutableDictionary *modelDict = [descDict mutableCopy];
	if(!intrinsicChannelsDict){
		intrinsicChannelsDict = [[NSMutableDictionary dictionary] retain];
		[typeDictionary setObject:[intrinsicChannelsDict autorelease] forKey:SIMIntrinsicChannelsKey];
	}
	
    intrinsicChannels = (SIMChannel **)NSZoneRealloc ([self zone],intrinsicChannels,++numIntrinsicChannels*sizeof(SIMChannel *));
    if(!inputChannels)NSLog(@"Out of memory while allocating channel models.");

		int modelIndex = numIntrinsicChannels-1;
        //[modelDict setObject:[NSNumber numberWithInt:modelIndex] forKey:SIMIndexKey];

        id theObjectClass = [modelDict channelClassForKey: SIMClassNameKey];
        if(theObjectClass)[intrinsicChannelClasses addObject:[modelDict objectForKey: SIMClassNameKey]];
        else {
            NSLog(@"Couldn't load class: %@",[modelDict objectForKey: SIMClassNameKey]);
            return;
        }
        id theObject = [(SIMChannel *)[theObjectClass alloc] initWithDescription: modelDict];
        if (theObject != nil){
			[theObject setAssignedIndex:modelIndex];
            if([intrinsicChannelsDict objectForKey:modelKey])NSLog(@"Repeated channel %@",modelKey);
			[theObject setModelName:modelKey];
			[theObject initializeWithCellType:self];
			[intrinsicChannelsDict setObject:theObject forKey: modelKey];
            intrinsicChannels[modelIndex] = theObject;
        }
        else NSLog(@"Couldn't initialize new intrinsic channel: %@ = %@",modelKey,modelDict);
		
		[modelDict release];
    
}

- (void) addInputChannel:(NSString *)modelKey withDescription:(NSDictionary *)descDict
{   
	NSMutableDictionary *modelDict = [descDict mutableCopy];
	if(!inputChannelsDict){
		inputChannelsDict = [[NSMutableDictionary dictionary] retain];
		[typeDictionary setObject:[inputChannelsDict autorelease] forKey:SIMInputChannelsKey];
	}

    inputChannels = (SIMInputChannel **)NSZoneRealloc ([self zone],inputChannels,++numInputChannels*sizeof(SIMInputChannel *));
    if(!inputChannels)NSLog(@"Out of memory while allocating channel models.");

		int modelIndex = numInputChannels-1;
        [modelDict setObject:[NSNumber numberWithInt:modelIndex] forKey:SIMIndexKey];

        id theObjectClass = [modelDict channelClassForKey: SIMClassNameKey];
        if(theObjectClass)[inputChannelClasses addObject:[modelDict objectForKey: SIMClassNameKey]];
        else {
            NSLog(@"Couldn't load class: %@",[modelDict objectForKey: SIMClassNameKey]);
            return;
        }
        id theObject = [(SIMInputChannel *)[theObjectClass alloc] initWithDescription: modelDict];
        if (theObject){
            if([inputChannelsDict objectForKey:modelKey])NSLog(@"Repeated channel %@",modelKey);
			[theObject setModelName:modelKey];
			[theObject initializeWithCellType:self];
			[inputChannelsDict setObject:theObject forKey: modelKey];
            inputChannels[[theObject assignedIndex]] = theObject;
        }
        else NSLog(@"Couldn't initialize new input channel: %@ = %@",modelKey,modelDict);
		
		[modelDict release];
    
}

- (void) addCellCompartment:(NSString *)modelKey withDescription:(NSDictionary *)descDict
{   
	NSMutableDictionary *modelDict = [descDict mutableCopy];
	if(!cellCompartmentsDict){
		cellCompartmentsDict = [[NSMutableDictionary dictionary] retain];
		[typeDictionary setObject:[cellCompartmentsDict autorelease] forKey:SIMCellCompartmentsKey];
	}
	
    cellCompartments = (SIMCell **)NSZoneRealloc ([self zone],cellCompartments,++numCellCompartments*sizeof(SIMCell *));
    if(!inputChannels)NSLog(@"Out of memory while allocating channel models.");

		int modelIndex = numCellCompartments-1;
        [modelDict setObject:[NSNumber numberWithInt:modelIndex] forKey:SIMIndexKey];

        id theObjectClass = [modelDict channelClassForKey: SIMClassNameKey];
        if(theObjectClass)[cellCompartmentClasses addObject:[modelDict objectForKey: SIMClassNameKey]];
        else {
            NSLog(@"Couldn't load class: %@",[modelDict objectForKey: SIMClassNameKey]);
            return;
        }
        id theObject = [(SIMCell *)[theObjectClass alloc] initWithDescription: modelDict];
        if (theObject){
            if([cellCompartmentsDict objectForKey:modelKey])NSLog(@"Repeated cell compartment %@",modelKey);
			[theObject setModelName:modelKey];
			[theObject initializeWithCellType:self];
			[cellCompartmentsDict setObject:theObject forKey: modelKey];
            cellCompartments[[theObject assignedIndex]] = theObject;
        }
        else NSLog(@"Couldn't initialize new cell compartment: %@ = %@",modelKey,modelDict);
		
		[modelDict release];
    
}


- (void) addCellModel:(SIMCell *)cell withName:(NSString *)name
{
    [cellCompartmentsDict setObject:cell forKey:name];
}

- (void) addIntrinsicChannel:(SIMChannel *)channel withName:(NSString *)name
{
    [intrinsicChannelsDict setObject:channel forKey:name];
}

- (SIMChannel *) intrinsicChannelWithName:(NSString *)name
/*"
    Returns the channel model for key name in the channel model dictionary.
"*/
{
    return [intrinsicChannelsDict objectForKey:name];
}

- (SIMChannel *) intrinsicChannelAtIndex:(int)index
/*"
    Returns the channel model at a particular index in the channel model dictionary.
"*/
{
    return intrinsicChannels[index];
}

- (int) indexOfIntrinsicChannel:(NSString *)type
/*"
    Returns the index of a channel model with key type in the channel model dictionary.
"*/
{
    return [[intrinsicChannelsDict objectForKey:type] assignedIndex];
}

- (void) addInputChannel:(SIMChannel *)channel withName:(NSString *)name
{
    [inputChannelsDict setObject:channel forKey:name];
}

- (SIMInputChannel *) inputChannelWithName:(NSString *)name
/*"
    Returns the channel model for key name in the channel model dictionary.
"*/
{
    return [inputChannelsDict objectForKey:name];
}

- (SIMInputChannel *) inputChannelAtIndex:(int)index
/*"
    Returns the channel model at a particular index in the channel model dictionary.
"*/
{
    return inputChannels[index];
}


- (int) indexOfInputChannel:(NSString *)type
/*"
    Returns the index of a channel model with key type in the channel model dictionary.
"*/
{
    return [[inputChannelsDict objectForKey:type] assignedIndex];
}

- (int) indexOfCellCompartment:(NSString *)type
/*"
    Returns the index of a cell model in the cell model dictionary.
"*/
{
    return [[cellCompartmentsDict objectForKey:type] assignedIndex];
}

- (unsigned) assignedIndex
{
    return _assignedIndex;
}

- (void) setAssignedIndex:(unsigned) index
/*" Don't use this method "*/
{
    _assignedIndex = index;
	[typeDictionary setObject:[NSNumber numberWithUnsignedInt:index] forKey:SIMIndexKey];
}

- (NSArray *)allInputChannelKeys
/*"
    Returns an array containing the key names of all the channel models.
"*/
{
    if(inputChannelsDict)return [inputChannelsDict allKeys];
    else return nil;
}

- (NSArray *)allIntrinsicChannelKeys
/*"
    Returns an array containing the key names of all the channel models.
"*/
{
    if(intrinsicChannelsDict)return [intrinsicChannelsDict allKeys];
    else return nil;
}

- (NSArray *)allCellCompartmentKeys
{
/*"
    Returns an array containing the key names of all the cell models.
"*/
    if(cellCompartmentsDict)return [cellCompartmentsDict allKeys];
    else return nil;
}

- (NSDictionary *)efferentConnectionModels
/*"
    Returns the dictionary of efferent connection models.
"*/
{
    return [typeDictionary objectForKey: SIMEfferentConnectionsKey];
}

- (NSDictionary *)afferentConnectionModels
/*"
    Returns the dictionary of afferent connection models.
"*/
{
    return [typeDictionary objectForKey: SIMAfferentConnectionsKey];
}

- (void) archiveActivityState:(SIMState *)element withCoder:(NSCoder *)coder
{
    int i;
        
    if(numIntrinsicChannels > 0){
        for(i = 0; i < numIntrinsicChannels; i++){
            [(SIMChannel *)intrinsicChannels[i] archiveState:element withCoder:coder];
        }
    }

    if(numInputChannels > 0){
        for(i = 0; i < numInputChannels; i++){
            [(SIMInputChannel *)inputChannels[i] archiveState:element withCoder:coder];
        }
    }

    if(numCellCompartments > 0){
        for(i = 0; i < numCellCompartments; i++){
            [(SIMCell *)cellCompartments[i] archiveState:element withCoder:coder];
        }
    }
}

- (void) unarchiveActivityState:(SIMState *)element withCoder:(NSCoder *)coder
{
    int i;
    
    if(numIntrinsicChannels > 0){
        for(i = 0; i < numIntrinsicChannels; i++){
            [(SIMChannel *)intrinsicChannels[i] unarchiveState:element withCoder:coder];
        }
    }

    if(numInputChannels > 0){
        for(i = 0; i < numInputChannels; i++){
            [(SIMInputChannel *)inputChannels[i] unarchiveState:element withCoder:coder];
        }
    }

    if(numCellCompartments > 0){
        for(i = 0; i < numCellCompartments; i++){
            [(SIMCell *)cellCompartments[i] unarchiveState:element withCoder:coder];
        }
    }
}

- (void) archiveState:(SIMState *)element withCoder:(NSCoder *)coder
{
    if(element->connections)[coder encodeConnections:(NSValueArray *)element->connections];
    else [coder encodeObject:[NSMutableValueArray valueArray: nil count: 0 withObjCType: @encode (SIMConnection)]];
    
    [coder encodeValueOfObjCType:@encode(SIMPosition) at:&element->position];
    
    [self archiveActivityState:element withCoder:coder];
}

- (void) unarchiveState:(SIMState *)element withCoder:(NSCoder *)coder
{
    [self allocState:element];

    element->connections = [[coder decodeConnections] retain];
    [coder decodeValueOfObjCType:@encode(SIMPosition) at:&element->position];

    [self unarchiveActivityState:element withCoder:coder];
}

- (void) archiveRemoteState:(SIMState *)element withCoder:(NSCoder *)coder
/*" This is the lightweight representation of the state, used for transport of the network. Should
be as small as possible.  Only absolutely necessary values should be encoded. "*/
{
    int i;
    
    [coder encodeValueOfObjCType:@encode(SIMPosition) at:&element->position];
    
// Optimize this out....
#if 0
    if(numInputChannels > 0){
        for(i = 0; i < numInputChannels; i++){
            [(SIMChannel *)inputChannels[i] archiveRemoteState:element withCoder:coder];
        }
    }
#endif

    if(numCellCompartments > 0){
        for(i = 0; i < numCellCompartments; i++){
            [(SIMCell *)cellCompartments[i] archiveRemoteState:element withCoder:coder];
        }
    }
}

- (void) unarchiveRemoteState:(SIMState *)element withCoder:(NSCoder *)coder
/*" This is the lightweight representation of the state, used for transport of the network. Should
be as small as possible.  Only absolutely necessary values should be encoded. "*/
{
    int i;
    
    [coder decodeValueOfObjCType:@encode(SIMPosition) at:&element->position];

// Optimized out
#if 0
    if(numInputChannels > 0){
        for(i = 0; i < numInputChannels; i++){
            [(SIMChannel *)inputChannels[i] unarchiveRemoteState:element withCoder:coder];
        }
    }
#endif

    if(numCellCompartments > 0){
        for(i = 0; i < numCellCompartments; i++){
            [(SIMCell *)cellCompartments[i] unarchiveRemoteState:element withCoder:coder];
        }
    }
}

- (void) unarchiveRemoteStateWithCoder:(NSCoder *)coder
/*" This decodes the state directly into the userState instance variable.  The pointer to this state
can be retrieved using the - (SIMState *) userState method. "*/
{
    [self unarchiveRemoteState:userState withCoder:coder];
}

- (id)initWithCoder:(NSCoder *)coder
{
    NSEnumerator *classEnum;
    NSString *className;
    int i;

    typeName = [[coder decodeObject] retain];
    cellCompartmentClasses = [[coder decodeObject] retain];

    classEnum = [cellCompartmentClasses objectEnumerator];
    while(className = [classEnum nextObject]){
        [self classWithName:className ofType:CELL_EXTENSION];
    }
    
    inputChannelClasses = [[coder decodeObject] retain];
    classEnum = [inputChannelClasses objectEnumerator];
    while(className = [classEnum nextObject]){
        [self classWithName:className ofType:CHANNEL_EXTENSION]; // correct this to have unique extension for input channels
    }

    intrinsicChannelClasses = [[coder decodeObject] retain];
    classEnum = [intrinsicChannelClasses objectEnumerator];
    while(className = [classEnum nextObject]){
        [self classWithName:className ofType:CHANNEL_EXTENSION];
    }

    connectionsClasses = [[coder decodeObject] retain];
    classEnum = [connectionsClasses objectEnumerator];
    while(className = [classEnum nextObject]){
        [self classWithName:className ofType:CONNECTIONS_EXTENSION];
    }

    typeDictionary = [[coder decodeObject] retain]; 
    _assignedIndex = [typeDictionary intForKey:SIMIndexKey];

    cellCompartmentsDict = [typeDictionary objectForKey:SIMCellCompartmentsKey];
    numCellCompartments = [cellCompartmentsDict count];

    intrinsicChannelsDict = [typeDictionary objectForKey:SIMIntrinsicChannelsKey];
    numIntrinsicChannels = [intrinsicChannelsDict count];

    inputChannelsDict = [typeDictionary objectForKey:SIMInputChannelsKey];
    numInputChannels = [inputChannelsDict count];

    cellCompartments = (SIMCell **)NSZoneMalloc ([self zone],numCellCompartments*sizeof(SIMCell *));
    if(!cellCompartments)NSLog(@"Out of memory while allocating cell models.");

    intrinsicChannels = (SIMChannel **)NSZoneMalloc ([self zone],numIntrinsicChannels*sizeof(SIMChannel *));
    if(!intrinsicChannels)NSLog(@"Out of memory while allocating intrinsic channel models.");

    inputChannels = (SIMInputChannel **)NSZoneMalloc ([self zone],numInputChannels*sizeof(SIMInputChannel *));
    if(!inputChannels)NSLog(@"Out of memory while allocating input channel models.");

    for(i = 0; i < numCellCompartments; i++){
        SIMCell *cellModel = [[coder decodeObject] retain];
		//[cellModel initializeWithCellType:self];
        cellCompartments[[cellModel assignedIndex]] = cellModel;
    }

    for(i = 0; i < numIntrinsicChannels; i++){
        SIMChannel *chanModel = [[coder decodeObject] retain];
		//[chanModel initializeWithCellType:self];
        intrinsicChannels[[chanModel assignedIndex]] = chanModel;
    }

    for(i = 0; i < numInputChannels; i++){
        SIMInputChannel *chanModel = [[coder decodeObject] retain];
		//[chanModel initializeWithCellType:self];
        inputChannels[[chanModel assignedIndex]] = chanModel;
    }

    percentage = [typeDictionary floatForKey:SIMPercentageKey];

    return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
    int i;
    
    [coder encodeObject:typeName];
    
    [coder encodeObject:cellCompartmentClasses];
    [coder encodeObject:inputChannelClasses];
    [coder encodeObject:intrinsicChannelClasses];
    [coder encodeObject:connectionsClasses];

    [coder encodeObject:typeDictionary];
    
    for(i = 0; i < numCellCompartments; i++){
        [coder encodeObject:cellCompartments[i]];
    }

    for(i = 0; i < numIntrinsicChannels; i++){
        [coder encodeObject:intrinsicChannels[i]];
    }

    for(i = 0; i < numInputChannels; i++){
        [coder encodeObject:inputChannels[i]];
    }
}

- (SIMState *) userState
{
    return userState;
}

- (void) allocState:(SIMState *) element
/*"
        Allocates the memory needed for all channel and cell models.  This calls
        -allocState:element for each model.
"*/
{
    int i;

    element->type = self;

    if(numIntrinsicChannels > 0){
        element->channel = (SIMStateValue **)NSZoneMalloc ([self zone],numIntrinsicChannels * sizeof(SIMStateValue *));
        for(i = 0; i < numIntrinsicChannels; i++){
            [(SIMChannel *)intrinsicChannels[i] allocState:element];
        }
    }

    if(numInputChannels > 0){
        element->inputChannel = (SIMStateValue **)NSZoneMalloc ([self zone],numInputChannels * sizeof(SIMStateValue *));
        for(i = 0; i < numInputChannels; i++){
            [(SIMInputChannel *)inputChannels[i] allocState:element];
        }
    }

    if(numCellCompartments > 0){
        element->cell = (SIMStateValue **)NSZoneMalloc ([self zone],numCellCompartments * sizeof(SIMStateValue *));
        for(i = 0; i < numCellCompartments; i++){
            [(SIMCell *)cellCompartments[i] allocState:element];
        }
    }
}

- (void) reallocState:(SIMState *) element forModel:(SIMModel *)model
/*"
        Allocates the memory needed for all channel and cell models.  This calls
        -allocState:element for each model.
"*/
{
    int i;

    element->type = self;


	if([model isKindOfClass:[SIMChannel class]]){
        element->channel = (SIMStateValue **)NSZoneRealloc ([self zone],element->channel,numIntrinsicChannels * sizeof(SIMStateValue *));
        for(i = 0; i < numIntrinsicChannels; i++){
            if(model == intrinsicChannels[i])[(SIMChannel *)intrinsicChannels[i] allocState:element];
        }
    }

	if([model isKindOfClass:[SIMInputChannel class]]){
        element->inputChannel = (SIMStateValue **)NSZoneRealloc ([self zone],element->inputChannel,numInputChannels * sizeof(SIMStateValue *));
        for(i = 0; i < numInputChannels; i++){
            if(model == inputChannels[i])[(SIMInputChannel *)inputChannels[i] allocState:element];
        }
    }

	if([model isKindOfClass:[SIMCell class]]){
        element->cell = (SIMStateValue **)NSZoneRealloc ([self zone],element->cell,numCellCompartments * sizeof(SIMStateValue *));
        for(i = 0; i < numCellCompartments; i++){
             if(model == cellCompartments[i])[(SIMCell *)cellCompartments[i] allocState:element];
        }
    }
}

- (void) deallocState:(SIMState *) element
/*"
    Deallocates the memory needed for all channel and cell models.  This calls
    -deallocState:element for each model.
"*/
{
    int i;

    for(i = 0; i < numIntrinsicChannels; i++){
        [(SIMChannel *)intrinsicChannels[i] deallocState:element];
    }
    if(numIntrinsicChannels > 0)NSZoneFree([self zone],element->channel);

    for(i = 0; i < numInputChannels; i++){
        [(SIMChannel *)inputChannels[i] deallocState:element];
    }
    if(numInputChannels > 0)NSZoneFree([self zone],element->inputChannel);

    for(i = 0; i < numCellCompartments; i++){
        [(SIMCell *)cellCompartments[i] deallocState:element];
    }
    if(numCellCompartments > 0)NSZoneFree([self zone],element->cell);

}

- (NSString *)inspectorClassName
{
    return @"SIMTypeInspector";
}

- (NSString *)description
{
    NSMutableDictionary *descDict = [NSMutableDictionary dictionary];
    [descDict setObject:[typeDictionary objectForKey:SIMInputChannelsKey] forKey:SIMInputChannelsKey];
    [descDict setObject:[typeDictionary objectForKey:SIMIntrinsicChannelsKey] forKey:SIMIntrinsicChannelsKey];
    [descDict setObject:[typeDictionary objectForKey:SIMAfferentConnectionsKey] forKey:SIMAfferentConnectionsKey];
    [descDict setObject:[typeDictionary objectForKey:SIMEfferentConnectionsKey] forKey:SIMEfferentConnectionsKey];
    [descDict setObject:[typeDictionary objectForKey:SIMPercentageKey] forKey:SIMPercentageKey];
    [descDict setObject:[typeDictionary objectForKey:SIMCellCompartmentsKey] forKey:SIMCellCompartmentsKey];
    [descDict setObject:[typeDictionary objectForKey:SIMClassNameKey] forKey:SIMClassNameKey];
    return [typeDictionary description];
}

- (NSValueArray *)membranePotentialForCellModel:(NSString *)cell usingChannelModel:(NSString *)channel forDuration:(float)ms
                               stimulusDuration:(float)stim magnitude:(float)mag dt:(float)dt
{
    NSMutableValueArray *values = [NSMutableValueArray valueArrayWithObjCType:@encode(double)];
    double t;
    SIMState *localState = (SIMState *)NSZoneMalloc([self zone],sizeof(SIMState));
    unsigned int cellIndex,startCellIndex,endCellIndex;
    unsigned int chanIndex,startChanIndex,endChanIndex;
    SIMConnection c;
    c.dx = 0.0;
    c.dy = 0.0;
    c.dz = 0.0;
    c.latency = 0.0;
    c.channelCount = 1;
    c.channels = NSZoneMalloc ([self zone],c.channelCount*sizeof(short int));

    localState->position.x = 0;
    localState->position.y = 0;
    localState->position.z = 0;

    if(dt == 0 || !numCellCompartments || !numInputChannels) return (NSValueArray *)values;

    [self allocState:localState];
    [self setInitialState:localState];
    for(chanIndex = 0; chanIndex < numInputChannels; chanIndex++){
        c.channels[0] = chanIndex;
        c.strength = 1;
        [self initializeConnection:&c toState:localState];
    }

    if([channel isEqual:@"All"]){startChanIndex = 0;endChanIndex = numInputChannels-1;}
    else {
        startChanIndex = [self indexOfInputChannel:channel];
        endChanIndex = startChanIndex;
    }

    if([cell isEqual:@"All"]){startCellIndex = 0;endCellIndex = numCellCompartments-1;}
    else {
        startCellIndex = [self indexOfCellCompartment:cell];
        endCellIndex = startCellIndex;
    }

    for(t = 0.0;t <= ms;t += dt){
        double val;

        for(chanIndex = startChanIndex; chanIndex <= endChanIndex; chanIndex++){
            if((t <= stim) && (stim > 0)) {
                c.channels[0] = chanIndex;
                c.strength = mag*dt;
                [self updateConnection:&c fromState:localState toState:localState dt:dt time:t];
            }
        }

        cellIndex = startCellIndex;
        chanIndex = startChanIndex;

        [self updateIntrinsicChannelState:localState dt:dt time:t];
        [self updateInputChannelState:localState dt:dt time:t];
        [self updateCellState:localState dt:dt time:t];

        val = [self membranePotential:localState atIndex:cellIndex];
        [values addValue:&val];
    }

    [self deallocState:localState];
    NSZoneFree([self zone],localState);
    NSZoneFree([self zone],c.channels);
    return (NSValueArray *)values;
}

- (void) dealloc
{
    NSLog(@"Deallocating type");

    [modelLibraryDict release];
    [self deallocState:userState];
    NSZoneFree([self zone],userState);
    [super dealloc];
}


@end

@implementation SIMType (SIMTypeDictionaryAccess)

- objectAtPath: (NSString *) path
{  return [typeDictionary objectAtPath:path]; }

- (NSArray *) allKeys
{ return [typeDictionary allKeys]; }

- (NSEnumerator *) keyEnumerator
{
    return [[typeDictionary allKeys] objectEnumerator];
}

- objectForKey: key
{ return [typeDictionary objectForKey:key]; }

- (void)setObject: obj forKey: key
{ [typeDictionary setObject: obj forKey: key]; }

- (NSMutableDictionary *) rootDictionary
{ return typeDictionary; }

@end

@implementation SIMType(SIMTypePrivate)


- (void) _instantiateModelsWithLibrary:(NSDictionary *)modelDict
{
    NSMutableDictionary *affDict, *effDict;
    NSDictionary *modelLibrary = [modelDict copy];

    percentage = [typeDictionary floatForKey:SIMPercentageKey];

    numCellCompartments = 0;
    numIntrinsicChannels = 0;
    numInputChannels = 0;
    
    [self _instantiateCellModelsWithLibrary:[modelLibrary objectForKey:SIMCellCompartmentsKey]];
    [self _instantiateIntrinsicChannelsWithLibrary:[modelLibrary objectForKey:SIMIntrinsicChannelsKey]];
    [self _instantiateInputChannelsWithLibrary:[modelLibrary objectForKey:SIMInputChannelsKey]];
    
    affDict = [self _instantiateConnectionGenerators:[typeDictionary objectForKey: SIMAfferentConnectionsKey] 
        withLibrary:[modelLibrary objectForKey:SIMConnectionsModelKey]];
    [typeDictionary setObject:affDict forKey: SIMAfferentConnectionsKey];

    effDict = [self _instantiateConnectionGenerators:[typeDictionary objectForKey: SIMEfferentConnectionsKey]
            withLibrary:[modelLibrary objectForKey:SIMConnectionsModelKey]];
    [typeDictionary setObject:effDict forKey: SIMEfferentConnectionsKey];
    
    [modelLibrary release];
    
}

- (NSMutableDictionary *)_instantiateConnectionGenerators:(NSDictionary *)dict withLibrary:(NSDictionary *)connectionsLibrary
{
    id theObjectClass, theObject,connectKey;
    NSEnumerator *connectEnumerator;
    NSMutableDictionary *connectionsDictionary,*connectDictionary, *connectModelDict;
    int index = 0;
    
    connectionsDictionary = [[NSMutableDictionary dictionaryWithDictionary:dict] retain];
    
    //TimEdit
    //connectEnumerator = [connectionsDictionary keyEnumerator];
    connectEnumerator = [[connectionsDictionary allKeys] objectEnumerator];
    while (connectKey = [connectEnumerator nextObject]) {
        id connectModel;
        connectDictionary = [connectionsDictionary objectForKey: connectKey];

        // Instantiates the connection model
        connectModel = [connectDictionary objectForKey:SIMConnectionsModelKey];
        
        if([connectModel isKindOfClass:[NSString class]]){
            connectModelDict = [connectionsLibrary objectForKey:connectModel];
            if(!connectModelDict){
                NSLog(@"Couldn't find model named %@ in connections library");
                return nil;
            }
        }
        else connectModelDict = [[connectDictionary objectForKey:SIMConnectionsModelKey] mutableCopy];
                      
        [connectModelDict setObject:[NSNumber numberWithInt:index] forKey:SIMIndexKey];
        theObjectClass = [connectModelDict connectionsClassForKey: SIMClassNameKey];
        if (!theObjectClass)
            NSLog(@"Could not find connection class for key: %@",[connectModelDict objectForKey:SIMClassNameKey]);
        [connectionsClasses addObject:[connectModelDict objectForKey: SIMClassNameKey]];
        
        theObject =
        [(SIMConnections *)[theObjectClass allocWithZone: [self zone]]
            initWithDescription: [connectModelDict copy]];
        if (theObject) {
			[theObject setModelName:connectKey];
			[connectDictionary setObject:theObject forKey: SIMConnectionsModelKey];
		}
        else NSLog(@"Error initializing connections for key: %@",connectKey);

        [connectionsDictionary setObject:connectDictionary forKey:connectKey];

    }
    return [connectionsDictionary autorelease];
}

- (void)_instantiateCellModelsWithLibrary:(NSDictionary *)cellLibrary
{
    id			theObjectClass, theObject,cellKey;
    NSEnumerator	*cellEnumerator;
    NSMutableDictionary	*cellDictionary;
    NSMutableDictionary	*origCellModelsDict;
    int index = 0;
        
    cellCompartmentsDict = [[NSMutableDictionary dictionary] retain];
    origCellModelsDict = [typeDictionary objectForKey:SIMCellCompartmentsKey];
    
    numCellCompartments = [origCellModelsDict count];
    cellCompartments = (SIMCell **)NSZoneMalloc ([self zone],numCellCompartments*sizeof(SIMCell *));
    if(!cellCompartments)NSLog(@"Out of memory while allocating cell models.");

    // Instantiates the cell model
    cellEnumerator = [origCellModelsDict keyEnumerator];
    while((cellKey = [cellEnumerator nextObject])){
        id obj = [origCellModelsDict objectForKey: cellKey];
        
        if([obj isKindOfClass:[NSString class]]){
            id libObject = [cellLibrary objectForKey:obj];
            if(libObject) cellDictionary = [[NSMutableDictionary dictionaryWithDictionary:libObject] retain];
            else {
                NSLog(@"Couldn't find model named %@ in cell library");
                return;
            }
        }
        else cellDictionary = [[NSMutableDictionary dictionaryWithDictionary:obj] retain];
        
        [cellDictionary setObject:[NSNumber numberWithInt:index++] forKey:SIMIndexKey];
        theObjectClass = [cellDictionary cellClassForKey: SIMClassNameKey];
        [cellCompartmentClasses addObject:[cellDictionary objectForKey: SIMClassNameKey]];
        theObject =
        [(SIMCell *)[theObjectClass alloc] initWithDescription: cellDictionary];
        if (theObject){
			[theObject setModelName:cellKey];
            [cellCompartmentsDict setObject:theObject forKey: cellKey];
            cellCompartments[[theObject assignedIndex]] = theObject;
        }
        else raiseInvalidCellModelException();
        
        [cellDictionary release];
    }

    [typeDictionary setObject:cellCompartmentsDict forKey:SIMCellCompartmentsKey];
}

- (void)_instantiateIntrinsicChannelsWithLibrary:(NSDictionary *)channelLibrary
{
    id			theObjectClass, theObject,channelKey;
    NSEnumerator 	*channelEnumerator;
    NSMutableDictionary	*channelDictionary;
    NSMutableDictionary *origChannelModelsDict;
    int index = 0;

    [channelLibrary retain];

    intrinsicChannelsDict = [[NSMutableDictionary dictionary] retain];
    origChannelModelsDict = [typeDictionary objectForKey:SIMIntrinsicChannelsKey];
    
    numIntrinsicChannels = [origChannelModelsDict count];
    intrinsicChannels = (SIMChannel **)NSZoneMalloc ([self zone],numIntrinsicChannels*sizeof(SIMChannel *));
    if(!intrinsicChannels)NSLog(@"Out of memory while allocating channel models.");

    channelEnumerator = [origChannelModelsDict keyEnumerator];
    while((channelKey = [channelEnumerator nextObject])){
        id obj = [origChannelModelsDict objectForKey: channelKey];
        if([obj isKindOfClass:[NSString class]]){
            id libraryEntry = [channelLibrary objectForKey:obj];
            if(libraryEntry) channelDictionary = [NSMutableDictionary dictionaryWithDictionary:libraryEntry];
            else {
                NSLog(@"Couldn't find model named %@ in channel library");
                return;
            }
        }
        else channelDictionary = [NSMutableDictionary dictionaryWithDictionary:obj];

        [channelDictionary setObject:[NSNumber numberWithInt:index++] forKey:SIMIndexKey];

        theObjectClass = [channelDictionary channelClassForKey: SIMClassNameKey];
        if(theObjectClass)[intrinsicChannelClasses addObject:[channelDictionary objectForKey: SIMClassNameKey]];
        else {
            NSLog(@"Couldn't load class: %@",[channelDictionary objectForKey: SIMClassNameKey]);
            return;
        }
        theObject = [(SIMChannel *)[theObjectClass alloc] initWithDescription: channelDictionary];
        if (theObject){
            if([intrinsicChannelsDict objectForKey:channelKey])NSLog(@"Repeated channel %@",channelKey);
			[theObject setModelName:channelKey];
            [intrinsicChannelsDict setObject:theObject forKey: channelKey];
            intrinsicChannels[[theObject assignedIndex]] = theObject;
        }
        else raiseInvalidChannelModelException();
    }
    
    [typeDictionary setObject:intrinsicChannelsDict forKey:SIMIntrinsicChannelsKey];

    [channelLibrary release];
}

- (void)_instantiateInputChannelsWithLibrary:(NSDictionary *)channelLibrary
{
    id			theObjectClass, theObject,channelKey;
    NSEnumerator 	*channelEnumerator;
    NSMutableDictionary	*channelDictionary;
    NSMutableDictionary *origChannelModelsDict;
    int index = 0;

    [channelLibrary retain];

    inputChannelsDict = [[NSMutableDictionary dictionary] retain];
    origChannelModelsDict = [typeDictionary objectForKey:SIMInputChannelsKey];
    
    numInputChannels = [origChannelModelsDict count];
    inputChannels = (SIMInputChannel **)NSZoneMalloc ([self zone],numInputChannels*sizeof(SIMInputChannel *));
    if(!inputChannels)NSLog(@"Out of memory while allocating channel models.");

    channelEnumerator = [origChannelModelsDict keyEnumerator];
    while((channelKey = [channelEnumerator nextObject])){
        id obj = [origChannelModelsDict objectForKey: channelKey];
        if([obj isKindOfClass:[NSString class]]){
            id libraryEntry = [channelLibrary objectForKey:obj];
            if(libraryEntry) channelDictionary = [NSMutableDictionary dictionaryWithDictionary:libraryEntry];
            else {
                NSLog(@"Couldn't find model named %@ in channel library");
                return;
            }
        }
        else channelDictionary = [NSMutableDictionary dictionaryWithDictionary:obj];

        [channelDictionary setObject:[NSNumber numberWithInt:index++] forKey:SIMIndexKey];

        theObjectClass = [channelDictionary channelClassForKey: SIMClassNameKey];
        if(theObjectClass)[inputChannelClasses addObject:[channelDictionary objectForKey: SIMClassNameKey]];
        else {
            NSLog(@"Couldn't load class: %@",[channelDictionary objectForKey: SIMClassNameKey]);
            return;
        }
        theObject = [(SIMInputChannel *)[theObjectClass alloc] initWithDescription: channelDictionary];
        if (theObject){
            if([inputChannelsDict objectForKey:channelKey])NSLog(@"Repeated channel %@",channelKey);
			[theObject setModelName:channelKey];
			[inputChannelsDict setObject:theObject forKey: channelKey];
            inputChannels[[theObject assignedIndex]] = theObject;
        }
        else raiseInvalidChannelModelException();
    }
    
    [typeDictionary setObject:inputChannelsDict forKey:SIMInputChannelsKey];

    [channelLibrary release];
}

@end
