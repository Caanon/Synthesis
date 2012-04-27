/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/SIMModel.h>
#import <SynthesisCore/SIMCategories.h>
#import <Desiderata/NSValueArray.h>

@implementation SIMModel
/*"
	A semi-abstract superclass used to implement a mathematical model
	of the behavior of an element in a network.  This class
	provides methods for automatically loading a template file
	which describes the parameters and state variables used for the model.

	Most of the other methods in this class are defined to 
	be implemented by subclasses such as SIMChannel and SIMCell.
	Another subclass to look at is SIMConnections which implements
	only a subset of these methods as it is not responsible for
	dynamically updating element states.
"*/

- initWithDescription:(NSDictionary *)aDescription
/*"
    The designated initializer for this class.  It first loads the template,
    merges the dictionary containing the description with that from the template.
    This then calls initModelWithNetwork: with an argument of nil, in order to provide
    a default initialization.
"*/
{
    [super initWithDescription:aDescription];
    
    evaluateDerivatives = (void (*)(id, SEL, SIMStateValue *, SIMStateValue *, float, SIMState *))
        [self methodForSelector:@selector(evaluateDerivatives:initialValues:time:context:)];

    userState.channel = (SIMStateValue **)nil;
    userState.cell = (SIMStateValue **)nil;
    userState.connections = nil;
    
    [self _setup];

    return self;
}

- (void)_setup
{
    [self updateParameterValues];
    
    randomSeed = 0;

    [self setRandomNumberSeed:randomSeed];

    _assignedIndex = [mainDictionary intForKey:SIMIndexKey];

    if(_integrationMethod != SIM_NoIntegrationMethod) [self initUserState];

    [self updateVariableIndexes];
}

- (void) initializeWithCellType:(SIMType *)type
/*"
    This method should be invoked by a call to [super initializeWithCellType:] in all
    subclasses.
"*/
{
	cellType = type;
    [self _setup];
}

- (SIMType *)cellType
{
	return cellType;
}

- (int) randomNumberSeed
{
    return randomSeed;
}

- (void) setRandomNumberSeed:(int)uniqueSeed
/*" Resets the state of all random number generators in a model. This must be implemented for all subclasses that use
    random number generators beyond the default stateGenerator.  "*/
{
    randomSeed = uniqueSeed;
    
    if(stateGenerator){
            [stateGenerator release];
            stateGenerator = nil;
    }
    
    stateGenerator = [[self randomStateGenerator] retain];
    
    [stateGenerator setSeed:uniqueSeed];
}

- (PRNGenerator *) randomStateGenerator
/*"
    Returns a new autoreleased instance of a random number generator.
    The default implementation provides an uniform distribution with a
    minimum value of 0.0 and maximum of 1.0. The seed value should be set
    in the setRandomNumberSeed: implementation.
"*/
{
    PRNUniformGenerator *aGenerator;
    aGenerator = [PRNUniformGenerator uniformGenerator];
    [aGenerator setSeed:randomSeed];
    [aGenerator setMinimum: 0.0 maximum: 1.0];
    return aGenerator;
}

- (void) updateVariableIndexes
{
// to be completed by any subclass adding state variables.
}

- (unsigned) assignedIndex
/*"
    Returns the index used to access SIMState data for this model.  Do not use.
"*/
{
    return _assignedIndex;
}

- (void) setAssignedIndex:(unsigned)index
/*"
    Sets the index used to access SIMState data for this model.  Do not use.
"*/
{
    _assignedIndex = index;
    [mainDictionary setObject:[NSNumber numberWithUnsignedInt:index] forKey:SIMIndexKey];
}

- (void) initUserState
/*"
    Cell and Channel subclasses implement this method; it should normally not
    be overridden.  This is called automatically in the event differential equation solving facilities are used.
"*/
{	
}

- (void)evaluateDerivatives:(SIMStateValue *)dy initialValues:(SIMStateValue *)y
    time:(float)t context:(SIMState *)state
/*"
	This method is implemented by the SIMCell and SIMChannel subclasses.
"*/
{	// subclass should complete this
}

- (void) updateState: (SIMState *) element dt: (float) dt  time: (float) t;
/*"
    This method is implemented by the SIMCell and SIMChannel subclasses.
"*/
{
    switch(_integrationMethod){
        case SIM_ForwardEuler:
            [self updateStateUsingForwardEuler:element dt:dt time:t];
            break;
        case SIM_RungeKutta4thOrder:
            [self updateStateUsingRungeKutta4thOrder:element dt:dt time:t];
            break;
        default:
            return;
    }
}

- (void)updateStateUsingForwardEuler:(SIMState *)values dt:(float)dt time:(float)time
/*"
    This method is implemented by the SIMCell and SIMChannel subclasses.
"*/
{
	// Implemented in SIMCell and SIMChannel subclasses
}

- (void)updateStateUsingRungeKutta4thOrder:(SIMState *)element dt:(float)dt time:(float)time;
/*"
    This method is implemented by the SIMCell and SIMChannel subclasses.
"*/
{
	// Implemented in SIMCell and SIMChannel subclasses
}

- (void) setRandomValuesForState: (SIMState *) element
{	// subclass should complete this
}

- (void) setInitialValuesForState: (SIMState *) element
{	// subclass should complete this
}

- (void) setNullValuesForState: (SIMState *) element;
{	// subclass should complete this
}

- (void) updateParameters
/*"
    This method is responsible for extracting parameter values from the description dictionary.
    All subclasses should override this method to extract values for parameters that they may
    have added.  Be sure to call [super updateParameters], because the base SIMModel extracts
    the integration method from its parameter dictionary with this method.
"*/
{
    NSString *intMethod = [self objectForKey:SIMIntegrationMethodKey];

    [super updateParameters];
    
    if([intMethod isEqual:SIMIntegrationMethod_RungeKutta4thOrder])_integrationMethod = SIM_RungeKutta4thOrder;
    else if([intMethod isEqual:SIMIntegrationMethod_ForwardEuler])_integrationMethod = SIM_ForwardEuler;
    else _integrationMethod = SIM_NoIntegrationMethod;
}


- (NSDictionary *)variableDescription:(NSString *)varName
/*"
    Returns the dictionary that describes the state variable varName.
"*/
{
    return [[self variableDictionary] objectForKey:varName];
}

- (NSDictionary *)variableDictionary
/*"
    Returns the dictionary that describes all state variables.
"*/
{
    return [mainDictionary objectForKey:SIMVariablesKey];
}

- (unsigned long) indexOfVariable:(NSString *)var
/*"
    Returns the index of the state variable var.
"*/
{
    NSInteger n;
    if(![self variableDescription:var]) n = NSNotFound;
    else n = [[self variableDescription:var] intForKey:SIMIndexKey];
    return n;
}

- (NSString *)variableAtIndex:(unsigned)index
/*"
    Returns the name of the variable that is stored at index.
"*/
{
    NSEnumerator *varEnum = [[[self allVariables] objectEnumerator] retain];
    NSString *variableName;
    while(variableName = [varEnum nextObject]){
        if([self indexOfVariable:variableName] == index)return variableName;
    }
    [varEnum release];
    return @"NotFound";
}

- (SIMValueType)typeForVariable:(NSString *)varName
/*"
    Returns the SIMValueType of the state variable with a name of varName.
"*/
{
    NSString *type = [[self variableDescription:varName] objectForKey:SIMTypeKey];
    
    if([type isEqual:@"unsigned"])
        return SIMUnsignedType;
    else if([type isEqual:@"BOOL"])
        return SIMBooleanType;
    else if([type isEqual:@"int"])
        return SIMIntegerType;
    else if([type isEqual:@"float"])
        return SIMFloatType;
    else if([type isEqual:@"long"])
        return SIMLongType;
    else if([type isEqual:@"double"])
        return SIMDoubleType;
    else if([type isEqual:@"id"])
        return SIMObjectType;
    else if([type isEqual:@"SIMActivityStateValue"]){
        return SIMActivityType;
    }
    else {
        NSLog(@"ERROR: Invalid type: %@ for variable:%@",type,varName);
        return SIMUnknownType;
    }
}

- (double) doubleValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	return (double)SIM_UndefinedState;
}

- (float) floatValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	return (float)SIM_UndefinedState;
}

- (int) intValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	return (int)SIM_UndefinedState;
}

- (SIMActivityStateValue) activityValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	return SIM_UndefinedState;
}

- (long) longValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	return (long)SIM_UndefinedState;
}

- (BOOL) boolValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	return NO;
}

- (id) objectValueOfVariable:(NSString *)var forState:(SIMState *)state
{
	return nil;
}

- (NSArray *)allVariableKeys 
{
	return [self allVariables];
}

- (NSArray *)allVariables;
/*"
    Returns an array containing the string names of all state variables.
"*/
{
    return [[self variableDictionary] allKeys];
}

- (int) numVariables
/*"
    Returns the count of the entries in the state variable dictionary.
"*/
{
    return [[self variableDictionary] count];
}

- (NSString *)iconName
/*"
    Returns the name of an icon that could be used to represent this class.
"*/
{
    return @"SIMModel";
}

- (void) setModelName:(NSString *)name
{
	[modelName autorelease];
	modelName = [name retain];
}


- (NSString *) modelName
{
	return modelName;
}

- (id)initWithCoder:(NSCoder *)coder
/*"
    Initializes a new instance of this class from coder.
"*/
{
    self = [super initWithCoder:coder];

	modelName = [[coder decodeObject] retain];

    evaluateDerivatives = (void (*)(id, SEL, SIMStateValue *, SIMStateValue *, float, SIMState *))
        [self methodForSelector:@selector(evaluateDerivatives:initialValues:time:context:)];

    //[self updateParameterValues];
    [self _setup];

    userState.channel = (SIMStateValue **)nil;
    userState.cell = (SIMStateValue **)nil;
    userState.connections = nil;

    return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
/*"
    Encodes the current object with coder, see NSCoding.
"*/
{
    [super encodeWithCoder:coder];
	
	[coder encodeObject:modelName];

}

- (void) archiveState:(SIMState *)element withCoder:(NSCoder *)coder
/*"
    Archives the state information in element using coder.  Subclasses typically do not have
    to be concerned with any details of this process.  All state variables are archived/unarchived
    according to the type information in the template.  If additional encoding/decoding needs to happen
    the subclass can override this.  Always be sure to call [super archiveState:withCoder:];
"*/
{
// Implemented by subclasses to allow archiving of system states
}

- (void) unarchiveState:(SIMState *)element withCoder:(NSCoder *)coder
/*"
    Unarchives the state information in element using coder.  Subclasses typically do not have
    to be concerned with any details of this process.  All state variables are archived/unarchived
    according to the type information in the template.  If additional encoding/decoding needs to happen
    the subclass can override this.  Always be sure to call [super archiveState:withCoder:];
"*/
{
// Implemented by subclasses to allow archiving of system states
}

- (void) archiveRemoteState:(SIMState *)element withCoder:(NSCoder *)coder
/*" Used for lightweight network transport of information between nodes "*/
{
// Implemented by subclasses to allow archiving of system states
}

- (void) unarchiveRemoteState:(SIMState *)element withCoder:(NSCoder *)coder
/*" Used for lightweight network transport of information between nodes "*/
{
// Implemented by subclasses to allow archiving of system states
}


- (void) allocState: (SIMState *) element
/*"
    Allocates the memory in element necessary for the state variables of this model.
"*/
{
	// each subclass that stores anything extra inside the state struct
	// must allocate it itself -- see SIMCell and SIMChannel
}

- (void) deallocState: (SIMState *) element
/*"
    Deallocates the memory in element necessary for the state variables of this model.
"*/
{
	// each subclass that stores anything extra inside the state struct
	// must deallocate it itself -- see SIMCell and SIMChannel
}

- (void)dealloc
/*"
    Deallocates the model.
"*/
{
    [super release];
    [self deallocState:&userState];
	[modelName release];
    [super dealloc];
}

@end
