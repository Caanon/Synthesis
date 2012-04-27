/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <Foundation/Foundation.h>
#import <Desiderata/NSValueArray.h>
#import <PseudoRandomNum/PRNGenerator.h>
#import <SynthesisCore/SIMType.h>
#import <SynthesisCore/SIMCell.h>
#import <SynthesisCore/SIMChannel.h>
#import <SynthesisCore/SIMCategories.h>
#import <SynthesisCore/Simulator.h>
#import <pthread.h>

@class SIMModel;
@class NSCountedSet, NSValueArray;

typedef enum {
    SIM_NODE_DEAD = -1,
    SIM_NODE_WAITING,
    SIM_NODE_WORKING,
    SIM_NODE_DONE
} SIMNodeStatus;

typedef struct {
    unsigned short int fromLayer;
    unsigned short int fromType;
    float dt;
    float time;
} SIMRemoteUpdate;

typedef struct {
    int count;
    NSMutableData *data;
    NSArchiver *archiver;
} SIMUpdateQueue;

typedef struct {
    NSString *hostName;
    NSString *serverName;
    SIMNodeStatus status;
    BOOL dataProcessed;
    id server;
    id node;
} SIMNode;

typedef enum {
    SIM_THREAD_IDLE,
    SIM_THREAD_LAUNCHING,
    SIM_THREAD_UPDATE_INTRINSIC_CHANNELS,
    SIM_THREAD_UPDATE_INPUT_CHANNELS,
    SIM_THREAD_UPDATE_CELLS,
    SIM_THREAD_TERMINATING,
    
} SIMThreadState;

typedef struct {
    NSString *name;
    unsigned short int	node;
    unsigned short int	numRows;
    unsigned short int	numColumns;
    unsigned short int	numTypes;
    unsigned short int  numConnections;
    SIMType **types;
} SIMLayer;


@interface SIMNetwork:NSObject <SIMDictionaryAccess,SIMRemoteNetwork>
{
	SIMState		      	***layers;
	SIMLayer	    		*layerInfo;
	SIMNode					*nodeInfo;
	unsigned int			localNode,numLayers,numProcessors,numNodes;
	float					time,dt;
	NSMutableSet			*agentClasses;
	NSMutableDictionary 	*agentDictionary,*nodeDictionary,*layerDictionary;
	NSMutableDictionary		*descriptionDictionary,*logDictionary,*statusDict;
	NSNotification			*networkUpdateNotification;
	SIMUpdateQueue 			***queue;
	NSConditionLock 		*CLock;
	NSUndoManager			*undoManager;
    //TimEdit
    SIMThreadState          mThreadState;
    NSThread                **mSIMWorkerThreads;
    NSConditionLock         *mWorkerThreadProcessingLock;
    NSCondition             *mMainThreadSignal;
    unsigned int            mNumWorkerThreads;
    //pthread_rwlock_t        *mThreadStateLock;
    //pthread_rwlockattr_t    *mThreadStateLockAttributes;
}

+ networkWithDescription:(NSDictionary *)aDictionary;
+ (int) numberOfProcessors;

// Timedit
- (void) initNewWorkerThreads:(unsigned int)pNumThreads;
- (void) closeExistingWorkerThreads;
- (void) workerThreadLoop:(NSValue *)pLayerRangeValues;

- initWithDescription:(NSDictionary *)aDictionary node:(int)nodeID;
- (void) initializeNetwork;
- (void) initializeModels;
- (void) resetNetwork;
- (void) initConnections;
- (void) setInitialStates;
- (void) setRandomStates;
- (void) setNullStates;
- (void) setup;
- (void) setupLog;
- (NSDictionary *)logDictionary;
- (void) update:(int)n;
- (void) updateMilliseconds: (float) milliseconds;
- (void) update;
- (void) updateInputChannelsInLayers:(NSValue *)rangeValue;
- (void) updateIntrinsicChannelsInLayers:(NSValue *)rangeValue;
- (void) updateCellsInLayers:(NSValue *)rangeValue;
- (float) dt;
- (float) time;
- (void) setTime: (float) aTime;
- (id) objectAtPath:(NSString *) path;
- (void) setObject:(NSObject *)obj atPath:(NSString *)path;
- (NSUndoManager *)undoManager;

- (void) addAgentsWithContentsOfURL:(NSURL *)agentsLocation;
- (void) addAgent:(NSDictionary *)agentDescription withKey:(NSString *)agentKey;
- (void) removeAgentForKey:(NSString *)agentName;
- (void) removeAllAgents;


- (void) addIntrinsicChannel:(NSString *)channelName withDescription:(NSDictionary *)descDict toCellType:(NSString *)typeName inLayer:(NSString *)layerName;
- (void) addInputChannel:(NSString *)channelName withDescription:(NSDictionary *)descDict toCellType:(NSString *)typeName inLayer:(NSString *)layerName;
- (void) addCellCompartment:(NSString *)channelName withDescription:(NSDictionary *)descDict toCellType:(NSString *)typeName inLayer:(NSString *)layerName;

- (NSMutableDictionary *) rootDictionary;  // same as -dictionary.
- (NSMutableDictionary *) layerDictionary;
- (NSMutableDictionary *) typesDictionaryForLayer:(int)layer;
- (NSMutableDictionary *) typesDictionaryForLayerWithKey: (NSString *) key;

- (void) archiveStatesWithCoder:(NSCoder *)coder;
- (void) unarchiveStatesWithCoder:(NSCoder *)coder;

- (void) archiveActivityStatesWithCoder:(NSCoder *)coder;
- (void) unarchiveActivityStatesWithCoder:(NSCoder *)coder;

- (void) postStatusNotificationWithDescription:(NSString *)description progress:(float)progress;
- (void) postErrorNotificationWithDescription:(NSString *)description;
- (void)logEntry:(NSString *)entry;
- (void) setParameter:(NSString *) path value:(NSObject *) value;
@end

@interface SIMNetwork (SIMNetworkPrivate)
- (void) _initTypes;
- (void) _initAgents;
- (void) _initDictionaries;
- (void) _initLayers;
- (void) _initTopology;
- (void) _setDescriptionDictionary:(NSDictionary *)aDictionary;
- (void) _initChannelDictionaries;
- (void) _updateConnectionStatistics;
- (void) _addChannels:channels toTypes:(NSArray *)types fromType:(NSString *)fromType;
- (void) _initEfferentConnectionChannels:(NSDictionary *)effConnectsDict forType:(NSMutableDictionary *)aType withKey:(NSString *)typeKey;
- (void) _initAfferentConnectionChannels:(NSDictionary *)affConnectsDict forType:(NSMutableDictionary *)aType withKey:(NSString *)typeKey;

@end



