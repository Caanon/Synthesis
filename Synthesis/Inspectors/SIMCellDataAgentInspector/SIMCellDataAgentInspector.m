/* SIMCellDataAgentInspector.m created by hill on Wed 20-Feb-2002 */

#import "SIMCellDataAgentInspector.h"
#import <SynthesisCore/SIMAgent.h>
#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisCore/SIMNetworkInfo.h>
#import <SynthesisCore/SIMNetworkTopology.h>
#import <SynthesisCore/SIMNetworkStatistics.h>

#define DISPLAY_OTHER 0
#define DISPLAY_STATE 1
#define DISPLAY_POTENTIAL 2
#define DISPLAY_INPUT 3

#define MODEL_CELL 0
#define MODEL_CHANNEL 1

#define min(x,y) ((x)<(y) ? (x):(y))
#define max(x,y) ((x)>(y) ? (x):(y))

@implementation SIMCellDataAgentInspector

- init
{
    [super init];
    layerIndex = 0;
    displayMode = DISPLAY_STATE;
    variableIndex = 0;
    layerIndex = 0;
    modelIndex = 0;
    //buffer = nil;
    //times = nil;

    return self;
}

- (void)display
{
    NSValueArray *newData,*newTimes;
    NSPoint selectedPoint;
    selectedPoint = [miniActivityView selectedPoint];

    if((aCell.x != selectedPoint.x) || (aCell.y != selectedPoint.y)) [self clearData:self];

    aCell.x = selectedPoint.x;
    aCell.y = selectedPoint.y;
    aCell.z = layerIndex;
            
    newTimes = [object times];
    newData = [object dataBuffer];
    
    [plotView plotValues:newTimes :newData];
    
    if([drawer state] == NSDrawerOpenState){
        NSData *displayData;
    
        switch (displayMode){
            case DISPLAY_STATE:
                [miniActivityView setMin:0.0 andMax:3.0];
				displayData = [(SIMNetwork *) network swappedValuesForCellCompartment:modelIndex atIndex:CELL_STATE_INDEX withType:type forLayer:layerIndex];
                break;
            case DISPLAY_POTENTIAL:
                [miniActivityView setMin:-90.0 andMax:30.0];
				displayData = [(SIMNetwork *) network swappedValuesForCellCompartment:modelIndex atIndex:CELL_POTENTIAL_INDEX withType:type forLayer:layerIndex];
                break;
            case DISPLAY_INPUT:
                [miniActivityView setAutoScale:YES];
                displayData = [network swappedSummedInputChannelCurrentsForLayer:layerIndex];
                break;
            case DISPLAY_OTHER:
                [miniActivityView setAutoScale:YES];
                if (modelType == MODEL_CHANNEL)
                    displayData = [network swappedValuesForInputChannel:modelIndex atIndex:variableIndex withType:type forLayer:layerIndex];
                else
                    displayData = [network swappedValuesForCellCompartment:modelIndex atIndex:variableIndex withType:type forLayer:layerIndex];
                break;
            default:
                return;
        }
        [miniActivityView setData:displayData byteOrder:[network hostByteOrder]];
        [miniActivityView setNeedsDisplay:YES];
    }
}

- (void)clearData:sender
{
    //[buffer removeAllObjects];
    //[times removeAllObjects];
}

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)num inMatrix:(NSMatrix *)matrix
{
    NSEnumerator	*enumerator = nil;
    id myObject,myCell;
    int x = 0;
    
    layer = [layerPopup titleOfSelectedItem];
    type = [[browser selectedCellInColumn:0] stringValue];
    modelType = [browser selectedRowInColumn:1];
    if(modelType < 0)modelType = 0;
    selectedModel = [[browser selectedCellInColumn:2] stringValue];
    
    switch(num){
        case 0:
            enumerator = [[[network allTypesForLayer:layer] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
            break;
        case 1:
            enumerator = [[NSArray arrayWithObjects:@"CELLS",@"CHANNELS",nil] objectEnumerator];
            break;
        case 2:            
            if(modelType == MODEL_CELL) 
                enumerator = [[[network allCellsForType:type inLayer:layer] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
            else 
                enumerator = [[[network allInputChannelsForType:type inLayer:layer] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
            break;
        case 3:
            if(modelType == MODEL_CELL)
                enumerator = [[[network allVariablesForCell:selectedModel inType:type layer:layer]
                                sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
            else enumerator = [[[network allVariablesForInputChannel:selectedModel inType:type layer:layer] 
                                sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
            break;
        default:
            //column = -1;
            break;
    }

    while ((myObject = [enumerator nextObject])){
        // Build browser entries excluding certain keys we would like to remain invisible
            [matrix addRow];
            myCell = [matrix cellAtRow:x++ column:0];
            [myCell setStringValue:[(NSObject *)myObject description]];
            if(num == 3)[myCell setLeaf:YES];
            else [myCell setLoaded:NO];
    }
}

- (void)ok:sender
{
    if(sender == layerPopup){
        layer = [layerPopup titleOfSelectedItem];
        layerIndex = (int)[network indexForLayerWithKey:layer];
        numRows = (int)[network numRowsInLayer:layerIndex];
        numColumns = (int)[network numColumnsInLayer:layerIndex];
        [miniActivityView initSize:numColumns :numRows];
        browserIndex0 = [browser selectedRowInColumn:0];
        browserIndex1 = [browser selectedRowInColumn:1];
        browserIndex2 = [browser selectedRowInColumn:2];
        browserIndex3 = [browser selectedRowInColumn:3];
        [browser loadColumnZero];
        [browser selectRow:browserIndex0 inColumn:0];
        [browser selectRow:browserIndex1 inColumn:1];
        [browser selectRow:browserIndex2 inColumn:2];
        [browser selectRow:browserIndex3 inColumn:3];
        [self clearData:self];
    }
    if(sender == variablePopup){
        displayMode = (int)[[sender selectedItem] tag];
        if(displayMode == DISPLAY_OTHER) [drawer open:self];
        [self clearData:self];
    }
    if(sender == advancedButton){
        if([drawer state] == NSDrawerClosedState){
            if(displayMode != DISPLAY_OTHER){
                [variablePopup selectItemWithTitle:@"Other"];
                displayMode = DISPLAY_OTHER;
                [self clearData:self];
            }
        }
        [drawer toggle:sender];
    }
    
    type = [[browser selectedCellInColumn:0] stringValue];
    modelType = [browser selectedRowInColumn:1];
    selectedModel = [[browser selectedCellInColumn:2] stringValue];
    variable = [[browser selectedCellInColumn:3] stringValue];
        
    if(layer && type && selectedModel && variable){
        if(modelType == MODEL_CHANNEL){
            modelIndex = [network indexForInputChannel:selectedModel inType:type layer:layer];
            variableIndex = [network indexForInputChannelVariable:variable inModel:selectedModel inType:type layer:layer];
        }
        else {
            modelIndex = [network indexForCell:selectedModel inType:type layer:layer];        
            variableIndex = [network indexForCellVariable:variable inModel:selectedModel inType:type layer:layer];
        }
    }

    switch (displayMode){
        case DISPLAY_STATE:
            [plotView setMainTitle:@"Mean firing rate"];
            [plotView setXTitle:@"Time (ms)"];
            [plotView setYTitle:@"spikes/s"];
            break;
        case DISPLAY_POTENTIAL:
            [plotView setMainTitle:@"Mean membrane potential"];
            [plotView setXTitle:@"Time (ms)"];
            [plotView setYTitle:@"mV"];
            break;
        case DISPLAY_INPUT:
            [plotView setMainTitle:@"Mean synaptic input"];
            [plotView setXTitle:@"Time (ms)"];
            [plotView setYTitle:@"Current"];
            break;
        case DISPLAY_OTHER:
            [plotView setMainTitle:variable];
            [plotView setXTitle:@"Time (ms)"];
            [plotView setYTitle:@""];
            break;
        default:
            return;
    }
    [plotView display];

    [self display];
}


- saveActivityData:sender
{
    return self;
}


- (void)inspect:anObject
{

    [anObject startAgent];
    network = [anObject network];
    
    [layerPopup removeAllItems];
    [layerPopup addItemsWithTitles:[[network allLayers] sortedArrayUsingSelector:@selector(compare:)]];    
    
    numRows = (int)[network numRowsInLayer:layerIndex];
    numColumns = (int)[network numColumnsInLayer:layerIndex];
    [miniActivityView initSize:numColumns :numRows];

    //if(!buffer)buffer = [[NSMutableValueArray valueArrayWithObjCType:@encode(float)] retain];
    //if(!times)times = [[NSMutableValueArray valueArrayWithObjCType:@encode(float)] retain];

    [self clearData:self];

    [plotView removeAllPlots:self];

    [plotView setAutoScale:YES];

    [super inspect:anObject];
    [browser loadColumnZero];
}

- (void)registerForNotifications
{
    [super registerForNotifications];
    [object addClient:self forNotificationName:SIMNetworkUpdateIntervalNotification
        selector:@selector(display) object:object];
}

- (void)unregisterForNotifications
{
    [super unregisterForNotifications];
}

- copyWithZone:(NSZone *)zone
{
    SIMCellDataAgentInspector *inspectorCopy = [super copyWithZone:zone];
	inspectorCopy->layerIndex = layerIndex;
	inspectorCopy->variableIndex = variableIndex;
	inspectorCopy->numRows = numRows;
	inspectorCopy->numColumns = numColumns;
	[inspectorCopy->miniActivityView initSize:numRows :numColumns];
    return inspectorCopy;
}


@end
