/*
 *  SIMNetworkNode.h
 *  SynthesisCore
 *
 *  Created by shill on Tue Jul 03 2001.
 *  Copyright (c) 2003. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisCore/SIMCategories.h>

@interface SIMNetwork (SIMNetworkNode)

- (void) updateLayer:(int)layer withData:(NSData *)data fromNode:(int)node;
- (void) updateFromRemoteNodes;
- (void) nodeDidUpdate:(NSNotification *)n;
- (NSData *) dataForLayer:(int)layer node:(int)node;
- (void) remoteUpdateWithConnection:(SIMConnection *)connection fromState:(SIMState *)from dt:(float)delta time:(float)t;

- connectToNode:(int)n;
- (int) nodeIdentifier;

- (void) _initNodes;
- (void) _emptyRemoteUpdateQueues;
- (void) _initRemoteUpdateQueues;

@end
