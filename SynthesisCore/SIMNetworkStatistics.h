/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisCore/SIMNetworkTopology.h>
#import <SynthesisCore/SIMEventData.h>
#import <SynthesisCore/Simulator.h>

typedef enum {
    SIM_IntrinsicChannelType,
    SIM_InputChannelType,
    SIM_CellCompartmentType
} SIMModelType;


@protocol SIMNetworkStatistics

- (float)time;
- (float)dt;
- (float) localFieldPotentialForCell:(SIMPosition *)pos radius:(int)r;
- (float)globalFieldPotentialForLayer:(int)l;
- (SIMStateValue)valueOfVariable:(in int)variable forCell:(in SIMPosition *)cell;	
- (int)numberActiveForType:(in int)type;
- (int)countForType:(in int)type;
- (int)typeOfCell:(in SIMPosition *)cell;
- (int)countOfConnectionsFromCell:(in SIMPosition *)cell
        toType:(in int)toType;
- (int)countOfConnectionsFromType:(in int)fromType
        toType:(in int)toType;
- (NSData *)intrinsicChannelDataAtIndex:(int)variable withType:(NSString *)type forLayer:(int)layer;
- (NSData *)inputChannelDataAtIndex:(int)variable withType:(NSString *)type forLayer:(int)layer;
- (NSData *)cellDataAtIndex:(int)variable withType:(NSString *)type forLayer:(int)layer;
- (NSData *)intrinsicChannelDataAtIndex:(int)variable forLayer:(int)layer;
- (NSData *)inputChannelDataAtIndex:(int)variable forLayer:(int)layer;
- (NSData *)cellDataAtIndex:(int)variable forLayer:(int)layer;
- (NSData *)cellDataAtIndex:(unsigned)variable forCells:(NSArray *)positions;
- (NSData *)channelDataAtIndex:(unsigned)variable forCells:(NSArray *)positions;
- (int)countOfSpikingCellsWithType:(NSString *)type;
- (int) countOfSpikingCellsInRegionOfLayer: (int) l
    xOffset:(int)xoff yOffset:(int)yoff
    xWidth:(int)numColumns yWidth:(int)numRows
    withType:(NSString *)type;
- (float)globalFieldPotentialForLayer:(int)l;
- (NSString *)recordFromCells:(NSValueArray *)positions
    event: (int) event startCode: (int) start
    lastEventTime: (int *) lastTime
    sync: (int) sync code: (int) code;
- (NSArray *)arrayOfRandomCells:(int)num;
- (NSValueArray *) arrayOfCellsInLayer: (int) zloc;
- (NSValueArray *) squareArrayOfCellsAtX: (int) xloc Y: (int) yloc
            Z: (int) zloc size: (int) size layers: (int) nlayers;
- (BOOL) isCellFiringAtPosition: (SIMPosition) pos;
- (BOOL) isCellFiringAtX: (int) x Y: (int) y Z: (int) z;
- histogramOfConnectionsFromType:(NSString *)fromType
    toType:(NSString *)toType;
- (int)countOfConnectionsFromCell:(SIMPosition *)cellValue
    toTypes:(NSArray *)toTypes;
- (NSCountedSet *)histogramOfConnectionsFromLayer: fromLayerKey toLayer: toLayerKey;
- (NSCountedSet *) histogramOfConnectionsFromCell: (SIMPosition) aCell toLayer: toLayerKey;
- (int) countOfConnectionsFromCell: (SIMPosition) aCell
        toLayer: (int) layer;
- (void) printConnectionsByLayer;
- (NSString *) listConnectionsFromLayer: fromLayerKey toLayer: toLayerKey;
- (NSString *) listConnectionsFromCell: (SIMPosition) aCell
        toLayer: layerKey;
- (int)indexForLayerWithKey:(NSString *)key;
@end

@interface SIMNetwork (SIMRemoteNetwork)

- (bycopy NSData *)valuesForIntrinsicChannelVariable:(in NSString *)varName withType:(bycopy NSString *)type forLayer:(in int)layer;
- (bycopy NSData *)valuesForInputChannelVariable:(in NSString *)varName withType:(bycopy NSString *)type forLayer:(in int)layer;
- (bycopy NSData *)valuesForCellCompartmentVariable:(in NSString *)varName withType:(bycopy NSString *)type forLayer:(in int)layer;
@end


@interface SIMNetwork (SIMNetworkStatistics)


- (id)valueOfVariable:(int)variable atIndex:(int)model modelType:(SIMModelType)type position:(SIMPosition *)pos;
- (void)setValue:(NSNumber *)value ofVariable:(int)variable atIndex:(int)model modelType:(SIMModelType)type position:(SIMPosition *)pos;

- valueForCellCompartment:(int)cell atIndex:(int)variable forCell:(SIMPosition *)pos;
- valueForCellCompartmentVariable:(NSString *)varName forCell:(SIMPosition *)pos;

- valueForIntrinsicChannelVariable:(NSString *)varName forCell:(SIMPosition *)pos;
- valueForIntrinsicChannel:(int)channel atIndex:(int)variable forCell:(SIMPosition *)pos;
- valueForInputChannelVariable:(NSString *)varName forCell:(SIMPosition *)pos;
- valueForInputChannel:(int)channel atIndex:(int)variable forCell:(SIMPosition *)pos;

- (void)setValue:(id)value forCellCompartmentVariable:(NSString *)varName forCell:(SIMPosition *)pos;
- (void)setValue:(id)value forIntrinsicChannelVariable:(NSString *)varName forCell:(SIMPosition *)pos;
- (void)setValue:(id)value forInputChannelVariable:(NSString *)varName forCell:(SIMPosition *)pos;

/*
- (NSData *)getSwappedValuesForChannelModel:(int)channel atIndex:(int)variable forCells:(NSArray *)positions;
- (NSData *)getSwappedValuesForCellModel:(int)cell atIndex:(int)variable forCells:(NSArray *)positions;
- (NSData *)getValuesForCellModel:(int)cell atIndex:(int)variable forCells:(NSArray *)positions;
- (NSData *)getValuesForChannelModel:(int)channel atIndex:(int)variable forCells:(NSArray *)positions;
*/


- (float)meanFiringRateForLayer:(NSString *)layerName;
- (float)meanFiringRateForLayerAtIndex:(int)l;

- (float)meanComputationalLoadForLayer:(NSString *)layerName;
- (float)meanComputationalLoadForLayerAtIndex:(int)l;

- (float) totalComputationalLoad;
- (float) computationalLoadForLayer:(int)l;

- (float)totalWeightOfInputsForCell:(SIMPosition)aCell;
- (float)totalNumberOfInputsForCell:(SIMPosition)aCell;
- (float)totalLatencyOfInputsForCell:(SIMPosition)aCell;

- (float)averageNumberOfInputsForType:(NSString *)type;
- (float)averageWeightOfInputsForType:(NSString *)type;
- (float)averageLatencyOfInputsForType:(NSString *)type;

- (float)averageNumberOfInputsForType:(NSString *)type fromType:(NSString *)fromType;
- (float)averageNumberOfInputsForType:(NSString *)type fromTypes:(NSArray *)types;

- (float)averageWeightOfInputsForType:(NSString *)type fromType:(NSString *)fromType;
- (float)averageWeightOfInputsForType:(NSString *)type fromTypes:(NSArray *)types;

- (float)averageLatencyOfInputsForType:(NSString *)type fromType:(NSString *)fromType;
- (float)averageLatencyOfInputsForType:(NSString *)type fromTypes:(NSArray *)types;

- (float)totalNumberOfInputsForType:(NSString *)type;
- (float)totalWeightOfInputsForType:(NSString *)type;
- (float)totalLatencyOfInputsForType:(NSString *)type;

- (float)totalNumberOfInputsForType:(NSString *)type fromType:(NSString *)fromType;
- (float)totalNumberOfInputsForType:(NSString *)type fromTypes:(NSArray *)types;

- (float)totalWeightOfInputsForType:(NSString *)type fromType:(NSString *)fromType;
- (float)totalWeightOfInputsForType:(NSString *)type fromTypes:(NSArray *)types;

- (float)totalLatencyOfInputsForType:(NSString *)type fromType:(NSString *)fromType;
- (float)totalLatencyOfInputsForType:(NSString *)type fromTypes:(NSArray *)types;

- (int) countOfSpikingCellsInLayer: (int) l;
- (int) countOfInteractingCellsInLayer: (int) l;

- (int)countOfSpikingCellsWithType:(NSString *)type;
- (int) countOfSpikingCellsInRegionOfLayer: (int) l
    xOffset:(int)xoff yOffset:(int)yoff
    xWidth:(int)numColumns yWidth:(int)numRows
    withType:(NSString *)type;
- (float) localFieldPotentialForCell:(SIMPosition *)pos radius:(int)r;
- (NSData *) localFieldPotentialForCells:(NSArray *)positions  radius:(int)r;
- (NSData *) inputChannelCurrent:(NSString *)key forCompartment:(int)index forCells:(NSArray *)positions;
- (float) inputChannelCurrent:(NSString *)key forCompartment:(int)index atPosition:(SIMPosition *)pos;
- (NSData *) intrinsicChannelCurrent:(NSString *)key forCompartment:(int)index forCells:(NSArray *)positions;
- (float) intrinsicChannelCurrent:(NSString *)key forCompartment:(int)index atPosition:(SIMPosition *)pos;

- (float) averageMembranePotentialAroundCell:(SIMPosition *)pos radius:(int)r;
- (NSData *) averageMembranePotentialAroundCells:(NSArray *)positions radius:(int)r;
- (float) populationActivityForLayer:(int)l;
- (NSString *)recordFromCells:(NSValueArray *)positions
    event: (int) event startCode: (int) start
    lastEventTime: (int *) lastTime
    sync: (int) sync code: (int) code;
- (NSArray *)arrayOfRandomCells:(int)num;
- (NSValueArray *) arrayOfCellsInLayer: (int) zloc;
- (NSValueArray *) arrayOfCellsInLayer:(int)k rows:(int)rows columns:(int)cols;
- (NSValueArray *) arrayOfCells:(int)num inLayer:(int)k;
- (NSValueArray *) squareArrayOfCellsAtPosition:(SIMPosition *)pos size:(int)size;
- (NSValueArray *) squareArrayOfCellsAtX: (int) xloc Y: (int) yloc
            Z: (int) zloc size: (int) size layers: (int) nlayers;
- (BOOL) isCellFiringAtPosition: (SIMPosition) pos;
- (BOOL) isCellFiringAtX: (int) x Y: (int) y Z: (int) z;
- (NSCountedSet *)histogramOfConnectionsFromType:(NSString *)fromType
    toType:(NSString *)toType;
- (int)countOfConnectionsFromCell:(SIMPosition)cellValue
    toTypes:(NSArray *)toTypes;
- (NSCountedSet *)histogramOfConnectionsFromLayer: fromLayerKey toLayer: toLayerKey;
- (NSCountedSet *) histogramOfConnectionsFromCell: (SIMPosition) aCell toLayer: toLayerKey;
- (int) countOfConnectionsFromCell: (SIMPosition) aCell
        toLayer: (int) layer;
- (void) printConnectionsByLayer;
- (NSString *) listConnectionsFromLayer: fromLayerKey toLayer: toLayerKey;
- (NSString *) listConnectionsFromCell: (SIMPosition) aCell
        toLayer: layerKey;
@end


@interface SIMNetwork (SIMNetworkStatisticsPrivate)
- (float) _populationActivityInRegionOfLayer: (int) l
    xOffset:(int)xoff yOffset:(int)yoff
    xWidth:(int)numColumns yWidth:(int)numRows;
@end


