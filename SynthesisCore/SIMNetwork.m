/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */


#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisCore/SIMNetworkNode.h>
#import <SynthesisCore/SIMNetworkInfo.h>
#import <SynthesisCore/SIMNetworkStatistics.h>
#import <SynthesisCore/SIMNetworkTopology.h>
#import <SynthesisCore/SIMObject.h>
#import <SynthesisCore/SIMModel.h>
#import <SynthesisCore/SIMChannel.h>
#import <SynthesisCore/SIMCell.h>
#import <SynthesisCore/SIMType.h>
#import <SynthesisCore/SIMAgent.h>
#import <SynthesisCore/SIMConnections.h>
#import <PseudoRandomNum/PRNGenerator.h>
#import <stdio.h>
#import <sys/sysctl.h>

/*"

Simulates a multiple layer network  

"*/

@implementation SIMNetwork

+ new
/*"
	Returns a new autoreleased instance of a default Network object.
"*/
{
    return [[[SIMNetwork alloc] init] autorelease];
}

+ (int) numberOfProcessors
{
	int processors, error, selectors[2] = { CTL_HW, HW_NCPU };
	size_t datasize = sizeof(processors);
	error = sysctl(selectors, 2, &processors, &datasize, 0, 0);

	return processors;
}

- init
/*"
	Standard initialization of the Network object.  This method loads the template
	for the Network class and sets up the description dictionary from this template.
	This also sets the CreationDateKey to the current date and time.
"*/
{
    NSString *templatePath;
    NSString *className = NSStringFromClass([self class]);

    CLock = [[NSConditionLock alloc] initWithCondition:0];
    
    statusDict = [[NSMutableDictionary dictionary] retain];

    templatePath = [[NSBundle bundleForClass:[self class]]
            pathForResource:NSStringFromClass([self class]) ofType:TEMPLATE_EXTENSION];

    NSAssert1(templatePath,@"Template file must exist in the bundle for the class: %@",className);

    [descriptionDictionary setObject:[[NSDate date] description] forKey:SIMCreationDateKey];

    [self _setDescriptionDictionary:[NSMutableDictionary dictionaryWithContentsOfFile:templatePath]];

    //Timedit

    mThreadState = SIM_THREAD_IDLE;
    mWorkerThreadProcessingLock = [[NSConditionLock alloc] initWithCondition:0];
    mMainThreadSignal = [[[NSCondition alloc] init] autorelease];
    mNumWorkerThreads = 0;
    //mThreadStateLock = (pthread_rwlock_t *) NSZoneMalloc ([self zone], sizeof (pthread_rwlock_t));
    //mThreadStateLockAttributes = (pthread_rwlockattr_t *) NSZoneMalloc([self zone], sizeof(pthread_rwlockattr_t));

    //pthread_rwlockattr_init(mThreadStateLockAttributes);
    //pthread_rwlock_init(mThreadStateLock, mThreadStateLockAttributes);

    return self;

}

+ networkWithDescription:(NSDictionary *)aDictionary
/*"
    Returns a new network object initialized with the configuration described in
    aDictionary.
"*/
{
	return [[(SIMNetwork *)[self alloc] initWithDescription:aDictionary node:0] autorelease];
}

- initWithDescription:(NSDictionary *)aDictionary node:(int)nodeID
/*"
    Initializes the network object with the configuration described in
    aDictionary.  It initializes the types of cells followed by the layers, the
    layout of the cell types within the layers, and finally generates all the
    connections.
"*/
{
    [self init];
    if(aDictionary != nil){
        [self _setDescriptionDictionary:aDictionary];
    }
    
    undoManager = [[NSUndoManager alloc] init];
    [self setParameter:@"/NUMBER_OF_PROCESSORS" value:[NSString stringWithFormat:@"%d",[SIMNetwork numberOfProcessors]]];

    [descriptionDictionary setInt:nodeID forKey:SIMNodeKey];

    [self _initTypes];
    [self _initAgents];
	
    return self;
}

- (void)initializeNetwork
/*"
    Perform a full initialize of the network.  This performs the setup, memory allocation,
    and full initialization of connections, initial states and sets the time to 0.0.
"*/
{
    [self setup];
    [self _initLayers];
    [self _initTopology];
    [self initializeModels];
    [self initConnections];
    [self setInitialStates];
    [self setTime: 0.0];
}

- (void)resetNetwork
/*"
    If a flag (SIMInitConnectionsFlag) is set to be YES in the description dictionary,
    then all connections are rebuilt when this method is called.  Calls initializeModels for
    each model and sets the initial states.
"*/
{
    // This flag (see Simulator.h) should be set to YES if you would like
    // the connections to be updated to the current parameter values.
    [self initializeModels];

    if([descriptionDictionary boolForKey:SIMInitConnectionsFlag]){
            [self initConnections];
    }

    [self _emptyRemoteUpdateQueues];
    [self setInitialStates];
}

- (void) _setDescriptionDictionary: (NSDictionary *) aDict
{
    id obj;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    if(!descriptionDictionary)descriptionDictionary = [[NSMutableDictionary dictionary] retain];
    [descriptionDictionary addEntriesFromDictionary:aDict];

    obj = [descriptionDictionary objectForKey:SIMModelLibraryKey];
    if([obj isKindOfClass:[NSString class]]){
        NSMutableDictionary *library = [NSMutableDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:obj]];
        if(!library){
            NSLog(@"Could not load model library from URL: %@",obj);
            return;
        }
        else [descriptionDictionary setObject:library forKey:SIMModelLibraryKey];
    };

    if([descriptionDictionary objectForKey:INSPECTORS_KEY]){
        [dict addEntriesFromDictionary:[descriptionDictionary objectForKey:INSPECTORS_KEY]];
    }
    [descriptionDictionary setObject:dict forKey:INSPECTORS_KEY];
    
    layerDictionary = [[descriptionDictionary objectForKey:SIMLayersKey] mutableCopy];
    [descriptionDictionary setObject:layerDictionary forKey:SIMLayersKey];

    nodeDictionary = [[descriptionDictionary objectForKey:SIMNodesKey] mutableCopy];
    [descriptionDictionary setObject:nodeDictionary forKey:SIMNodesKey];

    [self _initDictionaries];
    [self _initChannelDictionaries];

}

- (void) _initDictionaries
{
    int			layerIndex = 0;
    id			layerKey,typeKey;
    NSEnumerator	*layerEnumerator,*typeEnumerator;
    SIMType		*thisType;
    NSMutableDictionary	*thisLayer, *typeDictionary;

    //TimEdit
    layerEnumerator = [[layerDictionary allKeys] objectEnumerator];

    // Cycle through the dictionary of types for each layer.
    // Make all dictionaries mutable

    while (layerKey = [layerEnumerator nextObject]) {
        NSAutoreleasePool *subpool = [[NSAutoreleasePool alloc] init];
        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Layer" ofType:TEMPLATE_EXTENSION];

        thisLayer = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        [thisLayer addEntriesFromDictionary:[layerDictionary objectForKey: layerKey]];
        [thisLayer setObject:[NSNumber numberWithInt:layerIndex++] forKey:SIMIndexKey];
        typeDictionary = [[thisLayer objectForKey: SIMTypesKey] mutableCopy];
        //Another TIMEDIT
        //typeEnumerator = [typeDictionary keyEnumerator];
        typeEnumerator = [[typeDictionary allKeys] objectEnumerator];
        while((typeKey=[typeEnumerator nextObject])){	
            thisType = [[typeDictionary objectForKey:typeKey] mutableCopy];
            // Need to add a mutable dictionary for adding intrinsic channel models
            if([thisType objectForKey:SIMIntrinsicChannelsKey]){
                NSMutableDictionary *channelModels = [NSMutableDictionary dictionaryWithDictionary:[thisType objectForKey:SIMIntrinsicChannelsKey]];
                [thisType setObject:channelModels forKey:SIMIntrinsicChannelsKey];
            }
            else [thisType setObject:[NSMutableDictionary dictionary] forKey:SIMIntrinsicChannelsKey];
            // Need to add a mutable dictionary for adding input channel models
            if([thisType objectForKey:SIMInputChannelsKey]){
                NSMutableDictionary *channelModels = [NSMutableDictionary dictionaryWithDictionary:[thisType objectForKey:SIMInputChannelsKey]];
                [thisType setObject:channelModels forKey:SIMInputChannelsKey];
            }
            else [thisType setObject:[NSMutableDictionary dictionary] forKey:SIMInputChannelsKey];

            [typeDictionary setObject: thisType forKey: typeKey];
        }
        [thisLayer setObject: typeDictionary forKey: SIMTypesKey];
        [layerDictionary setObject: thisLayer forKey: layerKey];
        [subpool release];
    }
    [descriptionDictionary setObject: layerDictionary forKey: SIMLayersKey];
}

- (void) _initChannelDictionaries
{
    NSEnumerator *typeKeyEnum;
    NSDictionary *typesDict;
    NSString *typeKey;
    NSString *typesToGet = [NSString stringWithFormat:@"%@%@%@",SIM_All,SIM_TypeSeparator,SIM_All];

    // Place the channel model dictionaries in the Channel Models dictionary
    // for the appropriate type (the types to which the efferents project).
    typesDict = [[self getType:typesToGet] retain];
    typeKeyEnum = [typesDict keyEnumerator];
    while(typeKey = [typeKeyEnum nextObject]){
        NSMutableDictionary *currentType = (NSMutableDictionary *)[typesDict objectForKey:typeKey];            

        [self _initEfferentConnectionChannels:[currentType objectForKey:SIMEfferentConnectionsKey] forType:currentType withKey:typeKey];

        [self _initAfferentConnectionChannels:[currentType objectForKey:SIMAfferentConnectionsKey] forType:currentType withKey:typeKey];

    }
    [typesDict release];
}


- (void) _initEfferentConnectionChannels:(NSDictionary *)effConnectsDict forType:(NSMutableDictionary *)aType withKey:(NSString *)typeKey
{
    NSDictionary *modelLibraryDict = [[descriptionDictionary objectForKey:SIMModelLibraryKey] objectForKey:SIMInputChannelsKey];
    NSString *effKey;
    NSMutableDictionary *efferentConnections = [NSMutableDictionary dictionaryWithDictionary:effConnectsDict];
    //TimEdit
    //NSEnumerator *effEnum = [efferentConnections keyEnumerator];
    NSEnumerator *effEnum = [[efferentConnections allKeys] objectEnumerator];
    while((effKey = [effEnum nextObject])){
        NSMutableDictionary *effConnections = [NSMutableDictionary dictionaryWithDictionary:[efferentConnections objectForKey:effKey]];
        NSDictionary *projectionInfo = [effConnections objectForKey:SIMProjectionInfoKey];
        NSArray *typesArray = [projectionInfo objectForKey:SIMTypesKey];
        id channelModelDict = [effConnections objectForKey:SIMChannelModelKey];
        NSString *connectTypeKey = [NSString stringWithFormat:@"%@%@%@",typeKey,SIM_TypeSeparator,effKey];
                        
        if([channelModelDict isKindOfClass:[NSString class]]){ 
            id modelDict;
            if([modelLibraryDict objectForKey:channelModelDict]) {
                modelDict = [modelLibraryDict objectForKey:channelModelDict];
                channelModelDict = [NSMutableDictionary dictionaryWithDictionary:modelDict];
            }
            else NSLog(@"No model \"%@\" defined in network file or model library.",channelModelDict);   
        }
                        
        [self _addChannels:channelModelDict toTypes:typesArray fromType:connectTypeKey];

        if([channelModelDict isKindOfClass:[NSArray class]])
            [effConnections setObject:channelModelDict forKey:SIMChannelModelKey];
        else [effConnections setObject:connectTypeKey forKey:SIMChannelModelKey];

        [efferentConnections setObject:effConnections forKey:effKey];
        [effConnections release];
    }

    [aType setObject:efferentConnections forKey:SIMEfferentConnectionsKey];

}

- (void) _initAfferentConnectionChannels:(NSDictionary *)affConnectDict forType:(NSMutableDictionary *)aType withKey:(NSString *)typeKey
{

    // Place the channel model dictionaries in the INPUT_CHANNELS dictionary
    // for the current type.
    NSDictionary *modelLibraryDict = [[descriptionDictionary objectForKey:SIMModelLibraryKey] objectForKey:SIMInputChannelsKey];
    NSEnumerator *affEnum;
    NSString *affKey;
    NSMutableDictionary *afferentConnections = [NSMutableDictionary dictionaryWithDictionary:affConnectDict];
    //TimEdit
    affEnum = [[afferentConnections allKeys] objectEnumerator];
    while((affKey = [affEnum nextObject])){
        NSMutableDictionary *affConnections = [NSMutableDictionary dictionaryWithDictionary:[afferentConnections objectForKey:affKey]];
        id channelModelDict = [affConnections objectForKey:SIMChannelModelKey];
        NSString *connectTypeKey = [NSString stringWithFormat:@"%@%@%@",typeKey,SIM_TypeSeparator,affKey];
        NSMutableDictionary *channelModels = [aType objectForKey:SIMInputChannelsKey];

        if([channelModelDict isKindOfClass:[NSString class]]){ 
            id modelDict;
            if([modelLibraryDict objectForKey:channelModelDict]){
                modelDict = [modelLibraryDict objectForKey:channelModelDict];
                channelModelDict = [NSMutableDictionary dictionaryWithDictionary:modelDict];
            }
            else NSLog(@"No model \"%@\" defined in network file or model library.",channelModelDict);   
        }

        if([channelModelDict isKindOfClass:[NSArray class]]){ 
        // If it is not a dictionary then use the key as the name
            NSEnumerator *connectEnum;
            id key;
            connectEnum = [channelModelDict objectEnumerator];
            while(key = [connectEnum nextObject]){
                if(![channelModels objectForKey:key]){
                    id newChannelModelDict = [modelLibraryDict objectForKey:key];
                    if(newChannelModelDict)[channelModels setObject:newChannelModelDict forKey:key];
                    else NSLog(@"No model \"%@\" defined in network file or model library.",key);   
                }
            }
        }
        else 
        if(![channelModels objectForKey:connectTypeKey]){
            [channelModels setObject:channelModelDict forKey:connectTypeKey];
            [affConnections setObject:connectTypeKey forKey:SIMChannelModelKey];
        }
        else NSLog(@"Conflict while adding afferent channel %@. A channel type with this name already exists.", connectTypeKey);
        [afferentConnections setObject:affConnections forKey:affKey];
    }
    [aType setObject:afferentConnections forKey:SIMAfferentConnectionsKey];
}

- (void) _addChannels:channels toTypes:(NSArray *)types fromType:(NSString *)fromType
// "channels" is a dictionary or array or string which will be instantiated as a channel channels later
// "types" is an array of strings such as (Thalamus.All,Cortex.All)
// "fromType" is a string such as "Thalamus.Excitatory.Cortical"
{
    NSEnumerator *typeEnum;
    NSDictionary *typesDict, *aTypeDict;
    NSDictionary *modelLibraryDict = [[descriptionDictionary objectForKey:SIMModelLibraryKey] objectForKey:SIMInputChannelsKey];

    typesDict = [self getTypes:types];
    typeEnum = [typesDict objectEnumerator];
    while((aTypeDict = [typeEnum nextObject])){
        NSMutableDictionary *dict = [[aTypeDict objectForKey:SIMInputChannelsKey] retain];
        if([channels isKindOfClass:[NSArray class]]){
            NSEnumerator *modelEnum = [channels objectEnumerator];
            id modelKey;
            while(modelKey = [modelEnum nextObject]){
                id model = [dict objectForKey:modelKey];
                if(!model)model = [modelLibraryDict objectForKey:modelKey];
                if(model && ![dict objectForKey:modelKey]){
                    [dict setObject:model forKey: modelKey];
                }
                if(!model) {
                    NSLog(@"ERROR: Could not find channel: %@.",modelKey);
                    return;
                }
            }
        }
        else if(channels && ![dict objectForKey:fromType]){
            [dict setObject:channels forKey:fromType];
        }
        else {
            NSLog(@"ERROR: Could not find channel for key %@.",fromType);
            return;
        }
        [dict release];
    }
    [typesDict release];
}

- (void) _initTypes
// This method instantiates the models needed for each type.
// It converts all the dictionary entries which correspond to objects
// into their instantiatations.
{
    id layerKey,typeKey;
    NSEnumerator *layerEnumerator,*typeEnumerator;
    SIMType *thisType;
    NSMutableDictionary *thisLayer, *typeDictionary;

    [self postStatusNotificationWithDescription:@"Initializing models..." progress:0.0];

    //layerEnumerator = [layerDictionary keyEnumerator];
    //TimEdit
    layerEnumerator = [[layerDictionary allKeys] objectEnumerator];

// Cycle through the dictionary of types for each layer.

    while (layerKey = [layerEnumerator nextObject]) {
        unsigned int typeIndex = 0;
        //NSAutoreleasePool *subpool = [[NSAutoreleasePool alloc] init];
        thisLayer = [layerDictionary objectForKey: layerKey];
        typeDictionary = [thisLayer objectForKey: SIMTypesKey];
        //Timedit
        //typeEnumerator = [typeDictionary keyEnumerator];
        typeEnumerator = [[typeDictionary allKeys] objectEnumerator];
        while((typeKey=[typeEnumerator nextObject])){
            Class theObjectClass;
            NSMutableDictionary *thisTypeDict = [[NSMutableDictionary dictionaryWithDictionary:[typeDictionary objectForKey:typeKey]] retain];
            if([thisTypeDict objectForKey:SIMClassNameKey])
                theObjectClass = [thisTypeDict typeClassForKey: SIMClassNameKey];
            else {
                [thisTypeDict setObject:@"SIMType" forKey: SIMClassNameKey];
                theObjectClass = [thisTypeDict typeClassForKey: SIMClassNameKey];
            }

            thisType = [[theObjectClass alloc] initWithDescription:thisTypeDict 
                usingModelLibrary:[descriptionDictionary objectForKey:SIMModelLibraryKey]];
            [thisType setName:typeKey];
            [thisType setAssignedIndex:typeIndex++];
            [typeDictionary setObject: thisType forKey: typeKey];
            [thisLayer setObject: typeDictionary forKey: SIMTypesKey];
            [thisType autorelease];
            [thisTypeDict autorelease];
        }
        [layerDictionary setObject: thisLayer forKey: layerKey];
        //[subpool release];
    }		
    [self postStatusNotificationWithDescription:@"Finished initializing models." progress:1.0];
}

- (void) _initAgents
{
    id agents;

    agents = [descriptionDictionary objectForKey:SIMAgentsKey];
	
	if((agents = [descriptionDictionary objectForKey:SIMAgentsKey]) == nil){
	    agents = [[NSMutableDictionary alloc] init];
		[descriptionDictionary setObject:[agents autorelease] forKey:SIMAgentsKey];
	}
    else
    if([agents isKindOfClass:[NSString class]]){
		[descriptionDictionary setObject:[NSMutableDictionary dictionary] forKey:SIMAgentsKey];
		[self addAgentsWithContentsOfURL:[NSURL URLWithString:agents]];
    }
	else
    if(agents){
        //TimEdit
        NSEnumerator *agentEnum = [[agents allKeys] objectEnumerator];
        NSString *agentKey;
        while(agentKey = [agentEnum nextObject]){
            NSDictionary *agentDescription = [agents objectForKey:agentKey];
			[self addAgent:agentDescription withKey:agentKey];
        }
    }
}

- (void) addAgentsWithContentsOfURL:(NSURL *)agentsLocation
{
    NSMutableDictionary *agents = [[NSMutableDictionary dictionaryWithContentsOfURL:agentsLocation] retain];
	if(!agents){
		NSLog(@"Could not load agent library from URL: %@",agents);
		return;
	}
	NSEnumerator *agentEnum = [agents keyEnumerator];
	NSString *agentKey;
	while(agentKey = [agentEnum nextObject]){
		NSDictionary *agentDescription = [agents objectForKey:agentKey];
		[self addAgent:agentDescription withKey:agentKey];
	}
	
}


- (void) addAgent:(NSDictionary *)agentDescription withKey:(NSString *)agentKey
{
	agentDictionary = [descriptionDictionary objectForKey:SIMAgentsKey];

	SIMAgent *theAgent;

	Class agentClass = [agentDescription agentClassForKey: SIMClassNameKey];
	if(agentClass){
		theAgent = [(SIMAgent *)[agentClass alloc] initWithDescription: agentDescription forNetwork:self];
		if (theAgent){
			if(!agentClasses)agentClasses = [[NSMutableSet alloc] init];
			[agentClasses addObject:NSStringFromClass(agentClass)];
			[agentDictionary setObject:theAgent forKey: agentKey];
		}
		else NSLog(@"No agent instantiated.");
	}
	else NSLog(@"Problem instantiating agent %@.",agentKey);
}

- (void) removeAgentForKey:(NSString *)agentName
{
	agentDictionary = [descriptionDictionary objectForKey:SIMAgentsKey];
	@try{
		[agentDictionary removeObjectForKey:agentName];
	}
	@catch (id exception){
		NSLog([exception description]);
	}
}

- (void) removeAllAgents
{
	agentDictionary = [descriptionDictionary objectForKey:SIMAgentsKey];
	@try{
		[agentDictionary removeAllObjects];
	}
	@catch (id exception){
		NSLog([exception description]);
	}

}

- (void) _initLayers
{
    int	i, j, l;

    [self postStatusNotificationWithDescription:@"Allocating memory for layers..." progress:0.0];

    if (layers) {NSZoneFree ([self zone], layers); layers = (SIMState ***) nil;}

    layers = (SIMState ***) NSZoneMalloc ([self zone], numLayers * sizeof (SIMState **)); 

    for (l = 0; l < numLayers; l++) {
        if(layerInfo[l].node != localNode)continue;
        layers[l] = NSZoneMalloc ([self zone], layerInfo[l].numRows * sizeof(SIMState *));
        for (i = 0; i < layerInfo[l].numRows; i++){
            layers[l][i] = NSZoneMalloc([self zone],layerInfo[l].numColumns*sizeof(SIMState));
            for (j = 0; j < layerInfo[l].numColumns; j++) {
                layers[l][i][j].type = SIM_UndefinedType;
                layers[l][i][j].position.x = j;
                layers[l][i][j].position.y = i;
                layers[l][i][j].position.z = l;
                layers[l][i][j].connections =
                        [[NSMutableValueArray
                                valueArray: nil
                                count: 0
                                withObjCType: @encode (SIMConnection)] retain];
            }
        }
    } 
    [self postStatusNotificationWithDescription:@"Finished allocating memory for layers." progress:1.0];
}


- (void) _initTopology
{
	int		i = 0, j = 0, l = 0, typeCount = 0, count;
	NSDictionary	*thisLayer;
        NSString	*topologyType,*status;
	int		typeIndex;
	PRNGenerator	*generator;
	
        [self postStatusNotificationWithDescription:@"Initializing topology:" progress:0.0];
	
	for (l = 0; l < numLayers; l++) {
            int numRows = layerInfo[l].numRows;
            int numColumns = layerInfo[l].numColumns;
            NSString *layerKey = [self keyForLayerAtIndex:l];
            if(layerInfo[l].node != localNode)continue;
            thisLayer = [self layerDictionaryForIndex:l];
            topologyType = [thisLayer objectForKey:SIMTopologyTypeKey];
            status = [NSString stringWithFormat:@"Initializing layer %d (%@):\n\tRows %d, Columns %d, Distribution %@.",l,layerKey,numRows,numColumns,topologyType];
            [self postStatusNotificationWithDescription:status progress:(float)l/(float)numLayers];

            // this means that layers with same topologyType will use
            // the same seed -- if this is a problem, add something to
            // change the seed (or get it from the dictionary for example)
            if ([topologyType isEqual:SIM_SobolTopology]){
                    generator = [[PRNGenerator sobolGenerator] retain];
                    [(PRNSobolGenerator *)generator setNumSequences:2];
            }
            else{
                    generator = [[PRNGenerator marsagliaGenerator] retain];
            }

            for (typeIndex = 0; typeIndex< layerInfo[l].numTypes; typeIndex++){
                    SIMType *currentType = layerInfo[l].types[typeIndex];
                    int tries = 0;
                    float fraction = [currentType percentage]*.01;
                    typeCount = floor (numColumns * numRows * fraction);
                    count = 0;

                    if (fraction == 1.0) {
                        // Fill in the entire layer with just this type
                        for (i = 0; i < numRows; i++){
                            for (j = 0; j < numColumns; j++){
                                [currentType allocState:&layers[l][i][j]];
                            }
                        }
                        status = [NSString stringWithFormat:@"Allocated 100 percent of layer %d as type: %@",l,[currentType name]];
                        [self postStatusNotificationWithDescription:status progress:0.0];
                    }
                    else do {
                            i = numRows * [generator nextDouble];
                            j = numColumns * [generator nextDouble];
                            if (layers[l][i][j].type == SIM_UndefinedType){
                                    [currentType allocState:&layers[l][i][j]];
                                    count++;
                            }
                            tries++;
                    } while (count < typeCount && tries < typeCount * 100);
                    status = [NSString stringWithFormat:@"Allocated type %@: %d cells, fraction = %f.",[currentType name],typeCount,fraction];
                    [self postStatusNotificationWithDescription:status progress:0.0];
            }
            [generator release];
	}	
    [self postStatusNotificationWithDescription:@"Topology initialized." progress:1.0];
}	

- (void) addIntrinsicChannel:(NSString *)channelName withDescription:(NSDictionary *)descDict toCellType:(NSString *)typeName inLayer:(NSString *)layerName
{
	int l,i,j;
	SIMType *thisType = [[self typesDictionaryForLayerWithKey:layerName] objectForKey:typeName];
	
	[thisType addIntrinsicChannel:channelName withDescription:descDict];
	
	SIMModel *theModel = [thisType intrinsicChannelWithName:channelName];
	l = [self indexForLayerWithKey:layerName];
	
	for (i = 0; i < layerInfo[l].numRows; i++){
		for (j = 0; j < layerInfo[l].numColumns; j++){
			if(layers[l][i][j].type == thisType)[thisType reallocState:&layers[l][i][j] forModel:theModel];
		}
	}
}

- (void) addInputChannel:(NSString *)channelName withDescription:(NSDictionary *)descDict toCellType:(NSString *)typeName inLayer:(NSString *)layerName
{
	int l,i,j;
	SIMType *thisType = [[self typesDictionaryForLayerWithKey:layerName] objectForKey:typeName];
	
	[thisType addInputChannel:channelName withDescription:descDict];
	
	SIMModel *theModel = [thisType inputChannelWithName:channelName];
	l = [self indexForLayerWithKey:layerName];
	
	for (i = 0; i < layerInfo[l].numRows; i++){
		for (j = 0; j < layerInfo[l].numColumns; j++){
			if(layers[l][i][j].type == thisType)[thisType reallocState:&layers[l][i][j] forModel:theModel];
		}
	}
}

- (void) addCellCompartment:(NSString *)channelName withDescription:(NSDictionary *)descDict toCellType:(NSString *)typeName inLayer:(NSString *)layerName
{
	int l,i,j;
	SIMType *thisType = [[self typesDictionaryForLayerWithKey:layerName] objectForKey:typeName];
	
	[thisType addCellCompartment:channelName withDescription:descDict];
	
	SIMModel *theModel = [thisType cellCompartmentWithName:channelName];
	l = [self indexForLayerWithKey:layerName];
	
	for (i = 0; i < layerInfo[l].numRows; i++){
		for (j = 0; j < layerInfo[l].numColumns; j++){
			if(layers[l][i][j].type == thisType)[thisType reallocState:&layers[l][i][j] forModel:theModel];
		}
	}
}

- (void) _removeConnections
{
    int	row, col, l;

    for (l = 0; l < numLayers; l++) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        int numRows = layerInfo[l].numRows;
        int numColumns = layerInfo[l].numColumns;
        if(layerInfo[l].node != localNode)continue;
        for (row = 0; row < numRows; row++){
            for (col = 0; col < numColumns; col++){
                if (layers[l][row][col].type != SIM_UndefinedType)
                    [layers[l][row][col].connections removeAllObjects];
            }
        }
        [pool release];
    }	
}

- (void) initConnections
/*"
	Initalizes all connections that form the network.  First it removes any existing 
	connections and then cycles through all elements in the network generating and
	adding new afferent and efferent connections. 
"*/
{
// This could be made multithreaded to speed up the process.
	int	i, j, l;

        [self postStatusNotificationWithDescription:@"Initializing connections..." progress:0.0];

	[self _removeConnections];
	for (l = 0; l < numLayers; l++) {
            int numRows = layerInfo[l].numRows;
            int numColumns = layerInfo[l].numColumns;
            
            if(layerInfo[l].node != localNode)continue;
            // NEEDS ATTENTION

            for (i = 0; i < numRows; i++){
                for (j = 0; j < numColumns; j++){
                    SIMType		*currentType;
                    NSEnumerator 	*connectionEnumerator;
                    NSDictionary 	*connectionDict;
                    NSString	*connectionKey;

                    if (layers[l][i][j].type == SIM_UndefinedType)
                            continue;

                    currentType = layers[l][i][j].type;

                    connectionDict = [currentType efferentConnectionModels];
                    connectionEnumerator = [connectionDict keyEnumerator];
                    while (connectionKey = [connectionEnumerator nextObject]){
                        NSDictionary *connectionDesc = [connectionDict objectForKey:connectionKey];
                        id temp = [connectionDesc objectForKey:SIMChannelModelKey];
                        NSArray *channelArray;
                        if(![temp isKindOfClass:[NSArray class]]){
                            channelArray = [NSArray arrayWithObject:temp];
                        }
                        else channelArray = [connectionDesc objectForKey:SIMChannelModelKey];
                        [self addEfferentConnections:connectionDesc
                            toChannels:channelArray forCell:layers[l][i][j].position];
                    }

                    connectionDict = [currentType afferentConnectionModels];
                    connectionEnumerator = [connectionDict keyEnumerator];
                    while (connectionKey = [connectionEnumerator nextObject]){
                        NSDictionary *connectionDesc = [connectionDict objectForKey:connectionKey];
                        id temp = [connectionDesc objectForKey:SIMChannelModelKey];
                        NSArray *channelArray;
                        if(![temp isKindOfClass:[NSArray class]]){
                            channelArray = [NSArray arrayWithObject:temp];
                        }
                        else channelArray = [connectionDesc objectForKey:SIMChannelModelKey];
                        [self addAfferentConnections:connectionDesc
                            toChannels:channelArray forCell: layers[l][i][j].position];
                    }
                }
            }
	}	
        
        for (l = 0; l < numLayers; l++) {
            int numRows = layerInfo[l].numRows;
            int numColumns = layerInfo[l].numColumns;
            
            if(layerInfo[l].node != localNode)continue;
            // NEEDS ATTENTION

            for (i = 0; i < numRows; i++){
                for (j = 0; j < numColumns; j++){
                    layerInfo[l].numConnections += [layers[l][i][j].connections count];
                }
            }
            //printf("Layer %d: numConnections: %d\n",l,layerInfo[l].numConnections);
        }

        [self _updateConnectionStatistics];

    [self postStatusNotificationWithDescription:@"Connections initialized." progress:1.0];
}

- (void) _updateConnectionStatistics
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    SIMType *thisType;
    int l,row,col,numRows,numColumns;
        
    for (l = 0; l < numLayers; l++) {
        if(layerInfo[l].node != localNode)continue; // May not be needed
        numRows = layerInfo[l].numRows;
        numColumns = layerInfo[l].numColumns;
        for (row = 0; row < numRows; row++) {
            for (col = 0; col < numColumns; col++){
                int count, index;
                SIMConnection *bytes;


/* We cycle through all the connections and calculate what the
* position of the cell that our current cell connects to is.  Each
* connection coordinate is given in terms of an offset from the
* actual cell so it is easy to just add the offset in each direction
* to find the position of the connected cell.
*/

                count = [layers[l][row][col].connections count];

                bytes = (SIMConnection *)[layers[l][row][col].connections mutableBytes];
                for(index = 0;index < count; index++){
                    SIMPosition	position;
                    SIMConnection *connection=&bytes[index];
                    position.z = (l+connection->dz);
                    position.y = (row+connection->dy);
                    position.x = (col+connection->dx);

// This must be implemented for multiple nodes
#if 0    
                    if(layerInfo[l].node != localNode){ // buffer remote update information
                        SIMPosition currentPos;
                        currentPos.z = l;
                        currentPos.y = row;
                        currentPos.x = col;
                        NS_DURING
                            [self remoteInitializeConnection:connection
                                toState:&layers[l][row][col]];
                        NS_HANDLER
                            NSLog ([localException name]);
                            NSLog ([localException reason]);
                        NS_ENDHANDLER
                        continue;
                    };
#endif    
                    if (layers[position.z][position.y][position.x].type == SIM_UndefinedType) continue;

                    thisType = layers[position.z][position.y][position.x].type;


                    NS_DURING
                        [thisType initializeConnection:connection toState:&layers[position.z][position.y][position.x]];
                    NS_HANDLER
                        NSLog ([localException name]);
                        NSLog ([localException reason]);
                    NS_ENDHANDLER
                }
            }
        }
    }
    [pool release];
}


#ifdef SINGLETHREADED
#warning BUILDING SINGLETHREADED ENGINE
/*	This is the main routine.  This is where the variables for the layers[][][]
 *	get updated and the the activity is fed through the various channel methods
 */
- (void) update
/*"
	The main method of all simulations.  First all channel element states are updated
	(see SIMType method updateChannelState:dt:time:). Subsequently all cell states are 
	updated (see SIMType method updateCellState:dt:time:). If a cell is firing (see
	SIMType method isCellFiring:) this method cycles through all connections for that 
	cell and updates the state of the destination cell using the SIMType of the destination 
	cell. (see SIMType method updateConnection:fromState:toState:dt:time:).
	If the connection strength is equal to 0.0 the target cell is not updated.

	A notification (SIMNetworkDidUpdateNotification) is posted indicating that
	the network has been updated for one time step.  Finally, the time is incremented by the
	timestep dt.
"*/
{
	int		l, row, col,numRows,numColumns;
	SIMType		*thisType;	
	SIMPosition	position;
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	for (l = 0;l < numLayers; l++){
            if(layerInfo[l].node != localNode)continue;
            numRows = layerInfo[l].numRows;
            numColumns = layerInfo[l].numColumns;
            for (row = 0; row < numRows; row++) {
                for (col = 0; col < numColumns; col++){
                        if (layers[l][row][col].type == SIM_UndefinedType)
                                continue;
                        thisType = layers[l][row][col].type;

                        NS_DURING
                                [thisType updateChannelState:&layers[l][row][col] dt:dt time:time];
                        NS_HANDLER
                                NSLog ([localException name]);
                                NSLog ([localException reason]);
                        NS_ENDHANDLER
                }
            }
	}
    for (l = 0;l < numLayers; l++){
        if(layerInfo[l].node != localNode)continue;
        numRows = layerInfo[l].numRows;
        numColumns = layerInfo[l].numColumns;
		for (row = 0; row < numRows; row++) {
			for (col = 0; col < numColumns; col++){

/* In order to update the network we need to cycle through the entire
 * network and calculate the current state according to the input
 * from the previous time cycle.
 */
				if (layers[l][row][col].type == SIM_UndefinedType) 
					continue; // Skip this cell if it's undefined.

				thisType = layers[l][row][col].type;

/* The channel output method takes all the summed input from the
 * many cells and applies a threshold to it to allow only a certain
 * level of input into the cell's input.
 */
				NS_DURING
				[thisType updateCellState:&layers[l][row][col] dt:dt time:time];
				NS_HANDLER
                                    NSLog ([localException name]);
                                    NSLog ([localException reason]);
				NS_ENDHANDLER
				
/* After we have updated the activity of the cell we need to determine
 * if it is firing or not and propagate the activity on to the cells
 * it is connected to if it is.
 */

                if ([thisType shouldCellUpdateConnections:&layers[l][row][col]]){
					int				count, index;
					SIMConnection	*bytes;
/* We cycle through all the connections and calculate what the
 * position of the cell that our current cell connects to is.  Each
 * connection coordinate is given in terms of an offset from the
 * actual cell so it is easy to just add the offset in each direction
 * to find the position of the connected cell.
 */

					count = [layers[l][row][col].connections count];

					bytes = (SIMConnection *)[layers[l][row][col].connections mutableBytes];
					for(index = 0;index < count; index++){
						SIMConnection *connection=&bytes[index];
						position.z = (l+connection->dz);
						position.y = (row+connection->dy);
						position.x = (col+connection->dx);

	
					if (layers[position.z][position.y][position.x].type 
						== SIM_UndefinedType /*|| connection->strength == 0*/) continue;

					thisType = layers[position.z][position.y][position.x].type;

/* Here we propagate activity that is above threshold to the neurons
 * to which it is connected.  This provides an opportunity for
 * connection strengths to be updated as well, providing a convenient
 * location for activity dependent learning.
 */						
 
					NS_DURING
						[thisType updateConnection:connection
							fromState:&layers[l][row][col]
							toState:&layers[position.z][position.y][position.x]
							dt:dt time:time];
					NS_HANDLER
						NSLog ([localException name]);
						NSLog ([localException reason]);
					NS_ENDHANDLER
					}
				}
			}
		}
	}	
    time += dt;

    [[NSNotificationCenter defaultCenter]
        postNotificationName:SIMNetworkDidUpdateNotification object:self];
    [pool release];
}

#else
#warning BUILDING MULTITHREADED ENGINE

// Multithreaded version of the update method.  This forks a new thread for each layer update.
// There appears to be a very small penalty for this and possibly a great speed improvement
// in multiprocessor systems.
- (void) update
{
    int n,numThreads = MIN(numLayers,numProcessors);
    
    //TimEdit
    
    if (numThreads != mNumWorkerThreads) {
        [self initNewWorkerThreads:numThreads];
        //We can now safely assume we have a lock on the processing loop
        [mWorkerThreadProcessingLock lockWhenCondition:numThreads];
    }
    
    
    //
    //      UPDATE INTRINSIC CHANNELS
    //
    mThreadState = SIM_THREAD_UPDATE_INTRINSIC_CHANNELS;
    [mWorkerThreadProcessingLock unlockWithCondition:0];
    //printf("Main thread broadcasting intrinsic update...\n");
    //[mMainThreadSignal broadcast];
    // Now we wait for the threads 
    [mWorkerThreadProcessingLock lockWhenCondition:numThreads];
    
    
    //
    //      UPDATE INPUT CHANNELS
    //
    mThreadState = SIM_THREAD_UPDATE_INPUT_CHANNELS;
    [mWorkerThreadProcessingLock unlockWithCondition:0];
    //printf("Main thread broadcasting input update...\n");
    //[mMainThreadSignal broadcast];
    // Now we wait for the threads 
    [mWorkerThreadProcessingLock lockWhenCondition:numThreads];
    
    //
    //      UPDATE INPUT CHANNELS
    //
    mThreadState = SIM_THREAD_UPDATE_CELLS;
    [mWorkerThreadProcessingLock unlockWithCondition:0];
    //printf("Main thread broadcasting cell update...\n");
    //[mMainThreadSignal broadcast];
    // Now we wait for the threads 
    [mWorkerThreadProcessingLock lockWhenCondition:numThreads];
    

    if(numProcessors){
        time += dt;
        //timedit
        [[NSNotificationCenter defaultCenter] postNotificationName:SIMNetworkDidUpdateNotification object:self];
		//[[NSNotificationQueue defaultQueue] enqueueNotification:networkUpdateNotification postingStyle:NSPostNow];

    }
}

#endif

- (void) closeExistingWorkerThreads {
    int i = 0;
    
    if (mNumWorkerThreads == 0) {
        //There aren't any existing worker threads, so just return
        return;
    }
    
    //We've got some threads going, tell them to terminate
    mThreadState = SIM_THREAD_TERMINATING;
    
    if([mWorkerThreadProcessingLock condition] != 0) {
        //Let any locked threads throguh
        [mWorkerThreadProcessingLock unlockWithCondition:0];
    }

    // wait for threads to sync and terminate
    while (mNumWorkerThreads > 0) {
        sleep(0);
    }
    //All worker threads should be done
    for(i = 0; i < mNumWorkerThreads; i++) {
        [mSIMWorkerThreads[i] release];
    }
    free(mSIMWorkerThreads);
    mNumWorkerThreads = 0;
    //Make sure we reset the lock so we don't have any runaway threads
    [mWorkerThreadProcessingLock lock];
    [mWorkerThreadProcessingLock unlockWithCondition:0];
}

- (void) initNewWorkerThreads:(unsigned int)pNumThreads {
    unsigned int i = 0;
    if(mSIMWorkerThreads) {
        [self closeExistingWorkerThreads];
    }
    mThreadState = SIM_THREAD_LAUNCHING;

    if(mWorkerThreadProcessingLock) {
        [mWorkerThreadProcessingLock release];
    }
    mWorkerThreadProcessingLock = [[NSConditionLock alloc] initWithCondition:0];
    if(mMainThreadSignal) {
        [mMainThreadSignal release];
    }
    mMainThreadSignal = [[NSCondition alloc] init];
    mNumWorkerThreads = 0;
    
    if(pNumThreads > 0) {
        mSIMWorkerThreads = (NSThread **)malloc(sizeof(NSThread*) * pNumThreads);
        for(i = 0; i < pNumThreads; i++) {
            int start = floor(numLayers * i / pNumThreads);
            int stop = floor(numLayers * (i+1) / pNumThreads);
            //mSIMWorkerThreads[i] = (NSThread *)[NSThread detachNewThreadSelector:@selector(workerThreadLoop) toTarget:self withObject:[NSValue valueWithRange:NSMakeRange(start, stop-start)]];
            mSIMWorkerThreads[i] = (NSThread *)[[NSThread alloc] initWithTarget:self selector:@selector(workerThreadLoop:) object:[NSValue valueWithRange:NSMakeRange   (start, stop-start)]];
            [mSIMWorkerThreads[i] start];
        }
    }
    mNumWorkerThreads = pNumThreads;
}

- (void) workerThreadLoop:(NSValue *)pLayerRangeValues {
    //[mMainThreadSignal lock]; 
    SIMThreadState lastState = SIM_THREAD_IDLE;
    
    while(mThreadState != SIM_THREAD_TERMINATING) {
        if (mThreadState == lastState) {
            //sleep(1);
            continue;
        }
        lastState = mThreadState;
        
        // State should have switched
        // If we're terminating, we shouldn't do anything here anyway
        switch (mThreadState) {
            case SIM_THREAD_LAUNCHING:
                // we just launched, do nothing!
                break;
            case SIM_THREAD_UPDATE_INTRINSIC_CHANNELS:
                [self updateIntrinsicChannelsInLayers:pLayerRangeValues];
                break;
            case SIM_THREAD_UPDATE_INPUT_CHANNELS:
                [self updateInputChannelsInLayers:pLayerRangeValues];
                break;
            case SIM_THREAD_UPDATE_CELLS:
                [self updateCellsInLayers:pLayerRangeValues];
                break;
            case SIM_THREAD_IDLE:
                break;
            default:
                break ;
        }
        // Tell the main thread that we're done 
        [mWorkerThreadProcessingLock lock];
        int count = [mWorkerThreadProcessingLock condition] + 1;
        //NSLog(@"%@", [NSThread currentThread]);
        //printf("  INCidng condition, old=%i new=%i\n", count-1, count);
        [mWorkerThreadProcessingLock unlockWithCondition:count];
    }
    
    //We're closing, signal we've closed
    // Tell the main thread that we're done 
    
    @synchronized(self) {
        mNumWorkerThreads--;
    }
}

- (void) updateIntrinsicChannelsInLayers:(NSValue *)rangeValue
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSRange range = [rangeValue rangeValue];
    unsigned condition;
    int l,row,col,numRows,numColumns;
    for (l = range.location; l < NSMaxRange(range); l++){
        if(layerInfo[l].node != localNode)continue; //May not be needed
        nodeInfo[localNode].status = SIM_NODE_WORKING;
        numRows = layerInfo[l].numRows;
        numColumns = layerInfo[l].numColumns;
        for (row = 0; row < numRows; row++) {
            for (col = 0; col < numColumns; col++){
                if (layers[l][row][col].type == SIM_UndefinedType) continue;

                NS_DURING
                    [layers[l][row][col].type updateIntrinsicChannelState:&layers[l][row][col] dt:dt time:time];
                NS_HANDLER
                NSLog ([localException name]);
                    NSLog ([localException reason]); 
                NS_ENDHANDLER
            }
        }
    }
    [pool release];
    
    // synchronize with main thread
    [CLock lock];
    condition = [CLock condition];
    [CLock unlockWithCondition:++condition];
}

- (void) updateInputChannelsInLayers:(NSValue *)rangeValue
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSRange range = [rangeValue rangeValue];
    unsigned condition;
    int l,row,col,numRows,numColumns;
    for (l = range.location; l < NSMaxRange(range); l++){
        if(layerInfo[l].node != localNode)continue; //May not be needed
        nodeInfo[localNode].status = SIM_NODE_WORKING;
        numRows = layerInfo[l].numRows;
        numColumns = layerInfo[l].numColumns;
        for (row = 0; row < numRows; row++) {
            for (col = 0; col < numColumns; col++){
                if (layers[l][row][col].type == SIM_UndefinedType) continue;

                NS_DURING
                    [layers[l][row][col].type updateInputChannelState:&layers[l][row][col] dt:dt time:time];
                NS_HANDLER
                    NSLog ([localException name]);
                    NSLog ([localException reason]);
                NS_ENDHANDLER
            }
        }
    }
    [pool release];
    
    // synchronize with main thread
    [CLock lock];
    condition = [CLock condition];
    [CLock unlockWithCondition:++condition];
}

- (void) updateCellsInLayers:(NSValue *)rangeValue
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSRange range = [rangeValue rangeValue];
    SIMType *thisType;
    unsigned condition;
    int l,row,col,numRows,numColumns;
    for (l = range.location; l < NSMaxRange(range); l++) {
        if(layerInfo[l].node != localNode)continue; // May not be needed
        numRows = layerInfo[l].numRows;
        numColumns = layerInfo[l].numColumns;
        for (row = 0; row < numRows; row++) {
            for (col = 0; col < numColumns; col++){

    /* In order to update the network we need to cycle through the entire
    * network and calculate the current state according to the input
    * from the previous time cycle.
    */
                if (layers[l][row][col].type == SIM_UndefinedType) continue;

                thisType = layers[l][row][col].type;

    /* The channel output method takes all the summed input from the
    * many cells and applies a threshold to it to allow only a certain
    * level of input into the cell's input.
    */
                NS_DURING
                    [thisType updateCellState:&layers[l][row][col] dt:dt time:time];
                NS_HANDLER
                    NSLog ([localException name]);
                    NSLog ([localException reason]);
                NS_ENDHANDLER

    /* After we have updated the activity of the cell we need to determine
    * if it is firing or not and propagate the activity on to the cells
    * it is connected to if it is.
    */

                if ([thisType shouldCellUpdateConnections:&layers[l][row][col]]){
                    int count, index;
                    SIMConnection *bytes;
    /* We cycle through all the connections and calculate what the
    * position of the cell that our current cell connects to is.  Each
    * connection coordinate is given in terms of an offset from the
    * actual cell so it is easy to just add the offset in each direction
    * to find the position of the connected cell.
    */

                    count = [layers[l][row][col].connections count];

                    bytes = (SIMConnection *)[layers[l][row][col].connections mutableBytes];
                    for(index = 0;index < count; index++){
                        SIMPosition	position;
                        SIMConnection *connection=&bytes[index];
                        position.z = (l+connection->dz);
                        position.y = (row+connection->dy);
                        position.x = (col+connection->dx);

                        if(layerInfo[l].node != localNode){ // buffer remote update information
                            SIMPosition currentPos;
                            currentPos.z = l;
                            currentPos.y = row;
                            currentPos.x = col;
                            NS_DURING
                                [self remoteUpdateWithConnection:connection
                                    fromState:&layers[l][row][col]
                                    dt:dt time:time];
                            NS_HANDLER
                                NSLog ([localException name]);
                                NSLog ([localException reason]);
                            NS_ENDHANDLER
                            continue;
                        };

                        if (layers[position.z][position.y][position.x].type
                                == SIM_UndefinedType /*|| connection->strength == 0*/) continue;

                        thisType = layers[position.z][position.y][position.x].type;

    /* Here we propagate activity that is above threshold to the neurons
    * to which it is connected.  This provides an opportunity for
    * connection strengths to be updated as well, providing a convenient
    * location for activity dependent learning.
    */

                        NS_DURING
                            [thisType updateConnection:connection
                                    fromState:&layers[l][row][col]
                                    toState:&layers[position.z][position.y][position.x]
                                    dt:dt time:time];
                        NS_HANDLER
                            NSLog ([localException name]);
                            NSLog ([localException reason]);
                        NS_ENDHANDLER
                    }
                }
            }
        }
        //printf("%f\n",[self meanFiringRateForLayerAtIndex:l]);
    }
    [pool release];
    // synchronize with main thread
    [CLock lock];
    condition = [CLock condition];
    [CLock unlockWithCondition:++condition];
}


- (void) initializeModels
/*"
	Cycles through the all the types and messages them to initialize their
	models (See SIMType initModels).
"*/
{
    int k,l,uniqueSeed = [descriptionDictionary intForKey:SIMMasterRandomSeedKey];
        
    /* cycle through all the types and initialize all the models */
    for (l = 0; l < numLayers; l++) {
        for(k = 0; k < layerInfo[l].numTypes; k++){
            uniqueSeed ++;
            [layerInfo[l].types[k] initModelsWithNetwork:self randomSeed:uniqueSeed];
        }
    }
}

- (void) setInitialStates
/*"
	Cycles through all elements in the network and sets the initial values for each element
	using their associated SIMType object (See SIMType method setInitialState:).  A
	status notification is posted (SIMStatusUpdateNotification).
"*/
{
    int			row, col, l;

/* cycle through and send everything a setInitialState message */
    for (l = 0; l < numLayers; l++) {
        if(layerInfo[l].node != localNode)continue;
        for (row=0; row < layerInfo[l].numRows; row++){
            for (col=0; col < layerInfo[l].numColumns; col++){
                if (layers[l][row][col].type == SIM_UndefinedType)
                    continue;
                else [layers[l][row][col].type setInitialState:&layers[l][row][col]];
            }
        }
    }	
    [self postStatusNotificationWithDescription:(@"Set initial states for all network elements.") progress:0.0];
}

- (void) setRandomStates
/*"
    Cycles through all elements in the network and sets random values for each element
    using their associated SIMType object (See SIMType method setRandomState:).  A
    status notification is posted (SIMStatusUpdateNotification).
"*/
{
	int row, col, l;
	
	for (l = 0; l < numLayers; l++) {
            if(layerInfo[l].node != localNode)continue;
            for (row=0; row < layerInfo[l].numRows; row++){
                for (col=0; col < layerInfo[l].numColumns; col++){
                    SIMType *thisType;
                    if (layers[l][row][col].type == SIM_UndefinedType)
                            continue;
                    else thisType = layers[l][row][col].type;
                    [thisType setRandomState:&layers[l][row][col]];
                }
            }
	}	
    [self postStatusNotificationWithDescription:(@"Set random states for all network elements.") progress:0.0];
}

- (void) setNullStates
/*"
    Cycles through all elements in the network and sets null values for each element
    using their associated SIMType object (See SIMType method setNullState:).  A
    status notification is posted (SIMStatusUpdateNotification).
"*/
{
	int row, col, l;
	
    /* cycle through and send everything a setNullValuesForState message */
	for (l = 0; l < numLayers; l++) {
            if(layerInfo[l].node != localNode)continue;
            for (row=0; row < layerInfo[l].numRows; row++){
                for (col=0; col < layerInfo[l].numColumns; col++){
                    SIMType *thisType;
                    if (layers[l][row][col].type == SIM_UndefinedType)
                            continue;
                    else thisType = layers[l][row][col].type;
                    [thisType setNullState:&layers[l][row][col]];
                }
            }
	}	
    [self postStatusNotificationWithDescription:(@"Set null states for all network elements.") progress:0.0];
}

- (void) setup
/*"
	Reads various parameters (such as the time step) from the 
	description dictionary.  Initializes internal data structures used for updating the 
	network.  This must be called before the network is run.
"*/
{
	int	l;
	id	typeKey;
	SIMType *thisType;
	NSEnumerator *typeEnumerator;

        [self postStatusNotificationWithDescription:(@"Setting up internal network data structures.")
            progress:0.0];

	dt = [descriptionDictionary floatForKey: SIMTimeScaleKey];		      //
        numProcessors = [descriptionDictionary intForKey: SIMNumberOfProcessorsKey];  // should define an updateParameters method
	numLayers = [self countLayers];
    //COMMENT
        
        [self setupLog];
        
	if(networkUpdateNotification){[networkUpdateNotification release]; networkUpdateNotification = nil;}
	networkUpdateNotification = [[NSNotification notificationWithName:SIMNetworkDidUpdateNotification object:self] retain];

		
	if (layerInfo)
		{NSZoneFree ([self zone],layerInfo); layerInfo=(SIMLayer *)nil;}
	layerInfo = 
		(SIMLayer *) NSZoneMalloc ([self zone],numLayers*sizeof(SIMLayer));
		
	for (l=0; l<numLayers; l++) {
	    NSDictionary *thisLayer = [self layerDictionaryForIndex:l];
            NSDictionary *typesDict = [self typesDictionaryForIndex:l];
            layerInfo[l].name = [self keyForLayerAtIndex: l];
            layerInfo[l].node = [thisLayer intForKey:SIMNodeKey];
            layerInfo[l].numRows = [thisLayer intForKey: SIMNumRowsKey];
            layerInfo[l].numColumns = [thisLayer intForKey: SIMNumColumnsKey];
            layerInfo[l].numTypes = [typesDict count];
            layerInfo[l].types = NSZoneMalloc ([self zone], layerInfo[l].numTypes * sizeof(SIMType *));

            typeEnumerator = [typesDict keyEnumerator];
            while ((typeKey = [typeEnumerator nextObject])){
                thisType = [typesDict objectForKey: typeKey];
                layerInfo[l].types[[thisType assignedIndex]] = thisType;
            }
	}
                
        [self _initNodes];
        
        [self postStatusNotificationWithDescription:(@"Completed setup of internal network data structures.")
            progress:1.0];
}

- (void) setupLog
{
    logDictionary = [NSMutableDictionary dictionary];
    [self setObject:logDictionary forKey:@"LOG"];
}

- (void) setParameter: (NSString *) path value: (NSObject *) value
/*"
    Sets the parameter at path to value.  This method retrieves the object located
    at path and calls setObject:forKey: using the last component of the path as the
    key and value as the object.
"*/
{	
    NSString *paramName = [path lastSimulatorPathComponent];
    NSNotification *notification;
    NS_DURING
    [[undoManager prepareWithInvocationTarget:self]
        setParameter:path value:[self objectAtPath:path]];
    [undoManager setActionName:@"parameter change"];
    [[self objectAtPath: [path stringByDeletingLastSimulatorPathComponent]]
        setObject: value forKey: paramName];
    NS_HANDLER
    NSLog ([localException name]);
    NSLog ([localException reason]);
    NS_ENDHANDLER

    dt = [descriptionDictionary floatForKey: SIMTimeScaleKey]; // Should be moved
    numProcessors = [descriptionDictionary intForKey: SIMNumberOfProcessorsKey];

    notification = [NSNotification notificationWithName:SIMParameterDidChangeNotification object:self];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle: NSPostASAP
        coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
}

- objectAtPath: (NSString *) path
/*"
    Returns the object located at path in the network.
"*/
{  return [descriptionDictionary objectAtPath:path]; }

- (void) setObject: (NSObject *) obj atPath: (NSString *) path
/*"
    Sets the object located at path to obj.
"*/
{  [self setParameter:path value:obj];}


- (NSArray *) allKeys
/*"
    Returns all key entries in the description dictionary.
"*/
{ return [descriptionDictionary allKeys]; }

- (NSEnumerator *) keyEnumerator
/*"
    Returns an enumerator for all key entries in the description dictionary.
"*/
{
    return [[self allKeys] objectEnumerator];
}

- objectForKey: (NSString *)key
{ return [descriptionDictionary objectForKey:key]; }

- (void)setObject: obj forKey: (NSString *) key
{
    NSNotification *notification;
    NS_DURING
    [descriptionDictionary setObject: obj forKey: key];
    NS_HANDLER
    NSLog ([localException name]);
    NSLog ([localException reason]);
    NS_ENDHANDLER

    notification = [NSNotification notificationWithName:SIMParameterDidChangeNotification object:self];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle: NSPostASAP
        coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
}

- (NSMutableDictionary *) dictionary
{ return descriptionDictionary; }

- (NSMutableDictionary *) rootDictionary
{ return descriptionDictionary; }

- (NSMutableDictionary *) layerDictionary
{ return [descriptionDictionary objectForKey:SIMLayersKey]; }

- (NSMutableDictionary *) typesDictionaryForLayer: (int) layer
{
        id	myLayer;
        assert (layer <= [layerDictionary count]);
        myLayer = [layerDictionary objectForKey:
                        [self keyForLayerAtIndex: layer]];
        return [myLayer objectForKey:SIMTypesKey];
}

- (NSMutableDictionary *) typesDictionaryForLayerWithKey: (NSString *) key
{
        id	myLayer;
        myLayer = [layerDictionary objectForKey:key];
        return [myLayer objectForKey:SIMTypesKey];
}

- (float) time
{ return (float) time; }

- (void) setTime: (float) aTime
{ time = aTime; }

- (float) dt
{ return dt; }

- (void) setTimeStep: (float) aTime
{ dt = aTime; }

- (void) updateMilliseconds: (float) milliseconds
{ [self update: milliseconds / dt]; }

- (void) update: (int) steps
{
    int t;
    for (t = 0; t < steps; t++) {
        [self update];
    }
}

- (void)postStatusNotificationWithDescription:(NSString *)description progress:(float)progress
{
    [statusDict setObject:description forKey:SIMStatusDescriptionKey];
        [statusDict setObject:[NSDate date] forKey:SIMStatusDateKey];
    [statusDict setObject:[NSNumber numberWithFloat:time] forKey:SIMStatusTimeKey];
    [statusDict setObject:[NSNumber numberWithFloat:progress] forKey:SIMStatusProgressKey];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:SIMStatusUpdateNotification object:self userInfo:statusDict];
}

- (void)postErrorNotificationWithDescription:(NSString *)description
{
    [statusDict setObject:description forKey:SIMStatusDescriptionKey];
        [statusDict setObject:[NSDate date] forKey:SIMStatusDateKey];
    [statusDict setObject:[NSNumber numberWithFloat:time] forKey:SIMStatusTimeKey];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:SIMErrorUpdateNotification object:self userInfo:statusDict];
}

- (void)logEntry:(NSString *)entry
{
    [logDictionary setObject:entry forKey:[NSDate date]];
}

- (NSDictionary *)logDictionary
{
    return logDictionary;
}

- (NSUndoManager *)undoManager
{
    return undoManager;
}

- (NSString *) inspectorClassName { return @"SIMActivityInspector"; }


- (void) dealloc
{
	int	i, j, l;
	id	thisLayer;
	int	numColumns, numRows;
    
    if(mSIMWorkerThreads) {
        [self closeExistingWorkerThreads];
    }
	                
	for (l = 0; l < numLayers; l++) {
		thisLayer = [layerDictionary objectForKey:
			[self keyForLayerAtIndex: l]];
		numRows = [[thisLayer objectForKey:SIMNumRowsKey] intValue];
		numColumns = [[thisLayer objectForKey:SIMNumColumnsKey] intValue];
		for (i = 0; i < numRows; i++) {
			for (j = 0; j < numColumns; j++) {
				if (layers[l][i][j].type != SIM_UndefinedType){
					[layers[l][i][j].type deallocState: &layers[l][i][j]] ;
					[layers[l][i][j].connections release];
				}
			}
			NSZoneFree ([self zone],layers[l][i]);
		}
		NSZoneFree ([self zone],layers[l]);
	}	
	NSZoneFree ([self zone],layers);

        for (l = 0; l < numLayers; l++) {
            for (i = 0; i < layerInfo[l].numTypes; i++){
                //NSLog(@"Type retain count %d",[layerInfo[l].types[i] retainCount]);
                [layerInfo[l].types[i] release];
                //[layerInfo[l].types[i] release]; Where is this being retained again?
            }
            NSZoneFree([self zone],layerInfo[l].types);
        }
        NSZoneFree ([self zone],layerInfo);
        
        [agentClasses release];
        [agentDictionary release];
	[layerDictionary release];
	[descriptionDictionary release];
	[statusDict release];
        [undoManager release];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
    //Timedit FIXME 
    // Need to release worker threads!
	[super dealloc];
}

- initWithCoder:(NSCoder *)coder
{
    NSEnumerator *agentEnum;
    NSString *className;

    CLock = [[NSConditionLock alloc] initWithCondition:0];
    
    undoManager = [[NSUndoManager alloc] init];

    agentClasses = [[coder decodeObject] retain];

    agentEnum = [agentClasses objectEnumerator];
    while(className = [agentEnum nextObject]){
        [self classWithName:className ofType:AGENT_EXTENSION];
    }    
    
    descriptionDictionary = [[coder decodeObject] retain];
    layerDictionary = [descriptionDictionary objectForKey:SIMLayersKey];
    
    [self setup];
    [self _initLayers];
    [self initializeModels];
    
    [self unarchiveStatesWithCoder:coder];

    return self;
}

- (void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:agentClasses];
    [coder encodeObject:descriptionDictionary];

    [self archiveStatesWithCoder:coder];
}


- (void)unarchiveStatesWithCoder:(NSCoder *)coder
{
    int	i, j, l;

    [coder decodeValueOfObjCType:@encode(float) at:&time];

    for (l = 0; l < numLayers; l++) {
        if(layerInfo[l].node != localNode)continue;
        for (i = 0; i < layerInfo[l].numRows; i++) {
            for (j = 0; j < layerInfo[l].numColumns; j++) {
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                int index = -1;
                NS_DURING
                [coder decodeValueOfObjCType:@encode(int) at:&index];
                if(index < 0){layers[l][i][j].type = SIM_UndefinedType; continue;}
                else {
                    layers[l][i][j].type = layerInfo[l].types[index];
                    [layers[l][i][j].type unarchiveState: &layers[l][i][j] withCoder:coder];
                }
                NS_HANDLER
                    NSLog(@"ERROR: Couldn't decode state: (%d,%d,%d).",l,i,j);
                    NSLog ([localException name]);
                    NSLog ([localException reason]);
                NS_ENDHANDLER
                [pool release];
            }
        }
    }
}

- (void) archiveStatesWithCoder:(NSCoder *)coder
{
    int	i, j, l;
    
    [coder encodeValueOfObjCType:@encode(float) at:&time];
    
    for (l = 0; l < numLayers; l++) {
        if(layerInfo[l].node != localNode)continue;    
        for (i = 0; i < layerInfo[l].numRows; i++) {
            for (j = 0; j < layerInfo[l].numColumns; j++) {
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                NS_DURING
                if(layers[l][i][j].type == SIM_UndefinedType){
                    int index = -1;
                    [coder encodeValueOfObjCType:@encode(int) at:&index];
                    NSLog(@"Encoding undefined type object");
                }
                else {
                    int index = [layers[l][i][j].type assignedIndex];
                    [coder encodeValueOfObjCType:@encode(int) at:&index];
                    [layers[l][i][j].type archiveState: &layers[l][i][j] withCoder:coder];
                }
                NS_HANDLER
                    NSLog(@"ERROR: Couldn't encode state: (%d,%d,%d).",l,i,j);
                    NSLog ([localException name]);
                    NSLog ([localException reason]);
                NS_ENDHANDLER
                [pool release];
            }
        }
    }	
}

- (void)unarchiveActivityStatesWithCoder:(NSCoder *)coder
{
    int	i, j, l;

    [coder decodeValueOfObjCType:@encode(float) at:&time];

    for (l = 0; l < numLayers; l++) {
        if(layerInfo[l].node != localNode)continue;
        for (i = 0; i < layerInfo[l].numRows; i++) {
            for (j = 0; j < layerInfo[l].numColumns; j++) {
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                int index = -1;
                NS_DURING
                [coder decodeValueOfObjCType:@encode(int) at:&index];
                if(index < 0){layers[l][i][j].type = SIM_UndefinedType; continue;}
                else {
                    layers[l][i][j].type = layerInfo[l].types[index];
                    [layers[l][i][j].type unarchiveActivityState: &layers[l][i][j] withCoder:coder];
                }
                NS_HANDLER
                    NSLog(@"ERROR: Couldn't decode state: (%d,%d,%d).",l,i,j);
                    NSLog ([localException name]);
                    NSLog ([localException reason]);
                NS_ENDHANDLER
                [pool release];
            }
        }
    }
}

- (void) archiveActivityStatesWithCoder:(NSCoder *)coder
{
    int	i, j, l;
    
    [coder encodeValueOfObjCType:@encode(float) at:&time];
    
    for (l = 0; l < numLayers; l++) {
        if(layerInfo[l].node != localNode)continue;    
        for (i = 0; i < layerInfo[l].numRows; i++) {
            for (j = 0; j < layerInfo[l].numColumns; j++) {
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                NS_DURING
                if(layers[l][i][j].type == SIM_UndefinedType){
                    int index = -1;
                    [coder encodeValueOfObjCType:@encode(int) at:&index];
                    NSLog(@"Encoding undefined type object");
                }
                else {
                    int index = [layers[l][i][j].type assignedIndex];
                    [coder encodeValueOfObjCType:@encode(int) at:&index];
                    [layers[l][i][j].type archiveActivityState: &layers[l][i][j] withCoder:coder];
                }
                NS_HANDLER
                    NSLog(@"ERROR: Couldn't encode state: (%d,%d,%d).",l,i,j);
                    NSLog ([localException name]);
                    NSLog ([localException reason]);
                NS_ENDHANDLER
                [pool release];
            }
        }
    }	
}

- (NSString *)description
{
/*    NSString *desc;
    NSMutableDictionary *descDict = [descriptionDictionary mutableCopy];
    NSEnumerator *layerEnum = [[layerDictionary allKeys] objectEnumerator];
    NSString *key;
    while(key = [layerEnum nextObject]){
        NSMutableDictionary *layerDict = [[layerDictionary objectForKey:key] mutableCopy];
        [layerDict removeObjectForKey:SIMParameterRangesKey];
        [descDict setObject:layerDict forKey:key];
    }
    [descDict removeObjectForKey:SIMParameterRangesKey];
    desc = [[descDict description] retain];
    [descDict release];*/
    //NSLog([descriptionDictionary description]);
    return [descriptionDictionary description];
}

@end
