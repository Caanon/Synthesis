//
//  SIMNetworkNode.m
//  SynthesisCore
//
//  Created by shill on Mon Jul 02 2001.
//  Copyright (c) 2003. All rights reserved.
//

#import <SynthesisCore/SIMNetworkNode.h>
#import <SynthesisCore/SIMCommandServer.h>

@implementation SIMNetwork (SIMNetworkNode)

- (void) _initNodes
{
    int	i;
        
    [self postStatusNotificationWithDescription:@"Allocating node information." progress:0.0];
    
    localNode = [[self objectForKey:SIMNodeKey] intValue];
        
    numNodes = [nodeDictionary count];
            
    nodeInfo = (SIMNode *)NSZoneMalloc([self zone], numNodes*sizeof(SIMNode));
    
    for(i = 0; i < numNodes; i++){
        NSDictionary *nodeDict = [nodeDictionary objectForKey:[NSString stringWithFormat:@"%d",i]];
        nodeInfo[i].status = SIM_NODE_WAITING;
        nodeInfo[i].dataProcessed = NO;
        nodeInfo[i].serverName = [[nodeDict objectForKey:SIMServerNameKey] retain]; 
        nodeInfo[i].hostName = [[nodeDict objectForKey:SIMHostNameKey] retain]; 
        nodeInfo[i].node = [self connectToNode:i]; 
    }

    [self _initRemoteUpdateQueues];
        
    [self postStatusNotificationWithDescription:@"Finished allocating node information." progress:1.0];
}


- (void) _initRemoteUpdateQueues
{
    int l,n,k;
    
    queue = (SIMUpdateQueue ***)NSZoneMalloc([self zone],sizeof(SIMUpdateQueue **) * numLayers);
    for(l = 0; l < numLayers; l++){
        if(layerInfo[l].node == localNode)continue; // skip local layers
        queue[l] = (SIMUpdateQueue **)NSZoneMalloc([self zone],sizeof(SIMUpdateQueue *)*numNodes);
        for(n = 0; n < numNodes; n++){
            nodeInfo[n].dataProcessed = NO;
            nodeInfo[n].status = SIM_NODE_WAITING;
            if(n == localNode)continue; // skip local node
            queue[l][n] = (SIMUpdateQueue *)NSZoneMalloc([self zone],sizeof(SIMUpdateQueue)*numLayers);
            for(k = 0; k < numLayers; k++){
                if(layerInfo[k].node == localNode)continue; // skip local layers
                queue[l][n][k].count = 0;
                queue[l][n][k].data = [NSMutableData data];
                queue[l][n][k].archiver = [[NSArchiver alloc] initForWritingWithMutableData:queue[l][n][k].data];
            }
        }
    }
}

- (void) _emptyRemoteUpdateQueues
{
    int l,n,k;
        
    for(l = 0; l < numLayers; l++){
        if(layerInfo[l].node == localNode)continue; // skip local layers
        for(n = 0; n < numNodes; n++){
            nodeInfo[n].status = SIM_NODE_WAITING;
            nodeInfo[n].dataProcessed = NO;
            if(n == localNode)continue; // skip local node
            for(k = 0; k < numLayers; k++){
                if(layerInfo[k].node == localNode)continue; // skip local layers
                queue[l][n][k].count = 0;
                [queue[l][n][k].data setLength:0]; // We really don't want to reallocate each time
                [queue[l][n][k].archiver initForWritingWithMutableData:[queue[l][n][k].data autorelease]]; // is this a bad idea?
            }
        }
    }
}

- (void) remoteUpdateWithConnection:(SIMConnection *)connection fromState:(SIMState *)from dt:(float)delta time:(float)t
// must be heavily optimized.
{
    SIMRemoteUpdate updateInfo;
    NSArchiver *archiver;  
    int toLayer = from->position.z + connection->dz;
    int toNode = layerInfo[toLayer].node; // get Node info from this.
    
    updateInfo.fromLayer = from->position.z;
    updateInfo.fromType = [from->type assignedIndex];
    updateInfo.dt = delta;
    updateInfo.time = t;
    
    archiver = queue[updateInfo.fromLayer][toNode][toLayer].archiver;  
    
    [archiver encodeValueOfObjCType:@encode(SIMRemoteUpdate) at:&updateInfo];
    [archiver encodeConnection:connection];
    [from->type archiveRemoteState:from withCoder:archiver];
    queue[updateInfo.fromLayer][toNode][toLayer].count++;
}

- (void) updateLayer:(int)layer withData:(NSData *)data fromNode:(int)node
{
    int i,l,count;
    SIMRemoteUpdate updateInfo;
    SIMConnection connection;
    NSUnarchiver *unarchiver = [[NSUnarchiver alloc] initForReadingWithData:data];
    
    for(l = 0; l < numLayers; l++){ // from layers
        if(layerInfo[l].node != node) continue; // skip the layers in the other nodes
        [unarchiver decodeValueOfObjCType:@encode(int) at:&count];
        data = [[unarchiver decodeDataObject] retain];
        for(i=0; i < count; i++){
            int x,y;
            SIMType *fromType;
            SIMState *fromState;
            [unarchiver decodeValueOfObjCType:@encode(SIMRemoteUpdate) at:&updateInfo];
            [unarchiver decodeConnection:&connection];
            fromType = layerInfo[updateInfo.fromLayer].types[updateInfo.fromType];
            fromState = [fromType userState];
            [fromType unarchiveRemoteState:fromState withCoder:unarchiver];

            x = fromState->position.x + connection.dx;
            y = fromState->position.y + connection.dy;

            [fromType updateConnection:&connection
                fromState:fromState
                toState:&layers[layer][y][x]
                dt:updateInfo.dt time:updateInfo.time];
        }
    }
}

- (NSData *) dataForLayer:(int)layer node:(int)node
{
    int l;
 // Should try to have the data prewrapped.
    NSMutableData *data = [[NSMutableData data] retain];
    NSArchiver *archiver = [[NSArchiver alloc] initForWritingWithMutableData:data];
    /* Encapsulate all queue data objects by destination layer */
    for(l = 0; l < numLayers; l++){ // from layers
        if(layerInfo[l].node != localNode)continue; // We only have data from layers on the local node
        [archiver encodeValueOfObjCType:@encode(int) at:&queue[l][node][layer].count];
        [archiver encodeDataObject:queue[l][node][layer].data];
    }
    [archiver release];
    return [data autorelease];
}

- (void) nodeDidUpdate:(NSNotification *)n
{
    int node = [[n object] nodeIdentifier];
    nodeInfo[node].status = SIM_NODE_DONE;
    
    if(nodeInfo[localNode].status == SIM_NODE_DONE){
        [self updateFromRemoteNodes];
    }
}

- (void) updateFromRemoteNodes
{
    int l,n,updatedNodes = 0;
// Check for finished, unprocessed nodes and update the network using them.
    for(n = 0; n < numNodes; n++){
        if((nodeInfo[n].status == SIM_NODE_DONE) && (nodeInfo[n].dataProcessed == NO)){
            for(l = 0; l < numLayers; l++){
                NSData *updateData;
                if(layerInfo[l].node == localNode)continue;
                updateData = [self dataForLayer:l node:n];
                [self updateLayer:l withData:updateData fromNode:n];
            }
            nodeInfo[n].dataProcessed = YES;
        }
        if(nodeInfo[n].dataProcessed)updatedNodes++;
    }
    if(updatedNodes == numNodes){    
        [self _emptyRemoteUpdateQueues];
        [[NSNotificationCenter defaultCenter] postNotificationName:SIMNetworkDidUpdateNotification object:self];
    }
}

- (int) nodeIdentifier
{
    return localNode;
}

- connectToNode:(int)n
{
    // identify if this localNode is the same node

    if(localNode == n){ 
        nodeInfo[n].node = self;
        return self;
    }
    else {

//#if ALLOW_LOCAL_CONNECTIONS_ONLY
//		NSConnection *connection = [NSConnection connectionWithRegisteredName:nodeInfo[n].serverName host:nil];
//#else
        NSSocketPortNameServer *sharedInstance = [NSSocketPortNameServer sharedInstance];
        SIMNode * nodez = nodeInfo;
		NSSocketPort *port = (NSSocketPort *)[sharedInstance portForName:nodeInfo[n].serverName host:nodeInfo[n].hostName];
		NSConnection *connection = [NSConnection connectionWithReceivePort:nil sendPort:port];
//#endif

        id server = nil; 
                
        if(!connection)return NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(serverConnectionDidDie:)
            name:NSConnectionDidDieNotification
            object:connection];
    
        if(server == nil)server = [[connection rootProxy] retain];
    
        if(server){
            /* Register for NodeDidUpdate notification */
            [server addClient:self forNotificationName:SIMNodeDidUpdateNotification selector:@selector(nodeDidUpdate:) object:nil];
            nodeInfo[n].server = server;
            nodeInfo[n].node = [(SIMCommandServer *)server network];
            return server;
        }
        else return nil;
    }
}

- (void) serverConnectionDidDie:(NSNotification *)n
{
    NSLog(@"Lost connection to a network node.");
    // identify which node died and reconnect.
}

@end
