/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/SIMAgent.h>

@implementation SIMAgent
/*"
    The SIMAgent object is designed to simply register itself for a particular notification from the network.
    When that notification arrives, some method (defined by the agent) is called and the agent can do whatever it desires.
    This is typically for data gathering purposes.
"*/

- initWithDescription:(NSDictionary *)desc forNetwork:(SIMNetwork *)net
/*"
    Initializes the agent using the NSDictionary desc to define the agent parameters.
    A reference to the observed network is retained for later data gathering.
"*/
{
    [super initWithDescription:desc];
    [self setNetwork:net];
    server = nil;
    return self;
}

- (NSString *) filePathForKey:(NSString *)key
{
	NSString *rootPath = [self objectForKey:@"RootPath"];
	NSString *filePath;
	if(rootPath != nil)
		filePath = [rootPath stringByAppendingPathComponent:[self objectForKey:key]];
	else filePath = [self objectForKey:key];
	return [filePath stringByStandardizingPath];
}

- (BOOL)createDataDirectory
{
	NSString *path = [[self objectForKey:@"RootPath"] stringByStandardizingPath];

	return [[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
}

- (NSValueArray *)dataBuffer
/*"
    Subclasses may return a buffer of values, should perhaps be an NSData.
"*/
{
    return (NSValueArray *)nil;
}

- (NSValueArray *)times
/*"
    Subclasses may return a buffer of times.
"*/
{
    return (NSValueArray *)nil;
}

- (float) dt
{
    return [network dt];
}

- (void) setNetwork:(SIMNetwork *)net
{
    if(network)[network autorelease];
    network = [net retain];
}

- (SIMNetwork *) network
{
    return network;
}

- (oneway void) updateParameters
/*"
    Assigns instance variables from the parameters in the main dictionary.
"*/
{
    [super updateParameters];
    notificationName = [mainDictionary objectForKey:SIM_NOTIFICATION_KEY];
    selectorName = [mainDictionary objectForKey:SIM_SELECTOR_KEY];
}

- (NSString *)description
/*"
    Returns a string containing the property list description of the main dictionary,
    including parameters and class name.
"*/
{
    NSMutableDictionary *descDict = [NSMutableDictionary dictionary];
    [descDict setObject:[mainDictionary objectForKey:SIMClassNameKey] forKey:SIMClassNameKey];
    [descDict setObject:[mainDictionary objectForKey:SIMParametersKey] forKey:SIMParametersKey];
    return [descDict description];
}

- (void) registerWithServer:(NSString *)sName onHost:(NSString *)hName
/*"
    Currently deprecated.  This may be reused when client-side agents are supported.
"*/
{
	NSConnection *connection;
	
    if(network)[network release];
    if(server)[server release];
    if(sName){
		if([hName isEqual:@""])
			connection  = [NSConnection connectionWithRegisteredName:sName host:nil];
		else {
			NSSocketPort *port = (NSSocketPort *)[[NSSocketPortNameServer sharedInstance] portForName:sName host:hName];
			connection = [NSConnection connectionWithReceivePort:nil sendPort:port];
		}

        if(server == nil)server = [[connection rootProxy] retain];
        network = [[server network] retain];
    }
    else NSLog(@"Couldn't register with server %@ on host %@.",sName,hName);
}

- (void) startAgent
/*"
    Updates the agent parameters, then registers the agent for the notificatios from the network object.
    The selector method to be called is defined in the parameter dictionary.
    After this method is executed, the agent will receive notifications and begins data gathering by calling
    the method defined by the selector name.
"*/
{
    [self updateParameters];

    [[NSNotificationCenter defaultCenter] removeObserver:self]; // Make sure we're only registered once.

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:NSSelectorFromString(selectorName)
        name:notificationName
        object:network];

/*
    if(server){
        [server addClient:self forNotificationName:notificationName selector:NSSelectorFromString(selectorName) object:[server network]];
    }
 */
}

- (void) stopAgent
/*"
    Unregisters the agent from the notification center for any notification from the network that uses the name specified in
    the description dictionary.  The agent stops gathering data.
"*/
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notificationName object:network];
    if(network)[network release];
    //NSNotification *notification = [NSNotification notificationWithName:notificationName object:[server network]];
    //[[NSNotificationQueue defaultQueue] dequeueNotificationsMatching:notification coalesceMask:NSNotificationCoalescingOnName|NSNotificationCoalescingOnSender];
    //if(server)[server removeClient:self];
}

- (void)dealloc
/*"
    Deallocates the model.
"*/
{
    [super dealloc];
}

@end
