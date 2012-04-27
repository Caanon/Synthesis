/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/SIMNetworkInfo.h>

@implementation SIMNetwork (SIMNetworkInfo)

- (NSArray *) allLayers
{
    return [self allLayerKeys];
}

- (NSArray *) allTypesForLayer:(NSString *)layer
{
    return [[self typesDictionaryForLayerWithKey:layer] allKeys];    
}

- (NSArray *) allCellsForType:(NSString *)type inLayer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [typeObject allCellCompartmentKeys];
}

- (NSArray *) allIntrinsicChannelsForType:(NSString *)type inLayer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [typeObject allIntrinsicChannelKeys];
}

- (NSArray *) allInputChannelsForType:(NSString *)type inLayer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [typeObject allInputChannelKeys];
}

- (NSArray *) allVariablesForCell:(NSString *)model inType:(NSString *)type layer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [[typeObject cellCompartmentWithName:model] allVariables];

}

- (NSArray *) allVariablesForIntrinsicChannel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [[typeObject intrinsicChannelWithName:model] allVariables];
}

- (NSArray *) allVariablesForInputChannel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [[typeObject inputChannelWithName:model] allVariables];
}

- (int) indexForType:(NSString *)type inLayer:(NSString *)layer
{
    return [[[self typesDictionaryForLayerWithKey:layer] objectForKey:type] assignedIndex];
}

- (int) indexForCell:(NSString *)model inType:(NSString *)type layer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [[typeObject cellCompartmentWithName:model] assignedIndex];
}

- (int) indexForIntrinsicChannel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [[typeObject intrinsicChannelWithName:model] assignedIndex];
}

- (int) indexForInputChannel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [[typeObject inputChannelWithName:model] assignedIndex];
}

- (int) indexForCellVariable:(NSString *)name inModel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [[typeObject cellCompartmentWithName:model] indexOfVariable:name];
}

- (int) indexForIntrinsicChannelVariable:(NSString *)name inModel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [[typeObject intrinsicChannelWithName:model] indexOfVariable:name];
}

- (int) indexForInputChannelVariable:(NSString *)name inModel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [[typeObject inputChannelWithName:model] indexOfVariable:name];
}

- (SIMValueType) valueTypeForCellVariable:(NSString *)name inModel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [[typeObject cellCompartmentWithName:model] typeForVariable:name];
}

- (SIMValueType) valueTypeForIntrinsicChannelVariable:(NSString *)name inModel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [[typeObject intrinsicChannelWithName:model] typeForVariable:name];
}

- (SIMValueType) valueTypeForInputChannelVariable:(NSString *)name inModel:(NSString *)model inType:(NSString *)type layer:(NSString *)layer
{
    SIMType *typeObject = [[self typesDictionaryForLayerWithKey:layer] objectForKey:type];
    return [[typeObject inputChannelWithName:model] typeForVariable:name];
}

@end

@implementation SIMNetwork (LayerAccessMethods)

- (int) nodeForLayer:(int)l
{
    return layerInfo[l].node;
}

- (int) nodeForLayerWithKey:(NSString *)layerKey
{
    int l = [self indexForLayerWithKey:layerKey];
    return layerInfo[l].node;
}

- (NSString *) nodeNameForLayerWithKey:(NSString *)layerKey
{
return @"";
}

- (NSArray *) layersForNode:(int)node
{
return [NSArray array];
}

- (int) indexForLayerWithKey: (NSString *) layerKey
{ return [[layerDictionary objectForKey: layerKey] intForKey:SIMIndexKey]; }

- (NSArray *)allLayerKeys
{
    return [layerDictionary allKeys];
}
- (NSString *) keyForLayerAtIndex: (int)index
{
    NSEnumerator *varEnum = [[self allLayerKeys] objectEnumerator];
    NSString *layerName;
    while(layerName = [varEnum nextObject]){
        if([self indexForLayerWithKey:layerName] == index)return layerName;
    }
    return @"NotFound";
}

- (unsigned) countLayers
{ return [layerDictionary count]; }

- (unsigned) numLayers
{ return [layerDictionary count]; }

- (unsigned) numRowsInLayerWithKey: (NSString *) layerKey
{
 	int l = [[layerDictionary objectForKey: layerKey] intForKey:SIMIndexKey];
	return layerInfo[l].numRows; 
}

- (unsigned) numColumnsInLayerWithKey: (NSString *) layerKey
{	
	int l = [[layerDictionary objectForKey: layerKey] intForKey:SIMIndexKey];
	return layerInfo[l].numColumns; 
}


- (unsigned) numRowsInLayer: (int) l
{ return layerInfo[l].numRows; }

- (unsigned) numColumnsInLayer: (int) l
{ return layerInfo[l].numColumns; }

- (unsigned) numberOfRowsInLayerAtIndex: (int) l
{ return layerInfo[l].numRows; }

- (unsigned) numberOfColumnsInLayerAtIndex: (int) l
{ return layerInfo[l].numColumns; }

- (NSDictionary *) layerDictionaryForIndex: (int) l
{ return [layerDictionary objectForKey:[self keyForLayerAtIndex: l]];}

- (NSDictionary *) typesDictionaryForIndex: (int) l
{ return [[self layerDictionaryForIndex:l] objectForKey:SIMTypesKey];}

@end
