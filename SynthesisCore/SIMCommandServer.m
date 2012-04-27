/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */


#import <SynthesisCore/SIMCommandServer.h>
#import <SynthesisCore/SIMCommands.h>∫
#import <sys/sysctl.h>

/*"
    This class provides control of a simulation and its SIMNetwork.  Methods are provided for loading networks, 
    connecting and removing remote clients.  In addition, SIMCommandServer can process scripts.
"*/

@implementation SIMCommandServer

+ (int) numberOfProcessors
{
	int processors, error, selectors[2] = { CTL_HW, HW_NCPU };
	size_t datasize = sizeof(processors);
	error = sysctl(selectors, 2, &processors, &datasize, 0, 0);

	return processors;
}

+ (void) runNetworkServer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *name,*net,*state, *script;
    SIMCommandServer *commandController;

    name = [[NSUserDefaults standardUserDefaults] stringForKey:SERVER_NAME_KEY];
    if(!name){
        name = DEFAULT_SERVERNAME;
        [[NSUserDefaults standardUserDefaults] setObject:name forKey:SERVER_NAME_KEY];
    }

    commandController = [[SIMCommandServer alloc] initWithNodeIdentifier:0];
    
    [commandController registerNode];

    if(net = [[NSUserDefaults standardUserDefaults] stringForKey:NETWORK_KEY]){
        NSString *networkCommand = [NSString stringWithFormat:@"loadNetwork %@",[net stringByStandardizingPath]];
        [commandController interpretCommand:networkCommand];
        printf("COMMANDLINE> %s\n",[networkCommand UTF8String]);
    }

    if(state = [[NSUserDefaults standardUserDefaults] stringForKey:STATE_KEY]){
        NSString *networkCommand = [NSString stringWithFormat:@"loadState %@",[state stringByStandardizingPath]];
        [commandController interpretCommand:networkCommand];
        printf("COMMANDLINE> %s\n",[networkCommand UTF8String]);
    }

    if(script = [[NSUserDefaults standardUserDefaults] stringForKey:SCRIPT_KEY]){
        NSString *networkCommand = [NSString stringWithFormat:@"loadScript %@",[script stringByStandardizingPath]];
        [commandController interpretCommand:networkCommand];
        printf("COMMANDLINE> %s\n",[networkCommand UTF8String]);
    }

    [[NSRunLoop currentRunLoop] run];
    [pool release];
    [NSThread exit];
    return; 
}

- init
{
    return [self initWithNodeIdentifier:0];
}

- initWithNodeIdentifier:(int)nodeID
{
    return [self initWithNetworkDescription:nil node:nodeID];
}

- initWithNetworkDescription:(NSDictionary *)dict node:(int)nodeID
{
    NSDictionary *nodeDict;
    id nextNodeKey,nodeEnum;
    int numNodes;
        
    localNode = nodeID;
    
    lock = [[NSLock new] retain];
    
    nodeDict = [dict objectForKey:SIMNodesKey];
    numNodes = [nodeDict count];
    
    nodeEnum = [nodeDict keyEnumerator];
    
    while(nextNodeKey = [nodeEnum nextObject]){
        SIMCommandServer *node = [self _connectToNode:[nodeDict objectForKey:nextNodeKey]];
        [node loadNetworkWithDescription:dict];
        [nodes addObject:node];
    }

    network = nil;
    stopTime = FLT_MAX;
    updateInterval = 1.0;
        
    [self loadNetworkWithDescription:[[dict retain] autorelease]];

    //currentPath = [[NSMutableString stringWithString:SIM_PathSeparator] retain];
    [self setCurrentPath:SIM_PathSeparator];
    if(network){
        [self initialize:nil];
    }
    return self;
}

- (void)registerNode
{
    NSDictionary *nodeInfo = [[[self network] objectForKey:SIMNodesKey] objectForKey:[NSString stringWithFormat:@"%d",localNode]];


    if(serverName)[serverName autorelease];
    serverName = [[NSUserDefaults standardUserDefaults] stringForKey:SERVER_NAME_KEY];
    if(!serverName){
        serverName = [nodeInfo objectForKey:SIMServerNameKey];
    }

    if(clients)[clients release];

    clients = [[NSMutableArray array] retain];
	
	NSConnection *connection1, *connection2;
	NSSocketPort *port = [[NSSocketPort alloc] init];
	connection1 = [NSConnection defaultConnection];
	connection2 = [NSConnection connectionWithReceivePort:port sendPort:nil];

    //[connection enableMultipleThreads];
    [connection1 runInNewThread];
    [connection2 runInNewThread];
    
    [connection1 setRootObject:self];
    [connection2 setRootObject:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(serverConnectionDidDie:)
        name:NSConnectionDidDieNotification
        object:connection1];

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(serverConnectionDidDie:)
        name:NSConnectionDidDieNotification
        object:connection2];

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(clientConnectionDidDie:)
        name:NSConnectionDidDieNotification
        object:nil];

    if (([connection1 registerName:serverName] == NO) || ([[NSSocketPortNameServer sharedInstance] registerPort:port name:serverName] == NO)) {
        NSLog(@"Error registering node as \"%@\".  Perhaps you should try another name?",serverName);
        [self terminate];
    }
    else {
        NSLog(@"Successfully registered node %d as \"%@\".",localNode, serverName);
                NSLog(@"Ready to accept client connections...");
    }
}

- (SIMCommandServer *)_connectToNode:(NSDictionary *)nodeInfo
{
    id server = nil;
    NSString *nodeHost = [nodeInfo objectForKey:SIMHostNameKey];
    NSString *nodeServer = [nodeInfo objectForKey:SIMServerNameKey];

	NSConnection *connection;
	if(nodeHost == nil)
		connection  = [NSConnection connectionWithRegisteredName:nodeServer host:nil];
	else {
		NSSocketPort *port = (NSSocketPort *)[[NSSocketPortNameServer sharedInstance] portForName:nodeServer host:nodeHost];
		connection = [NSConnection connectionWithReceivePort:nil sendPort:port];
	}

    if(!connection)return NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(serverConnectionDidDie:)
        name:NSConnectionDidDieNotification
        object:connection];

    if(server == nil)server = [[connection rootProxy] retain];

    if(server){
        /* Setup for commandline logging of status events */
        [server addClient:self forNotificationName:SIMStatusUpdateNotification selector:@selector(logEvents:) object:nil];
        [server addClient:self forNotificationName:SIMErrorUpdateNotification selector:@selector(logErrors:) object:nil];
        return server;
    }
    else return nil;
}


- (void) loadNetworkWithDescription:(NSDictionary *)dict
/*"
        Loads and initializes a new SIMNetwork object with the description dict.
"*/

{
    [self stop:nil];

    if(network)[network release];

    network = [[SIMNetwork alloc] initWithDescription:dict node:localNode];

}

- (void) loadExperimentWithDescription:(NSDictionary *)dict
/*"
        Loads and initializes a new SIMNetwork object with the description dict.
"*/

{
    [self stop:nil];

    if(network)[network release];

}

/*---------------------------------*/
- (unsigned) hostByteOrder
{
    return NSHostByteOrder();
}

- (id)interpretCommand:(NSString *)commandString
{
    SEL command;
    NSString *commandName;
    NSArray *argumentArray;
    
    commandString = [[commandString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] retain];

   /* is line a comment? */
    if ([commandString hasPrefix:@"//"]) {
        return @"";
    }

    if ([commandString hasPrefix:@"timingOn"]) {
		timingFlag = YES;
        return @"";
    }
    if ([commandString hasPrefix:@"timingOff"]) {
		timingFlag = NO;
        return @"";
    }
    
    if([commandString isEqual:@"!!"]){
        //[commandString ];
    }

    if ([commandString hasPrefix:@">"]) {
        argumentArray = [[NSArray arrayWithObjects:@"shellCommand",[commandString substringFromIndex:1],nil] retain];
    }
    else {
        argumentArray = [[commandString componentsSeparatedByString:@" "] retain];
    }


    [network logEntry:[commandString autorelease]];
            
    commandName = [argumentArray objectAtIndex:0];

   /* substitute alias */
    // something like if ([aliasDict containsObject:command])command = [aliasDict objectWithKey:]

    /* first tries the command on the local object*/
    command = [[commandName stringByAppendingString:@":"] selectorValue];

    if ([self respondsToSelector:command]) {
        id answer;
		if(timingFlag)timingDate = [[NSDate date] retain];
        //[lock lock];
        //[node makeObjectsPerformSelector:command withObject:[argumentArray autorelease]];
        //  Should I make the answer arrive via notifications?
        answer = [self performSelector:command withObject:[argumentArray autorelease]];
		
		if(timingFlag){
			answer = [answer stringByAppendingFormat:@"\nTiming = %g seconds",-[timingDate timeIntervalSinceNow]];
			[timingDate release];
		}
        //[lock unlock];
        return answer;
    } else {
        return [NSString stringWithFormat:@"Command: '%s' not found",[commandName UTF8String]];
    }
}

// Very simple and basic add/remove client methods

- (void)addClient:aClient forNotificationName:(NSString *)name selector:(SEL)aSelector object:anObject
{
    [clients addObject:aClient];
    // Timedit
    [[NSNotificationCenter defaultCenter] addObserver:aClient selector:aSelector name:name object:(self.network)];
    //[[NSNotificationCenter defaultCenter] addObserver:aClient selector:aSelector name:name object:anObject];

    //NSLog(@"A client has connected from host: \"%@\".",[aClient hostName]);
}

- (void)removeClient:aClient forNotificationName:(NSString *)name object:anObject
{
    [[NSNotificationCenter defaultCenter] removeObserver:aClient name:name object:anObject];
    [clients removeObject:aClient];
    //NSLog(@"Removed a client connected from host: \"%@\".",[aClient hostName]);
}

- (void)removeClient:aClient
{
    [[NSNotificationCenter defaultCenter] removeObserver:aClient];
    [clients removeObject:aClient];
    //NSLog(@"Removed a client connected from host: \"%@\".",[aClient hostName]);
}

- (void)removeAllClients:sender
{
    [self removeAllClients];
}

- (void)removeAllClients
{
    NSEnumerator *enumerator = [clients objectEnumerator];
    id next;
    id nCenter = [NSNotificationCenter defaultCenter];

    while(next = [enumerator nextObject]) {
        [nCenter removeObserver:next];
    }
    [clients removeAllObjects];
    NSLog(@"Removed all connected clients.");
}

- (int) nodeIdentifier
{
    return localNode;
}

- (int) clientCount
{
    return [clients count];
}

- (SIMNetwork *)network
{
    //if(isExperiment)return [experiment network];
    return network;
    // Perhaps this should be networkWithName eventually....
}

/*
- (void)initialize
{
    [network initModels];
    [network setInitialStates];
}
*/

- (void)run
{
    //if(isExperiment)[experiment run:self];
    [self run:nil];
}

- (void)update
{
    if(running && (([network time]+updateInterval) <= stopTime)){
        [network updateMilliseconds:updateInterval];
    }
    else {
        running = NO;
        stopTime = 0.0;
        [runTimer invalidate];
    }
}

- currentObject
{
    id obj = [network objectAtPath:[self currentPath]];
    if(obj) return obj;
    else return network;
}

- (void)setCurrentPath:(NSString *)path
{
    if(!currentPath)currentPath = [NSMutableString stringWithString:path];
    else [currentPath setString:path];
#if 0
    [[[NSThread currentThread] threadDictionary] setObject:path forKey:@"PATH"];
#endif
}

- currentPath
{
#if 0
    id answer;
    answer = [[[[NSThread currentThread] threadDictionary] objectForKey:@"PATH"] copy];
    //if(!answer)return SIM_PathSeparator;
    return [answer autorelease];
#endif
    return currentPath;
}

- (void)stop
{
    //if(isExperiment)[experiment stop:nil];
    [self stop:nil];
}

- (void)terminate
{
        if(running)[self stop];
        exit(0);
}

- (NSDate *)startDate
{
        if(running)return startDate;
        else return [NSDate date];
}

- (BOOL) isRunning
{
    return running;
}

- (NSMutableDictionary *)rootDictionary
{
    return [network rootDictionary];
}

- (NSMutableDictionary *)experimentDictionary
{
        return [network rootDictionary];  // change this to experiment
}

- loadScript:(NSArray *)argumentArray
{
    if([argumentArray count] == 2){
        NSString *myScript = [NSString stringWithContentsOfFile:[[argumentArray objectAtIndex:1] stringByStandardizingPath]];
        if(myScript){
            [self interpretScript:myScript];
            return [NSString stringWithFormat:@"Executed script: %@.",[argumentArray objectAtIndex:1]];
        }
        else return [NSString stringWithFormat:@"Couldn't load script: %@.",[argumentArray objectAtIndex:1]];
    }
    else return @"USAGE: loadScript <filename>";
}

- (BOOL) interpretScript:(NSString *)script
{
    NSScanner *scriptScanner = [NSScanner scannerWithString:script];
    NSString *command;

    if([script isKindOfClass:[NSArray class]])return NO;

    while ([scriptScanner isAtEnd] == NO) {
        NSCharacterSet *lfcrSet = [NSCharacterSet characterSetWithCharactersInString:@"\r\n"];
        [scriptScanner scanUpToCharactersFromSet:lfcrSet intoString:&command];
        [scriptScanner scanCharactersFromSet:lfcrSet intoString:NULL];
        [self interpretCommand:command];
        printf("SCRIPT> %s\n",[command UTF8String]);
    }
    return YES;
}


// NSConnection Notifications

- (void)serverConnectionDidDie:(NSNotification *)n
{
   NSLog(@"The server has lost its connection to the rest of the world.");
       [network release];
       exit(1);
}

- (void)clientConnectionDidDie:(NSNotification *)n
{
       id enumerator,next,deadClients = [NSMutableArray array];
       int	count;

   //NSLog(@"A client has recently died without checking out.");
   enumerator = [clients objectEnumerator];
   while(next = [enumerator nextObject]) {
       NS_DURING
           if([[next connectionForProxy] isEqual:[n object]]){
               [deadClients addObject:next];  //Can't check them out yet (we're enumerating clients)
           }
       NS_HANDLER
           NSLog(@"Couldn't remove a dead client.");
       NS_ENDHANDLER
   }
       count = [deadClients count];
       if(count){
       enumerator = [deadClients objectEnumerator];
       while(next = [enumerator nextObject]) {
           NS_DURING
               [[NSNotificationCenter defaultCenter] removeObserver:next];
           NS_HANDLER
               NSLog(@"Couldn't remove a dead client.");
           NS_ENDHANDLER
       }
       NSLog(@"Successfully checked out %d dead client(s).\n",count);
   }
}

- (void)dealloc
{
    [network release];
    [super dealloc];
}

@end
