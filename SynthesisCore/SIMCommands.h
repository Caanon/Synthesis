/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMCommandServer.h>

@interface SIMCommandServer (SIMCommands)

- valueForPath:(NSArray *)argumentArray;

- ls:(NSArray *)argumentArray;
- cd:(NSArray *)argumentArray;
- shellCommand:(NSArray *)argumentArray;
- set:(NSArray *)argumentArray;
- undo:(NSArray *)argumentArray;
- redo:(NSArray *)argumentArray;
- get:(NSArray *)argumentArray;
- pwd:(NSArray *)argumentArray;
- newNetwork:(NSArray *)argumentArray;
- loadState:(NSArray *)argumentArray;
- saveState:(NSArray *)argumentArray;
- loadNetwork:(NSArray *)argumentArray;
- saveNetwork:(NSArray *)argumentArray;
- initialize:(NSArray *)argumentArray;
- initConnections:(NSArray *)argumentArray;
- reset:(NSArray *)argumentArray;
- setInitialState:(NSArray *)argumentArray;
- setRandomState:(NSArray *)argumentArray;
- setNullState:(NSArray *)argumentArray;
- setTime:(NSArray *)argumentArray;
- time:(NSArray *)argumentArray;
- setUpdateInterval:(NSArray *)argumentArray;
- updateInterval:(NSArray *)argumentArray;
- run:(NSArray *)argumentArray;
- runUntil:(NSArray *)argumentArray;
- update:(NSArray *)argumentArray;
- updateUntil:(NSArray *)argumentArray;
- stop:(NSArray *)argumentArray;
- continue:(NSArray *)argumentArray;
- terminate:(NSArray *)argumentArray;
- startDate:(NSArray *)argumentArray;
- isRunning:(NSArray *)argumentArray;
- serverName:(NSArray *)argumentArray;
- byteOrder:(NSArray *)argumentArray;

- addAgents:(NSArray *)argumentArray;
- removeAgent:(NSArray *)argumentArray;
- removeAllAgents:(NSArray *)argumentArray;

- startAllAgents:(NSArray *)argumentArray;
- stopAllAgents:(NSArray *)argumentArray;
- startAgent:(NSArray *)argumentArray;
- stopAgent:(NSArray *)argumentArray;

- addIntrinsicChannels:(NSArray *)argumentArray;
- addInputChannels:(NSArray *)argumentArray;
- addCellCompartments:(NSArray *)argumentArray;

- scaleConnections:(NSArray *)argumentArray;
- setConnections:(NSArray *)argumentArray;
- modifyConnections:(NSArray *)argumentArray;
- listConnectionsForCell:(NSArray *)argumentArray;

- updateConnectionStatistics:(NSArray *)argumentArray;
- averageNumberOfInputs:(NSArray *)argumentArray;
- averageWeightOfInputs:(NSArray *)argumentArray;
- averageLatencyOfInputs:(NSArray *)argumentArray;
- totalWeightOfInputsForCell:(NSArray *)argumentArray;
- totalNumberOfInputsForCell:(NSArray *)argumentArray;
- totalLatencyOfInputsForCell:(NSArray *)argumentArray;
- totalNumberOfInputs:(NSArray *)argumentArray;
- totalWeightOfInputs:(NSArray *)argumentArray;
- totalLatencyOfInputs:(NSArray *)argumentArray;



- version:(NSArray *)argumentArray;

- help:(NSArray *)argumentArray;
- clearLog:(NSArray *)argumentArray;
- saveLog:(NSArray *)argumentArray;

// private
- (NSArray *)matchPathPattern:(NSString *)pattern;
- (void)_enumeratePaths:(NSDictionary *)dict path:(NSString *)rootPath paths:(NSMutableArray *)paths;

@end
