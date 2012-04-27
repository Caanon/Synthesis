/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMNetwork.h>


typedef enum {
        SIMSetToValue,	
        SIMScaleByValue,
        SIMAddValue,
		SIMThresholdValue
} SIMChangeConnectionOperation;


@interface SIMNetwork (SIMNetworkTopology)

- (void)addEfferentConnections:(NSDictionary *)effInfo toChannels:(NSArray *)types forCell:(SIMPosition)cell;
- (void)addAfferentConnections:(NSDictionary *)affInfo toChannels:(NSArray *)types forCell:(SIMPosition)cell;
- (void) addConnections:(NSDictionary *)info toChannels:(NSArray *)types forCell:(SIMPosition)aCell asAfferents:(BOOL)affFlag;
- (NSData *)typeDataForLayer:(int)layer;
- (NSArray *)efferentsForCell:(SIMPosition)cellValue toTypes:(NSArray *)toTypes;
- (NSArray *)afferentsForCell:(SIMPosition)cellValue
    fromTypes:(NSArray *)fromTypes;
	
// Boundary condition checking	
- (void)checkBoundary:(SIMPosition *)aPosition connect:(BOOL *)connect conditions:(NSString *)boundaryConditions 
    info:(NSDictionary *)infoDict;
- (void)applyCustomBoundaryCondition:(SIMPosition *)aPosition connect:(BOOL *)connect info:(NSDictionary *)boundaryInfo;
- (void)applyTiledBoundaryCondition:(SIMPosition *)aPosition connect:(BOOL *)connect info:(NSDictionary *)boundaryInfo;
- (void)applyPeriodicBoundaryCondition:(SIMPosition *)aPosition connect:(BOOL *)connect;
- (void)applyClippedBoundaryCondition:(SIMPosition *)aPosition connect:(BOOL *)connect;
- (void)applyNullFluxBoundaryCondition:(SIMPosition *)aPosition connect:(BOOL *)connect;
	
	
	
- (NSString *)typeForCell:(SIMPosition)cellValue;
- (NSValueArray *)connectionsForCell:(SIMPosition)aCell;
- (NSArray *)typesForLayer:(int)layer;
- (NSArray *)layerKeys;  // Was -layers
- (NSDictionary *)getType:(NSString *)typeString;
- (NSDictionary *)getTypes:(NSArray *)typesArray;

// Modifying the network connections
- (unsigned int) setStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType toValue:(float)val;
- (unsigned int) modifyStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType byValue:(float)delta;
- (unsigned int) scaleStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType byValue:(float)scale;
- (unsigned int) thresholdStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType atValue:(float)scale;

- (unsigned int) setStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType fractionOfCells:(float)frac1 toValue:(float)val fractionOfConnections:(float)frac2;
- (unsigned int) modifyStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType fractionOfCells:(float)frac1 byValue:(float)delta fractionOfConnections:(float)frac2;
- (unsigned int) scaleStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType fractionOfCells:(float)frac1 byValue:(float)scale fractionOfConnections:(float)frac2;
- (unsigned int) thresholdStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType fractionOfCells:(float)frac1 atValue:(float)scale fractionOfConnections:(float)frac2;

- (unsigned int) setStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes toValue:(float)val;
- (unsigned int) modifyStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes byValue:(float)delta;
- (unsigned int) scaleStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes byValue:(float)scale;
- (unsigned int) thresholdStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes atValue:(float)scale;

- (unsigned int) setStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes fractionOfCells:(float)frac1 toValue:(float)val fractionOfConnections:(float)frac2;
- (unsigned int) modifyStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes fractionOfCells:(float)frac1 byValue:(float)delta fractionOfConnections:(float)frac2;
- (unsigned int) scaleStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes fractionOfCells:(float)frac1 byValue:(float)scale fractionOfConnections:(float)frac2;
- (unsigned int) thresholdStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes fractionOfCells:(float)frac1 atValue:(float)scale fractionOfConnections:(float)frac2;

- (NSData *)connectionMatrixFromLayer:(NSString *)fromLayer andType:(NSString *)fromType toLayer:(NSString *)toLayer andType:(NSString *)toType channel:(NSString *)channel;
- (NSString *)connectionsTable;

@end

@interface SIMNetwork (SIMNetworkTopologyPrivate)
- (unsigned int) _changeConnectionStrengthFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes 
    operation:(SIMChangeConnectionOperation)op value:(float)val;
- (int) _countConnectionsTo: (SIMPosition) xyz inSet: (NSCountedSet *) setOfPositions addIt: (BOOL) flag;
- (NSSet *)_getSetOfLayersFromTypesArray:(NSArray *)types;
- (NSSet *)_getSetOfTypesFromTypesArray:(NSArray *)types;
@end
