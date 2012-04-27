/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <Foundation/Foundation.h>
#import <Desiderata/NSValueArray.h>
#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMModel.h>
#import <SynthesisCore/SIMCell.h>
#import <SynthesisCore/SIMChannel.h>
#import <SynthesisCore/SIMInputChannel.h>
#import <SynthesisCore/SIMConnections.h>

@interface SIMType : NSObject 
{
    NSString				*typeName;
    NSMutableDictionary		*typeDictionary;
    NSMutableDictionary		*inputChannelsDict;
    NSMutableDictionary		*intrinsicChannelsDict;
    NSMutableDictionary		*cellCompartmentsDict;
    NSDictionary			*modelLibraryDict;
	SIMNetwork				*network;
    NSMutableSet			*cellCompartmentClasses,*connectionsClasses,*inputChannelClasses,*intrinsicChannelClasses;
    SIMChannel				**intrinsicChannels;
    SIMInputChannel 		**inputChannels;
    SIMCell					**cellCompartments;
    SIMState				*userState;
    int						numInputChannels,numIntrinsicChannels,numCellCompartments,_assignedIndex;
    float					percentage;
}

- initWithDescription:(NSDictionary *)description;
- initWithDescription:(NSDictionary *)typeDescription usingModelLibrary:(NSDictionary *)modelDict;

- (SIMNetwork *)network;

- (NSArray *)allIntrinsicChannelKeys;
- (NSArray *)allInputChannelKeys;
- (NSArray *)allCellCompartmentKeys;

- (SIMCell *)cellCompartmentAtIndex:(int)index;
- (SIMCell *)cellCompartmentWithName:(NSString *)name;

- (void) addIntrinsicChannel:(SIMChannel *)channel withName:(NSString *)name;
- (SIMChannel *) intrinsicChannelWithName:(NSString *)name;
- (SIMChannel *) intrinsicChannelAtIndex:(int)index;
- (int) indexOfIntrinsicChannel:(NSString *)type;

- (void) addInputChannel:(SIMChannel *)channel withName:(NSString *)name;
- (SIMInputChannel *) inputChannelWithName:(NSString *)name;
- (SIMInputChannel *) inputChannelAtIndex:(int)index;
- (int) indexOfInputChannel:(NSString *)type;

- (SIMState *) userState;


- (void) addIntrinsicChannel:(NSString *)modelKey withDescription:(NSDictionary *)descDict;
- (void) addInputChannel:(NSString *)modelKey withDescription:(NSDictionary *)descDict;
- (void) addCellCompartment:(NSString *)modelKey withDescription:(NSDictionary *)descDict;

- (int) indexOfCellCompartment:(NSString *)type;
- (int) indexOfIntrinsicChannel:(NSString *)type;
- (int) indexOfInputChannel:(NSString *)type;

- (unsigned) assignedIndex;
- (void)setAssignedIndex:(unsigned)index;
- (float) percentage;
- (void) setPercentage:(float)val;
- (NSString *) name;
- (void)setName:(NSString *)name;

/*  This is under consideration...
- (void) applyInputToCell:(SIMState *)element atIndex:(int)index value:(double)val;
- (void) applyInputToCell:(SIMState *)element value:(double)val;
- (void) applyInputToChannel:(SIMState *)element atIndex:(int)index value:(double)val;
- (void) applyInputToChannel:(SIMState *)element value:(double)val;
*/

- (double) summedChannelCurrents:(SIMState *)element forCellModel:(SIMCell *)cellModel;
- (double) summedIntrinsicChannelCurrents:(SIMState *)element forCellModel:(SIMCell *)cellModel;
- (double) summedInputChannelCurrents:(SIMState *)element forCellModel:(SIMCell *)cellModel;
- (double) summedAbsoluteInputChannelCurrents:(SIMState *)element forCellModel:(SIMCell *)cellModel;

- (double) intrinsicChannelCurrent:(SIMState *)element atIndex:(int)index forCellModel:(SIMCell *)cellModel;
- (double) intrinsicChannelCurrent:(SIMState *)element forKey:(NSString *)key forCellModel:(SIMCell *)cellModel;
- (double) intrinsicChannelCurrent:(SIMState *)element forKey:(NSString *)key compartment:(int)cellIndex;

- (double) inputChannelCurrent:(SIMState *)element atIndex:(int)index forCellModel:(SIMCell *)cellModel;
- (double) inputChannelCurrent:(SIMState *)element forKey:(NSString *)key forCellModel:(SIMCell *)cellModel;
- (double) inputChannelCurrent:(SIMState *)element forKey:(NSString *)key compartment:(int)cellIndex;

- (void) setMembranePotential:(double)val forCell:(SIMState *)element;
- (void) setMembranePotential:(double)val forCell:(SIMState *)element atIndex:(int)index;
- (double) membranePotential:(SIMState *)element atIndex:(int)index;
- (double) membranePotential:(SIMState *)element;

- (BOOL) shouldCellUpdateConnections:(SIMState *)state;
- (BOOL) isCellSpiking:(SIMState *)state;
- (BOOL) isCellMiniSpiking:(SIMState *)state;
- (BOOL) isCellFiring:(SIMState *)state;
- (BOOL) isCellRefractory:(SIMState *)state;
- (BOOL) isCellResting:(SIMState *)state;
- (SIMActivityStateValue) cellActivityStateValue:(SIMState *)state;

- (NSDictionary *)efferentConnectionModels;
- (NSDictionary *)afferentConnectionModels;

- (void) allocState:(SIMState *)state;
- (void) reallocState:(SIMState *)state forModel:(SIMModel *)model;
- (void) deallocState:(SIMState *)state;

- (void) archiveState:(SIMState *)element withCoder:(NSCoder *)coder;
- (void) unarchiveState:(SIMState *)element withCoder:(NSCoder *)coder;

- (void) archiveActivityState:(SIMState *)element withCoder:(NSCoder *)coder;
- (void) unarchiveActivityState:(SIMState *)element withCoder:(NSCoder *)coder;

- (void) archiveRemoteState:(SIMState *)element withCoder:(NSCoder *)coder;
- (void) unarchiveRemoteState:(SIMState *)element withCoder:(NSCoder *)coder;

- (void) initModelsWithNetwork:(SIMNetwork *)net randomSeed:(int)seed;

- (void) setInitialState:(SIMState *)state;
- (void) setNullState:(SIMState *)state;
- (void) setRandomState:(SIMState *)state;

- (void) updateCellState:(SIMState *)element dt:(float)dt time:(float)t;
- (void) updateIntrinsicChannelState:(SIMState *)element dt:(float)dt time:(float)t;
- (void) updateInputChannelState:(SIMState *)element dt:(float)dt time:(float)t;
- (void) updateConnection:(SIMConnection *)connections fromState:(SIMState *)from toState:(SIMState *)to
	dt:(float)dt time:(float)t;
- (void)initializeConnection:(SIMConnection *)connection toState:(SIMState *)element;

- (NSValueArray *)membranePotentialForCellModel:(NSString *)cell usingChannelModel:(NSString *)channel forDuration:(float)ms
        stimulusDuration:(float)stim magnitude:(float)mag dt:(float)dt;

- (int) numCellCompartments;
- (int) numIntrinsicChannels;
- (int) numInputChannels;

- (int) totalNumberOfInputs:(SIMState *)element;
- (int) totalNumberOfInputs:(SIMState *)element fromLayer:(NSString *)layerName;
- (int) totalNumberOfInputs:(SIMState *)element fromType:(NSString *)typeString;
- (int) totalNumberOfInputs:(SIMState *)element fromTypes:(NSArray *)types;

- (float) totalWeightOfInputs:(SIMState *)element;
- (float) totalWeightOfInputs:(SIMState *)element fromLayer:(NSString *)layerName;
- (float) totalWeightOfInputs:(SIMState *)element fromType:(NSString *)typeString;
- (float) totalWeightOfInputs:(SIMState *)element fromTypes:(NSArray *)types;

- (float) totalLatencyOfInputs:(SIMState *)element;
- (float) totalLatencyOfInputs:(SIMState *)element fromLayer:(NSString *)layerName;
- (float) totalLatencyOfInputs:(SIMState *)element fromType:(NSString *)typeString;
- (float) totalLatencyOfInputs:(SIMState *)element fromTypes:(NSArray *)types;

@end

@interface SIMType (SIMTypeDictionaryAccess) <SIMDictionaryAccess>
- objectAtPath: (NSString *) path;
- (NSArray *) allKeys;
- objectForKey:(id) key;
- (void)setObject:(id) obj forKey: (id)key;
- (NSMutableDictionary *) rootDictionary;
@end


@interface SIMType (SIMTypePrivate)
- (void)_instantiateModelsWithLibrary:(NSDictionary *)dict;
- (void)_instantiateCellModelsWithLibrary:(NSDictionary *)dict;
- (void)_instantiateIntrinsicChannelsWithLibrary:(NSDictionary *)dict;
- (void)_instantiateInputChannelsWithLibrary:(NSDictionary *)dict;
- (NSMutableDictionary *)_instantiateConnectionGenerators:(NSDictionary *)objectDictionary withLibrary:(NSDictionary *)dict;
@end
