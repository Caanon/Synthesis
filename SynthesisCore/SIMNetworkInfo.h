/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisCore/SIMType.h>
#import <SynthesisCore/Simulator.h>

@interface SIMNetwork (SIMNetworkInfo)

- (NSArray *) allLayers;
- (NSArray *) allTypesForLayer:(NSString *)layer;
- (NSArray *) allCellsForType:(NSString *)type inLayer:(NSString *)layer;
- (NSArray *) allIntrinsicChannelsForType:(NSString *)type inLayer:(NSString *)layer;
- (NSArray *) allInputChannelsForType:(NSString *)type inLayer:(NSString *)layer;
- (NSArray *) allVariablesForCell:(NSString *)model inType:(NSString *)type layer:(NSString *)layer;
- (NSArray *) allVariablesForIntrinsicChannel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer;
- (NSArray *) allVariablesForInputChannel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer;
- (int) indexForType:(NSString *)type inLayer:(NSString *)layer;
- (int) indexForCell:(NSString *)model inType:(NSString *)type layer:(NSString *)layer;
- (int) indexForInputChannel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer;
- (int) indexForIntrinsicChannel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer;
- (int) indexForCellVariable:(NSString *)name inModel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer;
- (int) indexForIntrinsicChannelVariable:(NSString *)name inModel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer;
- (int) indexForInputChannelVariable:(NSString *)name inModel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer;
- (SIMValueType) valueTypeForCellVariable:(NSString *)name inModel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer;
- (SIMValueType) valueTypeForIntrinsicChannelVariable:(NSString *)name inModel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer;
- (SIMValueType) valueTypeForInputChannelVariable:(NSString *)name inModel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer;

@end

@interface SIMNetwork (LayerAccessMethods)
- (int) indexForLayerWithKey: (NSString *) layerKey;
- (NSString *) keyForLayerAtIndex: (int) l;
- (NSArray *) allLayerKeys;
- (unsigned) countLayers;
- (unsigned) numLayers;
- (unsigned) numRowsInLayerWithKey: (NSString *) l;
- (unsigned) numColumnsInLayerWithKey: (NSString *) l;
- (unsigned) numRowsInLayer: (int) l;
- (unsigned) numColumnsInLayer: (int) l;
- (unsigned) numberOfRowsInLayerAtIndex: (int) l;
- (unsigned) numberOfColumnsInLayerAtIndex: (int) l;
- (NSDictionary *) layerDictionaryForIndex: (int) l;
- (NSDictionary *) typesDictionaryForIndex: (int) l;
@end

