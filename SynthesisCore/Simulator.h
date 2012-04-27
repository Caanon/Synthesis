/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */


#import <Foundation/Foundation.h>

@class NSValueArray, NSMutableValueArray, SIMNetwork;

#define SGN(x) (x == 0 ? 0 : (x > 0 ? 1 : -1)) 
#define H(x) ((x) <= 0.0 ? 0.0 : 1.0)

extern const char *SIMVersionString();
extern double expx(double y); // accelerated exp() function


#define ALLOW_LOCAL_CONNECTIONS_ONLY 0

#ifndef M_PI
    #define M_PI	3.14159265358979323846
#endif
#ifndef M_LN2
    #define M_LN2 	0.69314718055994530941723212145818
#endif

#define SIM_MAX_PATH_LENGTH		1024
#define SIM_MAX_COMMAND_LENGTH		4096
#define SIM_MAX_COMMAND_LINE_ARGS	1024

#define SERVER_DAEMON 				@"SimulatorDaemon"
#define DEFAULT_SERVERNAME			@"SynthesisServer"
#define SERVER_NAME_KEY 			@"ServerName"
#define EXPERIMENT_NAME_KEY 			@"Experiment"

#define CONTROLLER_EXTENSION			@"bundle"
#define CELL_EXTENSION				@"cell"
#define CHANNEL_EXTENSION			@"channel"
#define CONNECTIONS_EXTENSION			@"connections"
#define TYPE_EXTENSION				@"type"
#define NETWORK_EXTENSION			@"network"
#define INSPECTOR_EXTENSION			@"bundle"
#define TEMPLATE_EXTENSION			@"template"
#define PATGEN_EXTENSION			@"patgen"
#define AGENT_EXTENSION				@"agent"

#define CONNECTION_LATENCIES	// undef to save space in connection struct

@class SIMType;


typedef struct {
		short int	x;
		short int	y;
		short int	z;
} SIMPosition;

#define SIM_DEFINE_UPDATE_STATE_FUNCTION(func) void(*func)(id, SEL,void *,float,float)
#define SIM_DEFINE_UPDATE_CONNECTION_FUNCTION(func) void(*func)(id,SEL,void *,void *,SIMConnection *,float,float)
#define SIMUpdateStateFunction void (*)(id, SEL,void *,float,float)
#define SIMUpdateConnectionFunction void (*)(id,SEL,void *,void *,SIMConnection *,float,float)


typedef enum {
		SIM_UndefinedState = 0x0000,	// (0000 0000 0000 0000)
        SIM_RefractoryState = 0x0400,	// (0000 0100 0000 0000)
        SIM_RestingState = 0x0800,		// (0000 1000 0000 0000)
        SIM_FiringState = 0x1000,		// (0001 0000 0000 0000)
        SIM_MiniSpikeState = 0x2000,	// (0010 0000 0000 0000)
		SIM_PlasticState = 0x4000,		// (0100 0000 0000 0000)
        SIM_SpikingState = 0x8000		// (1000 0000 0000 0000)
} SIMActivityStateValue;

typedef struct {
		unsigned int cellState:4;		// resting, firing, mini, spike
		unsigned int plasticState:4;	// plastic
		unsigned int modulatorState:4;	// modulator
        unsigned int reserved:20;  
		unsigned int userActivity:32; // should develop a means to reserve a bit flag in a model class
} SIMActivityValue;

/*

#define CHARSIZE sizeof(char)
#define MASK(y) ( 1 << y % CHARSIZE )
#define BITSLOT(y) ( y / CHARSIZE )
#define SET( x, y) ( x[BITSLOT(y)] |= MASK(y) )
#define CLEAR(x, y) ( x[BITSLOT(y)] &= ~MASK(y) )
#define TEST(x, y) ( x[BITSLOT(y)] & MASK(y) )
#define NUMSLOTS(n) ((n + CHARSIZE - 1) / CHARSIZE)

*/

/*" Enumerate the various integration methods available in SIMModel and its subclasses "*/
typedef enum {
    SIM_NoIntegrationMethod = 0,
    SIM_ForwardEuler,
    SIM_RungeKutta4thOrder
} SIMIntegrationMethods;

#define	SIMIntegrationMethodKey			@"INTEGRATION_METHOD"
#define SIMIntegrationMethod_None		@"None"
#define SIMIntegrationMethod_ForwardEuler 	@"ForwardEuler"
#define SIMIntegrationMethod_RungeKutta4thOrder @"RungeKutta4thOrder"

#define SIMNumberOfProcessorsKey		@"NUMBER_OF_PROCESSORS"

typedef enum {
    SIMUnknownType = 0,
    SIMActivityType,
    SIMDoubleType,
    SIMFloatType,
    SIMUnsignedType,
    SIMIntegerType,
    SIMLongType,
    SIMBooleanType,
    SIMObjectType
} SIMValueType;

typedef struct {
    SIMValueType type;
    union values {
        unsigned	unsignedValue;
        BOOL		booleanValue;
        int			intValue;
        float		floatValue;
        long		longValue;
        double		doubleValue;
        id 		objectValue;
        SIMActivityStateValue activityValue;
    } state;
} SIMStateValue;

// currently unused...
typedef struct {
                short int 	index;
                short int	stateCount;
                SIMStateValue	*state;
} SIMConnectionState;

typedef struct {
		short int		dx;
		short int		dy;
		short int		dz;
		float			strength;
#ifdef CONNECTION_LATENCIES
		float			latency;
#endif
		short int	channelCount;
		short int	*channels;
//                SIMConnectionState	*channels;  // states for the channels to use
} SIMConnection;

void SIMCopyConnection(SIMConnection *from, SIMConnection *to);

typedef struct {
	SIMStateValue compartment;
	SIMStateValue *channels;
	SIMStateValue *inputChannels;
	NSMutableValueArray *connections;
	SIMPosition position;
} SIMCompartmentState;

typedef struct {
    SIMType		*type;		// Type object
    SIMStateValue 	**cell;		// Multiple cell compartments
    SIMStateValue	**channel;	// Multiple intrinsic channel states
    SIMStateValue	**inputChannel;	// Multiple input channel states
    NSMutableValueArray *connections;	// Object containing connections
    SIMPosition		position;
/*"
    Note: cell[n][CELL_STATE_INDEX = 0] reserved for state (SIMActivityStateValue) value.
    cell[n][CELL_POTENTIAL_INDEX = 1] reserved for membrane potential value;
    channel[n][INPUT_INDEX = 0] reserved for channel input;
    channel[n][OUTPUT_INDEX = 1] reserved for channel output.
    Subclasses of SIMModel append their own variables/ids.
"*/
} SIMState;

/*"
The following macros all take a pointer to a SIMState as an argument.  They then return the appropriate
value from the SIMState structure.  These are neither complete, tested nor ready for public consumption.
"*/

#define CHANNEL_SET_VALUE(element,index,valuePtr) \
    switch(&element->channel[_assignedIndex][index].type) {				       \
        case SIMUnsignedType: &element->channel[_assignedIndex][index].state.unsignedValue = *(unsigned *)valuePtr; break; \
        case SIMBooleanType: &element->channel[_assignedIndex][index].state.booleanValue = *(BOOL *)valuePtr; break;	\
        case SIMIntegerType: &element->channel[_assignedIndex][index].state.intValue = *(int *)valuePtr; break;	\
        case SIMFloatType: &element->channel[_assignedIndex][index].state.floatValue = *(float *)valuePtr; break;		\
        case SIMLongType: &element->channel[_assignedIndex][index].state.longValue = *(long *)valuePtr; break;		\
        case SIMDoubleType: &element->channel[_assignedIndex][index].state.doubleValue = *(double *)valuePtr; break;	\
        case SIMObjectType: &element->channel[_assignedIndex][index].state.objectValue = *(id)valuePtr; break;		\
        case SIMActivityType: &element->channel[_assignedIndex][index].state.activityValue = *(SIMActivityStateValue *)valuePtr; break; \
        default: break;	\
    }

#define CHANNEL_GET_VALUE(element,index,resultPtr) \
    switch(&element->channel[_assignedIndex][index].type) {				       \
        case SIMUnsignedType: *(unsigned *)resultPtr = &element->channel[_assignedIndex][index].state.unsignedValue; break; \
        case SIMBooleanType: *(BOOL *)resultPtr = &element->channel[_assignedIndex][index].state.booleanValue; break;	\
        case SIMIntegerType: *(int *)resultPtr = &element->channel[_assignedIndex][index].state.intValue; break;	\
        case SIMFloatType: *(float *)resultPtr = &element->channel[_assignedIndex][index].state.floatValue; break;		\
        case SIMLongType: *(long *)resultPtr = &element->channel[_assignedIndex][index].state.longValue; break;		\
        case SIMDoubleType: *(double *)resultPtr = &element->channel[_assignedIndex][index].state.doubleValue; break;	\
        case SIMObjectType: *(id)resultPtr = &element->channel[_assignedIndex][index].state.objectValue; break;		\
        case SIMActivityType: *(SIMActivityStateValue *)resultPtr = &element->channel[_assignedIndex][index].state.activityValue; break; \
        default: break;	\
    }

#define CELL_SET_VALUE(_element,index,valuePtr) \
    switch(_element->cell[_assignedIndex][index].type) {				       \
        case SIMUnsignedType: _element->cell[_assignedIndex][index].state.unsignedValue = *(unsigned *)valuePtr; break; \
        case SIMBooleanType: _element->cell[_assignedIndex][index].state.booleanValue = *(BOOL *)valuePtr; break;	\
        case SIMIntegerType: _element->cell[_assignedIndex][index].state.intValue = *(int *)valuePtr; break;	\
        case SIMFloatType: _element->cell[_assignedIndex][index].state.floatValue = *(float *)valuePtr; break;		\
        case SIMLongType: _element->cell[_assignedIndex][index].state.longValue = *(long *)valuePtr; break;		\
        case SIMDoubleType: _element->cell[_assignedIndex][index].state.doubleValue = *(double *)valuePtr; break;	\
        case SIMObjectType: _element->cell[_assignedIndex][index].state.objectValue = *(id)valuePtr; break;		\
        case SIMActivityType: _element->cell[_assignedIndex][index].state.activityValue = *(SIMActivityStateValue *)valuePtr; break; \
        default: break;	\
    }

#define CELL_GET_VALUE(_element,index,resultPtr) \
    switch(_element->cell[_assignedIndex][index].type) {				       \
        case SIMUnsignedType: *(unsigned *)resultPtr = &_element->cell[_assignedIndex][index].state.unsignedValue; break; \
        case SIMBooleanType: *(BOOL *)resultPtr = &_element->cell[_assignedIndex][index].state.booleanValue; break;	\
        case SIMIntegerType: *(int *)resultPtr = &_element->cell[_assignedIndex][index].state.intValue; break;	\
        case SIMFloatType: *(float *)resultPtr = &_element->cell[_assignedIndex][index].state.floatValue; break;		\
        case SIMLongType: *(long *)resultPtr = &_element->cell[_assignedIndex][index].state.longValue; break;		\
        case SIMDoubleType: *(double *)resultPtr = &_element->cell[_assignedIndex][index].state.doubleValue; break;	\
        case SIMObjectType: *(id)resultPtr = &_element->cell[_assignedIndex][index].state.objectValue; break;		\
        case SIMActivityType: *(SIMActivityStateValue *)resultPtr = &_element->cell[_assignedIndex][index].state.activityValue; break; \
        default: break;	\
    }

#define CELL_VALUE(_element,index) \
        (_element->cell[_assignedIndex][index].type==SIMDoubleType)?(double)_element->cell[_assignedIndex][index].state.doubleValue: \
        (_element->cell[_assignedIndex][index].type==SIMActivityType)?(SIMActivityStateValue)_element->cell[_assignedIndex][index].state.activityValue: \
        (_element->cell[_assignedIndex][index].type==SIMFloatType)?(float)_element->cell[_assignedIndex][index].state.floatValue: \
        (_element->cell[_assignedIndex][index].type==SIMObjectType)?(id)_element->cell[_assignedIndex][index].state.objectValue: \
        (_element->cell[_assignedIndex][index].type==SIMLongType)?(long)_element->cell[_assignedIndex][index].state.longValue: \
        (_element->cell[_assignedIndex][index].type==SIMUnsignedType)?(unsigned)_element->cell[_assignedIndex][index].state.unsignedValue: \
        (_element->cell[_assignedIndex][index].type==SIMBooleanType)?(BOOL)_element->cell[_assignedIndex][index].state.booleanValue: \
        (_element->cell[_assignedIndex][index].type==SIMIntegerType)?(int)_element->cell[_assignedIndex][index].state.intValue

#define CHANNEL_VALUE(_element,index) \
        (_element->channel[_assignedIndex][index].type==SIMDoubleType)?(double)_element->channel[_assignedIndex][index].state.doubleValue: \
        (_element->channel[_assignedIndex][index].type==SIMActivityType)?(SIMActivityStateValue)_element->channel[_assignedIndex][index].state.activityValue: \
        (_element->channel[_assignedIndex][index].type==SIMFloatType)?(float)_element->channel[_assignedIndex][index].state.floatValue: \
        (_element->channel[_assignedIndex][index].type==SIMObjectType)?(id)_element->channel[_assignedIndex][index].state.objectValue: \
        (_element->channel[_assignedIndex][index].type==SIMLongType)?(long)_element->channel[_assignedIndex][index].state.longValue: \
        (_element->channel[_assignedIndex][index].type==SIMUnsignedType)?(unsigned)_element->channel[_assignedIndex][index].state.unsignedValue: \
        (_element->channel[_assignedIndex][index].type==SIMBooleanType)?(BOOL)_element->channel[_assignedIndex][index].state.booleanValue: \
        (_element->channel[_assignedIndex][index].type==SIMIntegerType)?(int)_element->channel[_assignedIndex][index].state.intValue

#define CHANNEL_UNSIGNED_VALUE(_element,index) ((unsigned)_element->channel[_assignedIndex][index].state.unsignedValue)
#define CHANNEL_BOOLEAN_VALUE(_element,index) ((BOOL)_element->channel[_assignedIndex][index].state.booleanValue)
#define CHANNEL_INTEGER_VALUE(_element,index) ((int)_element->channel[_assignedIndex][index].state.intValue)
#define CHANNEL_FLOAT_VALUE(_element,index) ((float)_element->channel[_assignedIndex][index].state.floatValue)
#define CHANNEL_LONG_VALUE(_element,index) ((long)_element->channel[_assignedIndex][index].state.longValue)
#define CHANNEL_DOUBLE_VALUE(_element,index) ((double)_element->channel[_assignedIndex][index].state.doubleValue)
#define CHANNEL_OBJECT_VALUE(_element,index) ((id)_element->channel[_assignedIndex][index].state.objectValue)
#define CHANNEL_ACTIVITY_VALUE(_element,index) ((SIMActivityStateValue)_element->channel[_assignedIndex][index].state.activityValue)
#define INPUT_VALUE(_element) ((double)_element->channel[_assignedIndex][INPUT_INDEX].state.doubleValue)
#define OUTPUT_VALUE(_element) ((double)_element->channel[_assignedIndex][OUTPUT_INDEX].state.doubleValue)

#define CELL_UNSIGNED_VALUE(_element,index) ((unsigned)_element->cell[_assignedIndex][index].state.unsignedValue)
#define CELL_BOOLEAN_VALUE(_element,index) ((BOOL)_element->cell[_assignedIndex][index].state.booleanValue)
#define CELL_INTEGER_VALUE(_element,index) ((int)_element->cell[_assignedIndex][index].state.intValue)
#define CELL_FLOAT_VALUE(_element,index) ((float)_element->cell[_assignedIndex][index].state.floatValue)
#define CELL_LONG_VALUE(_element,index) ((long)_element->cell[_assignedIndex][index].state.longValue)
#define CELL_DOUBLE_VALUE(_element,index) ((double)_element->cell[_assignedIndex][index].state.doubleValue)
#define CELL_OBJECT_VALUE(_element,index) ((id)_element->cell[_assignedIndex][index].state.objectValue)
#define CELL_ACTIVITY_VALUE(_element,index) ((SIMActivityStateValue)_element->cell[_assignedIndex][index].state.activityValue)
#define CELL_POTENTIAL(_element) ((double)_element->cell[_assignedIndex][CELL_POTENTIAL_INDEX].state.doubleValue)
#define CELL_ACTIVITY_STATE(_element) ((SIMActivityStateValue)_element->cell[_assignedIndex][CELL_STATE_INDEX].state.activityValue)

#define SIM_UNSIGNED_VALUE(_element,index) ((unsigned)_element[index].state.unsignedValue)
#define SIM_BOOLEAN_VALUE(_element,index) ((BOOL)_element[index].state.booleanValue)
#define SIM_INTEGER_VALUE(_element,index) ((int)_element[index].state.intValue)
#define SIM_FLOAT_VALUE(_element,index) ((float)_element[index].state.floatValue)
#define SIM_LONG_VALUE(_element,index) ((long)_element[index].state.longValue)
#define SIM_DOUBLE_VALUE(_element,index) ((double)_element[index].state.doubleValue)
#define SIM_OBJECT_VALUE(_element,index) ((id)_element[index].state.objectValue)
#define SIM_ACTIVITY_VALUE(_element,index) ((SIMActivityStateValue)_element[index].state.activityValue)
#define SIM_POTENTIAL(_element) ((double)_element[CELL_POTENTIAL_INDEX].state.doubleValue)
#define SIM_ACTIVITY_STATE(_element) ((SIMActivityStateValue)_element[CELL_STATE_INDEX].state.activityValue)

#define TYPE(state) ((SIMType *)state->type)
#define CONNECTIONS(state) ((NSArray *)state->connections)
#define POSITION(state) ((SIMPosition)state->position)

/*************************************/

#define SIM_DEFINE_DERIVATIVE_FUNCTION(func) void(*func)(id, SEL, SIMStateValue *, SIMStateValue *, float, SIMState *)
#define SIMDerivativeFunction void (*)(id, SEL, SIMStateValue *, SIMStateValue *, float, SIMState *)

/* Definition of Keys:
 * Key values should be CAPITALIZED
 * Their #defines should end with "Key".
 * #defines which indicate a value such as 
 * SIM_RandomTopology	@"Random"
 * should use an underscore after the SIM prefix and 
 * the values themselves should not
 * be fully capitalized.  Hopefully this can help 
 * the readability of network files and the source code.
*/

#define	SIMStatusDictionaryKey		@"STATUS"
#define	SIMStatusDescriptionKey		@"DESCRIPTION"
#define	SIMStatusDateKey		@"DATE"
#define	SIMStatusProgressKey		@"PROGRESS"  // ranges between 0 and 1;
#define	SIMStatusTimeKey		@"TIME"

#define	SIMNetworkKey			@"NETWORK"
#define	SIMExperimentKey		@"EXPERIMENT"
#define	SIMStatisticsKey		@"STATISTICS"

#define	SIMCommentsKey			@"COMMENTS"
#define	SIMCreationDateKey		@"CREATION_DATE"
#define	SIMLastModifiedDateKey		@"LAST_MODIFIED"
#define	SIMTimeScaleKey			@"TIME_SCALE"
#define	SIMDateAndTimeFormatKey		@"%Y-%m-%d %H:%M:%S %z"

#define SIMAgentsKey			@"AGENTS"
#define SIMNodesKey			@"NODES"
#define SIMNodeKey			@"NODE"
#define SIMServerNameKey		@"SERVERNAME"
#define SIMHostNameKey			@"HOSTNAME"
#define SIMIPAddressKey			@"IP_ADDRESS"
#define	SIMLayersKey			@"LAYERS"
#define	SIMTypesKey			@"TYPES"

#define SIMTypeKey			@"TYPE"

#define	SIM_UndefinedChannel		((short int)-1)
#define	SIM_UndefinedType		((SIMType *)0)
#define	SIM_UndefinedTypeObject		@""
#define SIM_PathSeparator		@"/"
#define	SIM_TypeSeparator		@"."
#define	SIM_All				@"All"

#define	SIMNumRowsKey				@"NUMROWS"
#define	SIMNumColumnsKey			@"NUMCOLUMNS"
#define	SIMPercentageKey			@"PERCENTAGE"
#define SIMIndexKey				@"INDEX"

#define	SIMModelLibraryKey				@"MODEL_LIBRARY"
#define	SIMChannelModelKey				@"CHANNEL_MODEL"
#define	SIMIntrinsicChannelsKey				@"INTRINSIC_CHANNELS"
#define	SIMInputChannelsKey				@"INPUT_CHANNELS"
#define	SIMCellCompartmentsKey 				@"CELL_COMPARTMENTS"
#define	SIMConnectionsModelKey 				@"CONNECTIONS_MODEL"

#define SIMAllowSelfConnectionsFlag			@"ALLOW_SELF_CONNECTIONS"
#define	SIMUniqueConnectionsFlag			@"UNIQUE_CONNECTIONS_FLAG"
#define	SIMPrintTypeHistogramsFlag			@"PRINT_TYPE_HISTOGRAMS_FLAG"
#define	SIMPrintConnectionHistogramsFlag		@"PRINT_CONNECTIONS_HISTOGRAMS_FLAG"
#define	SIMPrintCellConnectionHistogramsFlag 		@"PRINT_CELL_CONNECTION_HISTOGRAMS_FLAG"
#define	SIMPrintConnectionsFlag				@"PRINT_CONNECTIONS_FLAG"
#define	SIMEfferentConnectionsKey			@"EFFERENT_CONNECTIONS"
#define	SIMAfferentConnectionsKey			@"AFFERENT_CONNECTIONS"

#define SIMInitConnectionsFlag			@"INIT_CONNECTIONS_FLAG"

#define SIMMasterRandomSeedKey			@"MASTER_RANDOM_SEED"
//#define SIMStateGeneratorSeedKey		@"STATE_GENERATOR_SEED"

#define	SIMVariablesKey				@"VARIABLES"
#define	SIMParametersKey			@"PARAMETERS"
#define	SIMClassNameKey				@"CLASS_NAME"

#define	SIMTopologyTypeKey			@"TYPE_DISTRIBUTION"
#define	SIM_RandomTopology			@"Random"
#define	SIM_SobolTopology			@"Sobol"
#define	SIM_RegularTopology			@"Regular"  //Currently unimplemented

// Now located within Connection dictionary
#define	SIMHomogeneousKey			@"HOMOGENEOUS"

#define	SIMProjectionBoundaryConditionsKey	@"BOUNDARY_CONDITIONS"
#define	SIMProjectionBoundaryInfoKey		@"BOUNDARY_INFO" // currently only used for SIM_TiledBoundary condition 
#define SIM_CustomBoundary				@"Custom"
#define	SIM_PeriodicBoundary			@"Periodic"
#define	SIM_NullFluxBoundary			@"NullFlux"
#define	SIM_ClippedBoundary				@"Clipped"
#define	SIM_TiledBoundary				@"Tiled"
// The following entries describe which layers to tile with the SIM_TiledBoundary condition
#define SIM_TiledUpperEdgeKey			@"UPPER_EDGE"
#define SIM_TiledLowerEdgeKey			@"LOWER_EDGE"
#define SIM_TiledRightEdgeKey			@"RIGHT_EDGE"
#define SIM_TiledLeftEdgeKey			@"LEFT_EDGE"

// Keys for an inspector interface for modifying parameters
#define	SIMParameterRangesKey		@"PARAMETER_RANGES"
#define	SIMParameterInspectorKey	@"INSPECTOR"
#define	SIMParameterSelectorKey		@"SELECTOR"
#define	SIMParameterRangeKey		@"RANGE"
#define	SIMParameterFormatKey		@"FORMAT"


// SIMNotifications
#define	SIMStatusUpdateNotification			@"StatusUpdate"
#define	SIMErrorUpdateNotification			@"ErrorUpdate"
#define	SIMNetworkIsAvailableNotification		@"NetworkIsAvailable"
#define	SIMNetworkNotAvailableNotification		@"NetworkNotAvailable"
#define	SIMNetworkDidStartNotification			@"NetworkDidStart"
#define	SIMNodeDidUpdateNotification			@"NodeDidUpdate"
#define	SIMNetworkDidUpdateNotification			@"NetworkDidUpdate"
#define	SIMNetworkDidStopNotification			@"NetworkDidStop"
#define	SIMNetworkDictionaryChangedNotification		@"NetworkDictionaryChanged"
#define SIMParameterDidChangeNotification		@"ParameterDidChange"
#define	SIMNetworkUpdateIntervalNotification		@"NetworkUpdateInterval"

// Used for building the network.  SIMConnection should contain a dictionary
// using these keys in its parameter dictionary with a parameter name of
// SIMProjectionInfoKey.  See SIMConnection.template
#define	SIMProjectionInfoKey		@"PROJECTION_INFO"
#define	SIMProjectionTypesKey		@"TYPES"
#define	SIMProjectionXScaleKey		@"XSCALE"
#define	SIMProjectionYScaleKey		@"YSCALE"
#define	SIMProjectionXOffsetKey		@"XOFFSET"
#define	SIMProjectionYOffsetKey		@"YOFFSET"

#define INSPECTOR_CLASS_KEY	@"INSPECTOR_CLASS"
#define INSPECTOR_FRAME_KEY	@"FRAME"
#define INSPECTORS_KEY		@"INSPECTORS"



@protocol SIMRemoteNetwork

- (oneway void)update:(in int)n;
- (oneway void)update;
- (float)dt;
- (float)time;
- (oneway void)setTime: (in float) aTime;

- (bycopy NSData *) typeDataForLayer:(in int)layerIndex;
- (bycopy NSData *) valuesForCellCompartment:(in int)cell atIndex:(in int)variable withType:(bycopy NSString *)type forLayer:(in int)layer;
- (bycopy NSData *) swappedValuesForCellCompartment:(in int)modelIndex atIndex:(in int)CELL_STATE_INDEX withType:(bycopy NSString *)type forLayer:(in int)layerIndex;

- (bycopy NSData *) valuesForIntrinsicChannel:(in int)channel atIndex:(in int)variable withType:(bycopy NSString *)type forLayer:(in int)layer;
- (bycopy NSData *) swappedValuesForIntrinsicChannel:(in int)channel atIndex:(in int)variable withType:(bycopy NSString *)type forLayer:(in int)layer;

- (bycopy NSData *) valuesForInputChannel:(in int)channel atIndex:(in int)variable withType:(bycopy NSString *)type forLayer:(in int)layer;
- (bycopy NSData *) swappedValuesForInputChannel:(in int)channel atIndex:(in int)variable withType:(bycopy NSString *)type forLayer:(in int)layer;

- (double) membranePotentialForCell:(in SIMPosition *)pos;
- (bycopy NSData *)membranePotentialForCells:(bycopy NSArray *)positions;

- (double) summedIntrinsicChannelCurrentsForCell:(in SIMPosition *)pos;
- (bycopy NSData *) summedIntrinsicChannelCurrentsForLayer:(in int)layer;
- (bycopy NSData *) swappedSummedIntrinsicChannelCurrentsForLayer:(in int)layer;

- (double) summedInputChannelCurrentsForCell:(in SIMPosition *)pos;
- (bycopy NSData *) summedInputChannelCurrentsForLayer:(in int)layer;
- (bycopy NSData *) swappedSummedInputChannelCurrentsForLayer:(in int)layer;

- (bycopy NSData *)summedStateVariablesForModelOfType:(in int)modelType matchingPattern:(bycopy NSString *)patternString;

@end


@protocol SIMDictionaryAccess

- (oneway void) setObject:(in id)obj forKey: (in NSString *)key;
- (id)objectAtPath: (in NSString *) path;
- (NSArray *)allKeys;
- (NSEnumerator *) keyEnumerator;
- (id)objectForKey: (in NSString *)key;

@end

@protocol SIMNetworkInfo
- (NSArray *)typesForLayerWithKey:(NSString *)key;
- (NSArray *)layerKeys;

@end

@protocol SIMInspectable <SIMDictionaryAccess>
- (NSDictionary *)parameterRanges;
- (void)updateParameterValues;
- (void)updateParameters;
- (void)setParameterDictionary:(NSDictionary *)aDictionary;
- (NSString *)inspectorClassName;
- (NSString *)iconName;
@end

@protocol SIMTypeInspection
- (NSValueArray *)membranePotentialForCellModel:(NSString *)cell usingChannelModel:(NSString *)channel forDuration:(float)ms stimulus:(float)stim dt:(float)dt;
@end

@protocol SIMRemoteStatistics
- initFromNetwork:(id)aNetwork;
- (oneway void)emptyBuffer;
- (void)gatherData;
@end

@protocol SIMConnections
- (NSValueArray *)connections;
- (NSValueArray *)connectionsTemplate;
- (NSValueArray *)connectionsForPosition:(SIMPosition *)pos;
@end

@protocol SIMServer
- (void) addClient:aClient forNotificationName:(NSString *)name selector:(SEL)aSelector object:anObject;
- (void) removeClient:aClient forNotificationName:(NSString *)name object:anObject;
- (void) removeClient:aClient;
- (void) removeAllClients;
- (void) initialize;
- (void) loadNetworkWithDescription:(NSDictionary *)dict;
- (void) run;
- (void) stop;
- (BOOL) isRunning;
- (int) clientCountForServer:(NSString *)server;
- (void) terminate;
- (unsigned) hostByteOrder;
@end

@protocol SIMDaemon
- (id <SIMServer>) serverWithRegisteredName:(NSString *)name;
@end


@protocol SIMNetworkControl
- (void) initConnections;

- (void) setStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType toValue:(float)val;
- (void) modifyStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType byValue:(float)delta;
- (void) scaleStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType byValue:(float)scale;

- (void) setStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes toValue:(float)val;
- (void) modifyStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes byValue:(float)delta;
- (void) scaleStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes byValue:(float)scale;
@end

@protocol SIMNetworkSimulation
- (oneway void)update:(in int)n;
- (oneway void)update;
- (float)dt;
- (float)time;
- (oneway void)setTime: (in float) aTime;
@end

@class SIMCell;

@protocol SIMNetworkEditing
- (void)addLayerWithName:(NSString *)name;
- (void)addTypeWithName:(NSString *)name layer:(NSString *)layer;
- (void)addCellCompartment:(SIMCell *)cell withName:(NSString *)name type:(NSString *)type layer:(NSString *)layer;
- (void)addEfferentConnectionsWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer;
- (void)addAfferentConnectionsWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer;

- (void)removeLayerWithName:(NSString *)name;
- (void)removeTypeWithName:(NSString *)name layer:(NSString *)layer;
- (void)removeCellCompartmentWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer ;
- (void)removeEfferentConnectionsWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer;
- (void)removeAfferentConnectionsWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer;
@end
