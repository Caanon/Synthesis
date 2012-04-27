/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisCore/SIMNetworkStatistics.h>
#import <SynthesisCore/SIMCommands.h>
#import <SynthesisCore/SIMAgent.h>
#import <SynthesisCore/SIMPatternMatch.h>
#import <SynthesisCore/version.h>

/*"
    This category implements all commands available to the SIMCommandServer interpreter.  Each of these commands can be issued via a
    call to the SIMCommandServer or via the commandline through SIMCommandClient.
"*/

@implementation SIMCommandServer (SIMCommands)

- valueForPath:(NSArray *)argumentArray
{
	return [[network valueForKeyPath:[argumentArray objectAtIndex:1]] description];
}

- shellCommand:(NSArray *)argumentArray
{
    if([argumentArray count] == 2) {
        system([[argumentArray objectAtIndex:1] UTF8String]);
    }
    return @"";
}

- ls:(NSArray *)argumentArray
{
    id currentObject = [self currentObject];
    NSMutableString *listing = [[NSMutableString string] retain];
    NSEnumerator *enumerator = [[currentObject allKeys] objectEnumerator];
    NSString *pattern = nil;
    id key;

    if([argumentArray count] == 2) pattern = [argumentArray objectAtIndex:1];

    while(key = [enumerator nextObject]){
        NSString *keyDesc = [key description];
        id myObject = [currentObject objectForKey:key];
        if(/*[myObject isKindOfClass:[NSArray class]] || */
            [myObject isKindOfClass:[NSDictionary class]] ||
            [myObject conformsToProtocol:@protocol(SIMDictionaryAccess)]){
            if(!pattern || !SIMPatternMatch([pattern UTF8String],[keyDesc UTF8String],FNM_PATHNAME))
                [listing appendString:[NSString stringWithFormat:@"%@%@\n",keyDesc,SIM_PathSeparator]];
        }
        else {
            NSString *objDesc = [[currentObject objectForKey:key] description];
            if(!pattern || !SIMPatternMatch([pattern UTF8String],[keyDesc UTF8String],FNM_PATHNAME))
                [listing appendString:[NSString stringWithFormat:@"%@ = %@;\n",keyDesc,objDesc]];
        }
    }

    return [listing autorelease];
}

- pwd:(NSArray *)argumentArray
{
    id answer;
    answer = [self currentPath];

    return answer;
}

- cd:(NSArray *)argumentArray
{
    if([[argumentArray objectAtIndex:1] hasPrefix:SIM_PathSeparator]){
        [self setCurrentPath:[argumentArray objectAtIndex:1]];
    }
    else
    if([[argumentArray objectAtIndex:1] hasPrefix:@".."]){
        [self setCurrentPath:[[self currentPath] stringByDeletingLastSimulatorPathComponent]];
    }
    else [self setCurrentPath:[[self currentPath] stringByAppendingSimulatorPathComponent:[argumentArray objectAtIndex:1]]];

    return nil;
}

- set:(NSArray *)argumentArray
{
    NSMutableString *listing = [[NSMutableString string] retain];
    NSArray *paths;
    NSEnumerator *enumerator;
    NSString *path = nil,*match = nil,*value = nil, *newValue = nil;

    if([argumentArray count] <= 2)return @"USAGE: set <path|wildcard> <|match value|> value";

    if([argumentArray count] == 4){
        match = [argumentArray objectAtIndex:2];
        newValue = [argumentArray objectAtIndex:3];
    }
    else newValue = [argumentArray objectAtIndex:2];
    
    if ([newValue hasPrefix:@"("] || [newValue hasPrefix:@"{"]){
        NS_DURING
        value = [newValue propertyList];
        NS_HANDLER
        NSLog ([localException name]);
        NSLog ([localException reason]);
        NS_ENDHANDLER
    }
    else value = newValue;
        
    paths = [[self matchPathPattern:[argumentArray objectAtIndex:1]] retain];

    enumerator = [paths objectEnumerator];

    while(path = [enumerator nextObject]){
        id myObject;
        NSString *objDesc;

        myObject = [network objectAtPath:path];
        objDesc = [myObject description];

        if(!match || [match isEqual:objDesc]){
                
            [network setParameter:path value:value];

            myObject = [network objectAtPath:path];
            objDesc = [myObject description];

            if(/*[myObject isKindOfClass:[NSArray class]] ||*/
                [myObject isKindOfClass:[NSDictionary class]] ||
                [myObject conformsToProtocol:@protocol(SIMDictionaryAccess)]){
                [listing appendString:[NSString stringWithFormat:@"%@%@\n",path,SIM_PathSeparator]];
            }
            else {
                [listing appendString:[NSString stringWithFormat:@"%@ = %@;\n",path,objDesc]];
            }
        }
    }
	
	[paths release];

    return [listing autorelease];
}

- undo:(NSArray *)argumentArray
{
    NSUndoManager *undoManager = [network undoManager];
    NSString *undoAction = [undoManager undoActionName];
    [undoManager undo];
    return [NSString stringWithFormat:@"Undid %@.",undoAction];
}

- redo:(NSArray *)argumentArray
{
    NSUndoManager *undoManager = [network undoManager];
    NSString *redoAction = [undoManager redoActionName];
    [undoManager redo];
    return [NSString stringWithFormat:@"Redid %@.",redoAction];
}

/*
- setGradual:(NSArray *)argumentArray
{
    double value,startValue,endValue,interval;
    double dt = (double)[network dt];
    for(value = startValue; value <= endValue; endValue-startValue/interval*dt;
    [network setObject:[argumentArray objectAtIndex:2] atPath:[currentPath stringByAppendingSimulatorPathComponent:[argumentArray objectAtIndex:1]]];
    return nil;
}
*/

- get:(NSArray *)argumentArray
{
    NSMutableArray *results = [[NSMutableArray array] retain];
    NSArray *paths;
    NSEnumerator *enumerator;
    NSString *path;

    if([argumentArray count] <= 1)return @"USAGE: get <path|wildcard> value";

    paths = [[self matchPathPattern:[argumentArray objectAtIndex:1]] retain];

    enumerator = [paths objectEnumerator];

    while(path = [enumerator nextObject]){
        [results addObject:[network objectAtPath:path]];
    }
    
	[paths release];
	
    return [results autorelease];
}

- find:(NSArray *)argumentArray
{
    NSArray *results;
    NSMutableString *listing = [[NSMutableString string] retain];
    NSEnumerator *resultsEnum;
    NSString *path,*match = nil;

    if([argumentArray count] <= 1)return nil;

    if([argumentArray count] == 3)match = [argumentArray objectAtIndex:2];
    results = [[self matchPathPattern:[argumentArray objectAtIndex:1]] retain];

    resultsEnum = [results objectEnumerator];

    while(path = [resultsEnum nextObject]){
        id myObject = [network objectAtPath:path];
        if(/*[myObject isKindOfClass:[NSArray class]] ||*/
            [myObject isKindOfClass:[NSDictionary class]] ||
            [myObject conformsToProtocol:@protocol(SIMDictionaryAccess)]){
            [listing appendString:[NSString stringWithFormat:@"%@%@\n",path,SIM_PathSeparator]];
        }
        else {
            NSString *objDesc = [myObject description];
            if(!match || [match isEqual:objDesc])
                [listing appendString:[NSString stringWithFormat:@"%@ = %@;\n",path,objDesc]];
        }
    }

	[results release];
	
    return [listing autorelease];
}

- (NSArray *)matchPathPattern:(NSString *)pattern
{
    NSMutableArray *allPaths = [[NSMutableArray array] retain],*foundPaths = [[NSMutableArray array] retain];
    NSEnumerator *enumerator;
    NSString *path;

    [self _enumeratePaths:[network rootDictionary] path:nil paths:allPaths];

    enumerator = [allPaths objectEnumerator];

    while(path = [enumerator nextObject]){
        if(!SIMPatternMatch([pattern UTF8String],[path UTF8String],NULL)){
            [foundPaths addObject:path];
        }
    }
	
	[allPaths release];

    return [foundPaths autorelease];
}

- (void)_enumeratePaths:(NSDictionary *)dict path:(NSString *)rootPath paths:(NSMutableArray *)paths
{

	[dict retain];
	[paths retain];
	[rootPath retain];

    if(!rootPath)rootPath = SIM_PathSeparator;

    id key;
    NSEnumerator *enumerator = [dict keyEnumerator];

    while(key = [enumerator nextObject]){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        id value = [dict objectForKey:key];
        if([key isEqual:SIMParameterRangesKey])continue;
        if([value isKindOfClass:[NSDictionary class]] || [value conformsToProtocol:@protocol(SIMDictionaryAccess)]){
            [self _enumeratePaths:value path:[rootPath stringByAppendingSimulatorPathComponent:key] paths:paths];
        }
        else {
            NSString *newPath = [rootPath stringByAppendingSimulatorPathComponent:key];
            if(newPath)[paths addObject:newPath];
        }
		[pool release];
    }
	[rootPath release];
	[paths release];
	[dict release];
}

- startAgent:(NSArray *)argumentArray
{
    NSString *agentKey;
    NSDictionary *agentDictionary = nil;

    agentDictionary = [[network rootDictionary] objectForKey:SIMAgentsKey];

    if([argumentArray count] <= 1)return @"USAGE: startAgent <agent name>";

    agentKey = [argumentArray objectAtIndex:1];

    if(agentDictionary) {
        SIMAgent *theAgent = [agentDictionary objectForKey:agentKey];
        if(theAgent){
            [theAgent setNetwork:[self network]];
            //[theAgent registerWithServer:serverName onHost:[[NSHost currentHost] name]];
            [theAgent startAgent];
            return [NSString stringWithFormat:@"Agent: %@ started.",agentKey];
        }
    }

    return nil;
}

- stopAgent:(NSArray *)argumentArray
{
    NSString *agentKey;
    NSDictionary *agentDictionary = nil;

    agentDictionary = [[network rootDictionary] objectForKey:SIMAgentsKey];

    if([argumentArray count] <= 1)return @"USAGE: stopAgent <agent name>";

    agentKey = [argumentArray objectAtIndex:1];

    if(agentDictionary){
        SIMAgent *theAgent = [agentDictionary objectForKey:agentKey];
        if(theAgent){
            [theAgent stopAgent];
            return [NSString stringWithFormat:@"Agent: %@ stopped.",agentKey];
        }
    }

    return nil;
}

- startAllAgents:(NSArray *)argumentArray
{
    int count = 0;
    NSDictionary *agentDictionary = nil;

    agentDictionary = [[network rootDictionary] objectForKey:SIMAgentsKey];

    if(agentDictionary) {
        NSEnumerator *agentEnum = [agentDictionary keyEnumerator];
        NSString *agentKey;

        while(agentKey = [agentEnum nextObject]){
            SIMAgent *theAgent = [agentDictionary objectForKey:agentKey];
            if(theAgent){
                [theAgent setNetwork:[self network]];
                //[theAgent registerWithServer:serverName onHost:[[NSHost currentHost] name]];
                [theAgent startAgent];
                count++;
            }
        }
    }

    return [NSString stringWithFormat:@"%d Agent(s) started.",count];
}

- stopAllAgents:(NSArray *)argumentArray
{
    int count = 0;
    NSDictionary *agentDictionary = nil;

    agentDictionary = [[network rootDictionary] objectForKey:SIMAgentsKey];

    if(agentDictionary){
        NSEnumerator *agentEnum = [agentDictionary keyEnumerator];
        NSString *agentKey;

        while(agentKey = [agentEnum nextObject]){
            SIMAgent *theAgent = [agentDictionary objectForKey:agentKey];
            if(theAgent){
                [theAgent stopAgent];
                count++;
            }
        }
    }

    return [NSString stringWithFormat:@"%d Agent(s) stopped.",count];
}

- addAgents:(NSArray *)argumentArray
{
	if([argumentArray count] == 2){
		[network addAgentsWithContentsOfURL:[NSURL URLWithString:[argumentArray objectAtIndex:1]]];
		return nil;
	}
	else return @"USAGE: addAgents <URL>";
}

- removeAgent:(NSArray *)argumentArray
{
	if([argumentArray count] == 2){
		[self stopAgent:argumentArray];
		[network removeAgentForKey:[argumentArray objectAtIndex:1]];
		return nil;
	}
	else return @"USAGE: removeAgent <agent name>";
}

- removeAllAgents:(NSArray *)argumentArray
{
	if([argumentArray count] == 1){
		[self stopAllAgents:argumentArray];
		[network removeAllAgents];
		return nil;
	}
	else return @"USAGE: removeAgent <agent name>";

}

- addIntrinsicChannels:(NSArray *)argumentArray
{
    if([argumentArray count] == 4){
		NSString *layerName = [argumentArray objectAtIndex:2];
		NSString *typeName = [argumentArray objectAtIndex:3];
		NSMutableDictionary *modelDict = [[NSMutableDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:[argumentArray objectAtIndex:1]]] retain];
		if(!modelDict){
			return [NSString stringWithFormat:@"Could not load models from URL: %@",[argumentArray objectAtIndex:1]];
		}
		NSEnumerator *modelEnum = [modelDict keyEnumerator];
		NSString *modelKey;
		while(modelKey = [modelEnum nextObject]){
			NSDictionary *modelDescription = [modelDict objectForKey:modelKey];
			[network addIntrinsicChannel:modelKey withDescription:modelDescription toCellType:typeName inLayer:layerName];
		}
		return [NSString stringWithFormat:@"Added %d models to cell type %@ in layer %@",[modelDict count],typeName,layerName];
	}
    else return @"USAGE: addIntrinsicChannels <URL> <Layer> <CellType>";
}

- addInputChannels:(NSArray *)argumentArray
{
    if([argumentArray count] == 4){
		NSString *typeName = [argumentArray objectAtIndex:2];
		NSString *layerName = [argumentArray objectAtIndex:3];
		NSMutableDictionary *modelDict = [[NSMutableDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:[argumentArray objectAtIndex:1]]] retain];
		if(!modelDict){
			return [NSString stringWithFormat:@"Could not load models from URL: %@",[argumentArray objectAtIndex:1]];
		}
		NSEnumerator *modelEnum = [modelDict keyEnumerator];
		NSString *modelKey;
		while(modelKey = [modelEnum nextObject]){
			NSDictionary *modelDescription = [modelDict objectForKey:modelKey];
			[network addInputChannel:modelKey withDescription:modelDescription toCellType:typeName inLayer:layerName];
		}
		return [NSString stringWithFormat:@"Added %d models to cell type %@ in layer %@",[modelDict count],typeName,layerName];
	}
    else return @"USAGE: addInputChannels <URL> <CellType> <Layer>";
}

- addCellCompartments:(NSArray *)argumentArray
{
    if([argumentArray count] == 4){
		NSString *typeName = [argumentArray objectAtIndex:2];
		NSString *layerName = [argumentArray objectAtIndex:3];
		NSMutableDictionary *modelDict = [[NSMutableDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:[argumentArray objectAtIndex:1]]] retain];
		if(!modelDict){
			return [NSString stringWithFormat:@"Could not load models from URL: %@",[argumentArray objectAtIndex:1]];
		}
		NSEnumerator *modelEnum = [modelDict keyEnumerator];
		NSString *modelKey;
		while(modelKey = [modelEnum nextObject]){
			NSDictionary *modelDescription = [modelDict objectForKey:modelKey];
			[network addCellCompartment:modelKey withDescription:modelDescription toCellType:typeName inLayer:layerName];
		}
		return [NSString stringWithFormat:@"Added %d models to cell type %@ in layer %@",[modelDict count],typeName,layerName];
	}
    else return @"USAGE: addCellCompartments <URL> <CellType> <Layer>";
}

- newNetwork:(NSArray *)argumentArray
{
    SIMNetwork *newNetwork = [[SIMNetwork alloc] init];
 
    [[NSNotificationCenter defaultCenter]
	postNotificationName:SIMNetworkNotAvailableNotification object:network];
       
    [self stopAllAgents:nil];
    [network release];
    network = newNetwork;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:SIMNetworkIsAvailableNotification object:network];
    
    return @"Created new empty network.";
}

- loadActivityState:(NSArray *)argumentArray
{
    NSString *returnString;
    NSUnarchiver *unarchiver;
    NSData *data;
    
    if([argumentArray count] == 2){
        NSString *path = [[argumentArray objectAtIndex:1] stringByStandardizingPath];

        //[self stop:nil];

        //[[NSNotificationCenter defaultCenter]
        //    postNotificationName:SIMNetworkNotAvailableNotification object:network];

        data = [NSData dataWithContentsOfFile:path];
        //data = [NSData dataWithContentsOfMappedFile:path];

        unarchiver = [[NSUnarchiver alloc] initForReadingWithData:data];
        
        if(unarchiver){
            [network unarchiveActivityStatesWithCoder:unarchiver];
            returnString = [NSString stringWithFormat:@"Network activity state read from: %@",path];
        }
        else returnString = [NSString stringWithFormat:@"Couldn't read network activity state from: %@",path];
        
        [unarchiver release];

        //[[NSNotificationCenter defaultCenter]
        //    postNotificationName:SIMNetworkIsAvailableNotification object:network];
        return returnString;
    }

    return nil;
}

- saveActivityState:(NSArray *)argumentArray
{
    NSString *returnString;
    NSArchiver *archiver;
    NSMutableData *data;
    
    if([argumentArray count] == 2){
        BOOL isRunning = running;
        NSString *path = [[argumentArray objectAtIndex:1] stringByStandardizingPath];
        if(isRunning)[self stop:nil];
        
        data = [NSMutableData data];

        archiver = [[NSArchiver alloc] initForWritingWithMutableData:data];

        [network archiveActivityStatesWithCoder:archiver];

        if([data length]){
            if(isRunning)[self continue:nil];
            if([data writeToFile:path atomically:YES])
                returnString = [NSString stringWithFormat:@"State saved to: %@",path];
            else returnString = [NSString stringWithFormat:@"Couldn't save network state to: %@",path];
        }
        else returnString = @"Problem archiving activity state information.";
        [archiver release];
        return returnString;
    }
    return nil;
}

- loadState:(NSArray *)argumentArray
{
    SIMNetwork *newNetwork;
    NSString *returnString;
    if([argumentArray count] == 2){
        NSString *path = [[argumentArray objectAtIndex:1] stringByStandardizingPath];

        [self stop:nil];

        [[NSNotificationCenter defaultCenter]
            postNotificationName:SIMNetworkNotAvailableNotification object:network];

        newNetwork = [[NSUnarchiver unarchiveObjectWithFile:path] retain];

        if(newNetwork){
            if(network){[self stopAllAgents:nil];[network release];}
            network=newNetwork;
            [self cd:[NSArray arrayWithObjects:@"cd",SIM_PathSeparator,nil]];
            returnString = [NSString stringWithFormat:@"Network state read from: %@",path];
        }
        else returnString = [NSString stringWithFormat:@"Couldn't read network state from: %@",path];
        [[NSNotificationCenter defaultCenter]
            postNotificationName:SIMNetworkIsAvailableNotification object:network];
        return returnString;
    }

    return nil;
}

- saveState:(NSArray *)argumentArray
{
    if([argumentArray count] == 2){
        BOOL isRunning = running;
        BOOL success;
        NSString *path = [[argumentArray objectAtIndex:1] stringByStandardizingPath];
        if(isRunning)[self stop:nil];
        success = [NSArchiver archiveRootObject:network toFile:path];

        if(success){
            if(isRunning)[self continue:nil];
            return [NSString stringWithFormat:@"State saved to: %@",path];
        }
        else return [NSString stringWithFormat:@"Couldn't save network state to: %@",path];
    }
    return nil;
}

- loadNetwork:(NSArray *)argumentArray
/*"
        Loads and initializes a new SIMNetwork object with the description dict.
"*/
{
    SIMNetwork *newNetwork;
    NSString *returnString;
    if([argumentArray count] == 2){
        NSString *networkName = [[argumentArray objectAtIndex:1] stringByStandardizingPath];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:networkName];

        [self stop:nil];

        [[NSNotificationCenter defaultCenter]
            postNotificationName:SIMNetworkNotAvailableNotification object:network];

        if(!dict)return [NSString stringWithFormat:@"Invalid network description (Possibly corrupt): %@.",networkName];
        else newNetwork = [[SIMNetwork alloc] initWithDescription:dict node:localNode];
        if(newNetwork){
            if(network){[self stopAllAgents:nil];[network release];}
            network=newNetwork;
            [network initializeNetwork];
            [self cd:[NSArray arrayWithObjects:@"cd",SIM_PathSeparator,nil]];
            returnString = [NSString stringWithFormat:@"Loaded network from file: %@",networkName];
        }
        else returnString = [NSString stringWithFormat:@"Could not load network from file: %@",networkName];
        [[NSNotificationCenter defaultCenter]
            postNotificationName:SIMNetworkIsAvailableNotification object:network];
        return returnString;
    }
    return nil;
}

- saveNetwork:(NSArray *)argumentArray
{
    if([argumentArray count] == 2){
        NSString *path = [[argumentArray objectAtIndex:1] stringByStandardizingPath];

        NSString *description;
        
        description = [network description];

        if([description writeToFile:path atomically:YES]){
            return [NSString stringWithFormat:@"Network description saved to: %@",path];
        }
        else return [NSString stringWithFormat:@"Couldn't save network description to: %@",path];
    }
    return nil;
}

- initialize:(NSArray *)argumentArray
{
    [self stop:nil];
    [network initializeNetwork];
    [network setTime:0.0];

    return nil;
}

- initConnections:(NSArray *)argumentArray
{
    [self stop:nil];
    [network initConnections];
    return nil;
}

- setInitialState:(NSArray *)argumentArray
{
    //[network initModels];
    [network setInitialStates];
    return nil;
}

- setRandomState:(NSArray *)argumentArray
{
    [network setRandomStates];

    return nil;
}

- setNullState:(NSArray *)argumentArray
{
    [network setNullStates];

    return nil;
}

- setTime:(NSArray *)argumentArray
{
    if([argumentArray count] == 2){
        [network setTime:[[argumentArray objectAtIndex:1] floatValue]];

        return nil;
    }
    else return @"USAGE: setTime <time>";
}

- time:(NSArray *)argumentArray
{
    return [NSNumber numberWithFloat:[network time]];
}

- setUpdateInterval:(NSArray *)argumentArray
{
    if([argumentArray count] == 2){
        updateInterval = [[argumentArray objectAtIndex:1] floatValue];
        return nil;
    }
    else return @"USAGE: setUpdateInterval <interval>";
}

- updateInterval:(NSArray *)argumentArray
{
    return [NSNumber numberWithFloat:updateInterval];
}

- reset:(NSArray *)argumentArray
{
    //[self stop:nil];
    [network resetNetwork];

    return nil;
}

- run:(NSArray *)argumentArray
{
    if(running) return [NSString stringWithFormat:@"Running until t = %0.3f",stopTime];

    if([argumentArray count] == 2)stopTime = [network time] + [[argumentArray objectAtIndex:1] intValue];
    else stopTime = FLT_MAX;

    if(!running){
        runTimer = [NSTimer timerWithTimeInterval:0.0
            target:self
            selector:@selector(update)
            userInfo:nil
            repeats:YES];
        running = YES;
        if(startDate)[startDate release];
        startDate = [[NSDate date] retain];
        [[NSRunLoop currentRunLoop] addTimer:runTimer forMode: NSDefaultRunLoopMode];
    }
    return [NSString stringWithFormat:@"Running. t = %0.3f",[network time]];
}

- runUntil:(NSArray *)argumentArray
{
    stopTime = [[argumentArray objectAtIndex:1] floatValue];

    if(!running){
        runTimer = [NSTimer timerWithTimeInterval:0.0
            target:self
            selector:@selector(update)
            userInfo:nil
            repeats:YES];
        running = YES;
        if(startDate){[startDate release];startDate = nil;}
        startDate = [[NSDate date] retain];
        [[NSRunLoop currentRunLoop] addTimer:runTimer forMode: NSDefaultRunLoopMode];
    }
    return [NSString stringWithFormat:@"Running until t = %0.3f",stopTime];
}

- update:(NSArray *)argumentArray
/*" When typed with no arguments this updates the network by the smallest time step (dt).  Otherwise this command
updates the network for the duration (in ms) as given by the argument.
"*/
{
    int i,updates;
    float dt = [network dt];

    if([argumentArray count] == 2)updates = (int)rintf([[argumentArray objectAtIndex:1] floatValue]/dt);
    else updates = 1;

    running = YES;

    for(i = 0;i < updates; i++){
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        if(!running)break;
        [network update];
        [pool release];
    }

    running = NO;

    return [NSString stringWithFormat:@"Updated %d times. t = %0.3f",updates,[network time]];
}

- updateUntil:(NSArray *)argumentArray
/*" 
    Updates the network until the current time = the argument (in ms).
"*/
{
    int updates = 0;
    float t = [[argumentArray objectAtIndex:1] floatValue];

    running = YES;

    while(running && ([network time] < t)){
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [network update];
        updates++;

        [pool release];
    }

    running = NO;

    return [NSString stringWithFormat:@"Updated %d times. t = %0.3f",updates,[network time]];
}

- stop:(NSArray *)argumentArray
/*"
    If the network is running it stops the network.
"*/
{
    if(running){
        [runTimer invalidate];
        running = NO;
        
        //TimEdit this could crap out, don't know how SIMCommands and SIMNetwork interact
        [network closeExistingWorkerThreads];

        return [NSString stringWithFormat:@"Stopped. t = %0.3f",[network time]];
    }
    running = NO;
    return nil;
}

- continue:(NSArray *)argumentArray
/*"
    Continues a simulation which has been stopped.
"*/
{
    if(!running){
        runTimer = [NSTimer timerWithTimeInterval:0.0
            target:self
            selector:@selector(update)
            userInfo:nil
            repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:runTimer forMode: NSDefaultRunLoopMode];
        running = YES;

        return [NSString stringWithFormat:@"Continuing. t = %0.3f",[network time]];
    }
    else return nil;
}


- terminate:(NSArray *)argumentArray
/*"
    Instructs the server to terminate its execution.
"*/
{
    NSTimer *terminateTimer = [NSTimer timerWithTimeInterval:0.1
        target:self
        selector:@selector(terminate)
        userInfo:nil
        repeats:NO];

    [self stop:nil];

    [[NSRunLoop currentRunLoop] addTimer:terminateTimer forMode: NSDefaultRunLoopMode];
    return nil;
}

- startDate:(NSArray *)argumentArray
/*"
    Returns the starting time and date of the current simulation.
"*/
{
    if(startDate)
        return startDate;
    else return @"Not running";
}

- date:(NSArray *)argumentArray
/*"
    Returns the current date.
"*/
{
    return [NSDate date];
}

- byteOrder:(NSArray *)argumentArray
/*"
    Returns the byte order of the host on which the server is running.
"*/
{
    if([network hostByteOrder] == NS_BigEndian)return @"BigEndian";
    else if([network hostByteOrder] == NS_LittleEndian)return @"LittleEndian";
    else return @"UnknownByteOrder";
}

- serverName:(NSArray *)argumentArray
/*"
    Returns the name of the currently connected server.
"*/
{
    return serverName;
}

- scaleConnections:(NSArray *)argumentArray
/*" 
    Causes the connections between two types of cells to be scaled by a value.
    USAGE: scaleConnections <fromType> <toType> <byValue>
"*/
{
    int count;
	int narg = [argumentArray count];
    if(narg < 4)return @"USAGE: scaleConnections <fromType> <toType> <byValue> |fractionOfCells| |fractionOfConnections|";
    else{
        NSString *fromType = [argumentArray objectAtIndex:1];
        NSString *toType = [argumentArray objectAtIndex:2];
        float byValue = [[argumentArray objectAtIndex:3] floatValue];
		float fracCells = 1.0;
		float fracConnects = 1.0;
		if(narg >= 5) fracCells = [[argumentArray objectAtIndex:4] floatValue];
		if(narg >= 6) fracConnects = [[argumentArray objectAtIndex:5] floatValue];

        count = [network scaleStrengthOfConnectionsFromType:fromType toType:toType fractionOfCells:fracCells 
					byValue:byValue fractionOfConnections:fracConnects];
    }
    return [NSString stringWithFormat:@"%d connections changed.",count];
}

- thresholdConnections:(NSArray *)argumentArray
/*" 
    Causes the connections between two types of cells to be scaled by a value.
    USAGE: scaleConnections <fromType> <toType> <byValue>
"*/
{
    int count;
	int narg = [argumentArray count];
    if(narg < 4)return @"USAGE: thresholdConnections <fromType> <toType> <byValue> |fractionOfCells| |fractionOfConnections|";
    else{
        NSString *fromType = [argumentArray objectAtIndex:1];
        NSString *toType = [argumentArray objectAtIndex:2];
        float byValue = [[argumentArray objectAtIndex:3] floatValue];
		float fracCells = 1.0;
		float fracConnects = 1.0;
		if(narg >= 5) fracCells = [[argumentArray objectAtIndex:4] floatValue];
		if(narg >= 6) fracConnects = [[argumentArray objectAtIndex:5] floatValue];

        count = [network thresholdStrengthOfConnectionsFromType:fromType toType:toType fractionOfCells:fracCells 
					atValue:byValue fractionOfConnections:fracConnects];
    }
    return [NSString stringWithFormat:@"%d connections changed.",count];
}


- setConnections:(NSArray *)argumentArray
/*" 
    Causes the connections between two types of cells to be set to a value.
    USAGE: setConnections <fromType> <toType> <toValue>
"*/
{
    int count;
	int narg = [argumentArray count];
    if(narg < 4)return @"USAGE: setConnections <fromType> <toType> <toValue>  |fractionOfCells| |fractionOfConnections|";
    else{
        NSString *fromType = [argumentArray objectAtIndex:1];
        NSString *toType = [argumentArray objectAtIndex:2];
        float toValue = [[argumentArray objectAtIndex:3] floatValue];
		float fracCells = 1.0;
		float fracConnects = 1.0;
		if(narg >= 5) fracCells = [[argumentArray objectAtIndex:4] floatValue];
		if(narg >= 6) fracConnects = [[argumentArray objectAtIndex:5] floatValue];
		
        count = [network setStrengthOfConnectionsFromType:fromType toType:toType fractionOfCells:fracCells
					toValue:toValue fractionOfConnections:fracConnects];
    }
    return [NSString stringWithFormat:@"%d connections changed.",count];
}

- modifyConnections:(NSArray *)argumentArray
/*" 
    Adds a value to the connections between two types of cells.
    USAGE: modifyConnections <fromType> <toType> <byValue>
"*/
{
    int count;
	int narg = [argumentArray count];
    if(narg < 4)return @"USAGE: modifyConnections <fromType> <toType> <byValue> |fractionOfCells| |fractionOfConnections|";
    else{
        NSString *fromType = [argumentArray objectAtIndex:1];
        NSString *toType = [argumentArray objectAtIndex:2];
        float byValue = [[argumentArray objectAtIndex:3] floatValue];
		float fracCells = 1.0;
		float fracConnects = 1.0;
		if(narg >= 5) fracCells = [[argumentArray objectAtIndex:4] floatValue];
		if(narg >= 6) fracConnects = [[argumentArray objectAtIndex:5] floatValue];
		
        count = [network modifyStrengthOfConnectionsFromType:fromType toType:toType fractionOfCells:fracCells 
					byValue:byValue fractionOfConnections:fracConnects];
    }
    return [NSString stringWithFormat:@"%d connections changed.",count];
}

- listConnectionsForCell:(NSArray *)argumentArray
{
    SIMPosition aCell;

    if([argumentArray count] != 4)return @"USAGE: listConnectionsForCell <x> <y> <z>";
    else {
        aCell.x = [[argumentArray objectAtIndex:1] intValue];
        aCell.y = [[argumentArray objectAtIndex:2] intValue];
        aCell.z = [[argumentArray objectAtIndex:3] intValue];
        [SIMConnections logConnections:[network connectionsForCell:aCell]];
    }

    return nil;
}

- totalWeightOfInputsForCell:(NSArray *)argumentArray
{
    SIMPosition aCell;

    if([argumentArray count] != 4)return @"USAGE: totalWeightOfInputsForCell <row> <col> <layer>";
    else {
        aCell.y = [[argumentArray objectAtIndex:1] intValue];
        aCell.x = [[argumentArray objectAtIndex:2] intValue];
        aCell.z = [[argumentArray objectAtIndex:3] intValue];
        return [NSString stringWithFormat:@"%f",[network totalWeightOfInputsForCell:aCell]];
    }

    return nil;
}

- totalNumberOfInputsForCell:(NSArray *)argumentArray
{
    SIMPosition aCell;

    if([argumentArray count] != 4)return @"USAGE: totalNumberOfInputsForCell <row> <col> <layer>";
    else {
        aCell.y = [[argumentArray objectAtIndex:1] intValue];
        aCell.x = [[argumentArray objectAtIndex:2] intValue];
        aCell.z = [[argumentArray objectAtIndex:3] intValue];
        return [NSString stringWithFormat:@"%f",[network totalNumberOfInputsForCell:aCell]];
    }

    return nil;
}

- totalLatencyOfInputsForCell:(NSArray *)argumentArray
{
    SIMPosition aCell;

    if([argumentArray count] != 4)return @"USAGE: totalLatencyOfInputsForCell <row> <col> <layer>";
    else {
        aCell.y = [[argumentArray objectAtIndex:1] intValue];
        aCell.x = [[argumentArray objectAtIndex:2] intValue];
        aCell.z = [[argumentArray objectAtIndex:3] intValue];
        return [NSString stringWithFormat:@"%f",[network totalLatencyOfInputsForCell:aCell]];
    }

    return nil;
}

- totalNumberOfInputs:(NSArray *)argumentArray
{
    float avgInput;
    if([argumentArray count] < 2)return @"USAGE: totalNumberOfInputs <type> |<fromType>|";

    if([argumentArray count] == 2)avgInput = [network totalNumberOfInputsForType:[argumentArray objectAtIndex:1] fromType:@"*"];
    else avgInput = [network totalNumberOfInputsForType:[argumentArray objectAtIndex:1] fromType:[argumentArray objectAtIndex:2]];

    return [NSString stringWithFormat:@"%g",avgInput];
}

- totalWeightOfInputs:(NSArray *)argumentArray
{
    float avgInput;
    if([argumentArray count] < 2)return @"USAGE: totalWeightOfInputs <type> |<fromType>|";

    if([argumentArray count] == 2)avgInput = [network totalWeightOfInputsForType:[argumentArray objectAtIndex:1] fromType:@"*"];
    else avgInput = [network totalWeightOfInputsForType:[argumentArray objectAtIndex:1] fromType:[argumentArray objectAtIndex:2]];

    return [NSString stringWithFormat:@"%g",avgInput];
}

- totalLatencyOfInputs:(NSArray *)argumentArray
{
    float avgInput;
    if([argumentArray count] < 2)return @"USAGE: totalLatencyOfInputs <type> |<fromType>|";

    if([argumentArray count] == 2)avgInput = [network totalLatencyOfInputsForType:[argumentArray objectAtIndex:1] fromType:@"*"];
    else avgInput = [network totalLatencyOfInputsForType:[argumentArray objectAtIndex:1] fromType:[argumentArray objectAtIndex:2]];

    return [NSString stringWithFormat:@"%g",avgInput];
}


- averageNumberOfInputs:(NSArray *)argumentArray
{
    float avgInput;
    if([argumentArray count] < 2)return @"USAGE: averageNumberOfInputs <type> |<fromType>|";

    if([argumentArray count] == 2)avgInput = [network averageNumberOfInputsForType:[argumentArray objectAtIndex:1] fromType:@"*"];
    else avgInput = [network averageNumberOfInputsForType:[argumentArray objectAtIndex:1] fromType:[argumentArray objectAtIndex:2]];

    return [NSString stringWithFormat:@"%g",avgInput];
}

- averageWeightOfInputs:(NSArray *)argumentArray
{
    float avgInput;
    if([argumentArray count] < 2)return @"USAGE: averageWeightOfInputs <type> |<fromType>|";

    if([argumentArray count] == 2)avgInput = [network averageWeightOfInputsForType:[argumentArray objectAtIndex:1] fromType:@"*"];
    else avgInput = [network averageWeightOfInputsForType:[argumentArray objectAtIndex:1] fromType:[argumentArray objectAtIndex:2]];

    return [NSString stringWithFormat:@"%g",avgInput];
}

- averageLatencyOfInputs:(NSArray *)argumentArray
{
    float avgInput;
    if([argumentArray count] < 2)return @"USAGE: averageLatencyOfInputs <type> |<fromType>|";

    if([argumentArray count] == 2)avgInput = [network averageLatencyOfInputsForType:[argumentArray objectAtIndex:1] fromType:@"*"];
    else avgInput = [network averageLatencyOfInputsForType:[argumentArray objectAtIndex:1] fromType:[argumentArray objectAtIndex:2]];

    return [NSString stringWithFormat:@"%g",avgInput];
}

- updateConnectionStatistics:(NSArray *)argumentArray
{
    [network _updateConnectionStatistics];

    return @"Connection statistics updated";
}

- connectionsTable:(NSArray *)argumentArray
{
	return [network connectionsTable];
}

- help:(NSArray *)argumentArray
{
    NSString *helpString,*helpPath = [[NSBundle bundleForClass:[self class]]
            pathForResource:@"help" ofType:@"txt"];
    NSAssert1(helpPath,@"Help is not currently available at %@. Sorry!",helpPath);
    helpString = [NSString stringWithContentsOfFile:helpPath];
    return helpString;
}

- listLog:(NSArray *)argumentArray
{
    NSDictionary *log;
    NSMutableString *logList = [NSMutableString string];
    NSEnumerator *logEnum;
    NSString *key;
    
    log = [network logDictionary];
    
    logEnum = [[[log allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    
    while(key = [logEnum nextObject]){
        [logList appendFormat:@"%@\n",[log objectForKey:key]];
    }
    return logList;
}

- clearLog:(NSArray *)argumentArray
{
    [network setupLog];
    return @"Log cleared.";
}

- saveLog:(NSArray *)argumentArray
{
    NSString *log;
    NSString *path;
    if([argumentArray count] < 2)return @"USAGE: saveLog <path>";
    
    path = [[argumentArray objectAtIndex:1] stringByStandardizingPath];
    log = [self listLog:nil];
    [log writeToFile:path atomically:YES];
    return [NSString stringWithFormat:@"Saved log to %@.",path];
}


- version:(NSArray *)argumentArray
{
    return [NSString stringWithCString:SIMVersionString()];
}

- isRunning:(NSArray *)argumentArray
{
    if (running) return @"YES"; else return @"NO";
}
@end
