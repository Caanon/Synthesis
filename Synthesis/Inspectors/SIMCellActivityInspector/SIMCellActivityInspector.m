/* SIMCellActivityInspector.m created by hill on Wed 20-Feb-2002 */

#import "SIMCellActivityInspector.h"
#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisCore/SIMNetworkInfo.h>
#import <SynthesisCore/SIMNetworkTopology.h>
#import <SynthesisCore/SIMNetworkStatistics.h>
#import <Desiderata/SIMHistogram.h>

#define DISPLAY_OTHER 0
#define DISPLAY_STATE 1
#define DISPLAY_POTENTIAL 2
#define DISPLAY_INPUT 3

#define MODEL_CELL 0
#define MODEL_INTRINSIC_CHANNEL 1
#define MODEL_INPUT_CHANNEL 2

#define min(x,y) ((x)<(y) ? (x):(y))
#define max(x,y) ((x)>(y) ? (x):(y))

@implementation SIMCellActivityInspector

- init
{
    [super init];
    layerIndex = 0;
    displayMode = DISPLAY_STATE;
    variableIndex = 0;
    layerIndex = 0;
    modelIndex = 0;
    buffer = nil;
    times = nil;
    timeWindow = 1000;
    sampleInterval = 100;

    return self;
}

- (void)display
{
    float dt = [object dt];


    if(fmod([object time],sampleInterval) == 0.0){
        NSRange plotRange;
        int l = [buffer count] - timeWindow/dt;
        plotRange.location = max(0,l);
        plotRange.length = min(timeWindow/dt,[buffer count]);
        
        NSValueArray *tempBuffer = [buffer valueArrayFromRange:plotRange];
        SIMHistogram *histogram = [SIMHistogram histogramWithData:tempBuffer numberOfBins:numberOfBins rangeStart:minValue end:maxValue];
        
        [plotView plotValues:[times valueArrayFromRange:plotRange] :tempBuffer];
        [histogramView setPlotStyle:@"FilledBar"];
        [histogramView plotValues:[histogram rangeValues] :[histogram binValues]];
    }
    
    if([drawer state] == NSDrawerOpenState){
        NSData *displayData;
    
        switch (displayMode){
            case DISPLAY_STATE:
                [miniActivityView setMin:0.0 andMax:3.0];
				displayData = [(SIMNetwork *) object swappedValuesForCellCompartment:modelIndex atIndex:CELL_STATE_INDEX withType:type forLayer:layerIndex];
                break;
            case DISPLAY_POTENTIAL:
                [miniActivityView setMin:-90.0 andMax:30.0];
				displayData = [(SIMNetwork *) object swappedValuesForCellCompartment:modelIndex atIndex:CELL_POTENTIAL_INDEX withType:type forLayer:layerIndex];
                break;
            case DISPLAY_INPUT:
                [miniActivityView setAutoScale:YES];
                displayData = [(SIMNetwork *) object swappedSummedInputChannelCurrentsForLayer:layerIndex];
                break;
            case DISPLAY_OTHER:
                [miniActivityView setAutoScale:YES];
                if (modelType == MODEL_INPUT_CHANNEL)
                    displayData = [(SIMNetwork *) object swappedValuesForInputChannel:modelIndex atIndex:variableIndex withType:type forLayer:layerIndex];
                else
                if (modelType == MODEL_INTRINSIC_CHANNEL)
                    displayData = [(SIMNetwork *) object swappedValuesForIntrinsicChannel:modelIndex atIndex:variableIndex withType:type forLayer:layerIndex];
                else
                    displayData = [(SIMNetwork *) object swappedValuesForCellCompartment:modelIndex atIndex:variableIndex withType:type forLayer:layerIndex];
                break;
            default:
                return;
        }
        [miniActivityView setData:displayData byteOrder:[object hostByteOrder]];
        [miniActivityView setNeedsDisplay:YES];
    }
}

- (void)gatherData
{
    NSPoint selectedPoint;
    float activity,time,dt;
    int radius = 5;

    selectedPoint = [miniActivityView selectedPoint];

    if((aCell.x != selectedPoint.x) || (aCell.y != selectedPoint.y)) [self clearData:self];

    aCell.x = selectedPoint.x;
    aCell.y = selectedPoint.y;
    aCell.z = layerIndex;
    
    switch (displayMode){
        case DISPLAY_STATE:
            activity = [object meanFiringRateForLayerAtIndex:layerIndex];
            break;
        case DISPLAY_POTENTIAL:
            activity = [object averageMembranePotentialAroundCell:&aCell radius:radius];
            break;
        case DISPLAY_INPUT:
            activity = [object localFieldPotentialForCell:&aCell radius:radius];
            break;
        case DISPLAY_OTHER:
            if (modelType == MODEL_INPUT_CHANNEL)
                activity = [[object valueForInputChannel:modelIndex atIndex:variableIndex forCell:&aCell] floatValue];
            else
            if (modelType == MODEL_INTRINSIC_CHANNEL)
                activity = [[object valueForIntrinsicChannel:modelIndex atIndex:variableIndex forCell:&aCell] floatValue];
            else
                activity = [[object valueForCellCompartment:modelIndex atIndex:variableIndex forCell:&aCell] floatValue];
            break;
        default:
            return;
    }

    time = [object time];
    [buffer addValue:&activity];
    [times addValue:&time];

    [self display];
}

- (void)clearData:sender
{
    [buffer removeAllObjects];
    [times removeAllObjects];
}

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)num inMatrix:(NSMatrix *)matrix
{
    NSEnumerator	*enumerator;
    id myObject,myCell;
    int x = 0;
    
    layer = [layerPopup titleOfSelectedItem];
    type = [[browser selectedCellInColumn:0] stringValue];
    modelType = [browser selectedRowInColumn:1];
    if(modelType < 0)modelType = 0;
    selectedModel = [[browser selectedCellInColumn:2] stringValue];
    
    switch(num){
        case 0:
            enumerator = [[[object allTypesForLayer:layer] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
            break;
        case 1:
            enumerator = [[NSArray arrayWithObjects:@"CELLS",@"INTRINSIC CHANNELS",@"INPUT CHANNELS",nil] objectEnumerator];
            break;
        case 2:            
            if(modelType == MODEL_CELL) 
                enumerator = [[[object allCellsForType:type inLayer:layer] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
            else 
            if(modelType == MODEL_INTRINSIC_CHANNEL)
                enumerator = [[[object allIntrinsicChannelsForType:type inLayer:layer] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
            else 
                enumerator = [[[object allInputChannelsForType:type inLayer:layer] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
            break;
        case 3:
            if(modelType == MODEL_CELL)
                enumerator = [[[object allVariablesForCell:selectedModel inType:type layer:layer]
                                sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
            else if(modelType == MODEL_INTRINSIC_CHANNEL)
                enumerator = [[[object allVariablesForIntrinsicChannel:selectedModel inType:type layer:layer] 
                                sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
            else
                enumerator = [[[object allVariablesForInputChannel:selectedModel inType:type layer:layer] 
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
        layerIndex = (int)[object indexForLayerWithKey:layer];
        numRows = (int)[object numRowsInLayer:layerIndex];
        numColumns = (int)[object numColumnsInLayer:layerIndex];
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
        [advancedButton setState:NSOnState];
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
    
    timeWindow = [timeWindowField intValue];
    sampleInterval = [sampleIntervalField intValue];
    numberOfBins = [numberOfBinsField intValue];
    minValue = [minValueField doubleValue];
    maxValue = [maxValueField doubleValue];
    
    type = [[browser selectedCellInColumn:0] stringValue];
    modelType = [browser selectedRowInColumn:1];
    selectedModel = [[browser selectedCellInColumn:2] stringValue];
    variable = [[browser selectedCellInColumn:3] stringValue];
        
    if(layer && type && selectedModel && variable){
        if(modelType == MODEL_INPUT_CHANNEL){
            modelIndex = [object indexForInputChannel:selectedModel inType:type layer:layer];
            variableIndex = [object indexForInputChannelVariable:variable inModel:selectedModel inType:type layer:layer];
        }
        else if(modelType == MODEL_INTRINSIC_CHANNEL){
            modelIndex = [object indexForIntrinsicChannel:selectedModel inType:type layer:layer];
            variableIndex = [object indexForIntrinsicChannelVariable:variable inModel:selectedModel inType:type layer:layer];
        }
        else {
            modelIndex = [object indexForCell:selectedModel inType:type layer:layer];        
            variableIndex = [object indexForCellVariable:variable inModel:selectedModel inType:type layer:layer];
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
    [layerPopup removeAllItems];
    [layerPopup addItemsWithTitles:[[anObject allLayers] sortedArrayUsingSelector:@selector(compare:)]];
    numRows = (int)[(SIMNetwork *)anObject numRowsInLayer:layerIndex];
    numColumns = (int)[(SIMNetwork *)anObject numColumnsInLayer:layerIndex];
    [miniActivityView initSize:numColumns :numRows];

    if(!buffer)buffer = [[NSMutableValueArray valueArrayWithObjCType:@encode(float)] retain];
    if(!times)times = [[NSMutableValueArray valueArrayWithObjCType:@encode(float)] retain];

    [self clearData:self];

//    radius = [radiusField intValue];
//    xPos = [xPosField intValue];
//    yPos = [yPosField intValue];
    timeWindow = [timeWindowField intValue];
    sampleInterval = [sampleIntervalField intValue];

    [plotView removeAllPlots:self];

    [plotView setAutoScale:YES];

    [histogramView removeAllPlots:self];
    [histogramView setAutoScale:YES];
    [histogramView setMainTitle:@"Histogram"];
    [histogramView setXTitle:@"Value"];
    [histogramView setYTitle:@"Count"];


    [super inspect:anObject];
    [browser loadColumnZero];

}

- (void)registerForNotifications
{
    [super registerForNotifications];
    [server addClient:self forNotificationName:SIMNetworkDidUpdateNotification
        selector:@selector(gatherData) object:[server network]];
}

- (void)unregisterForNotifications
{
    [super unregisterForNotifications];
}

- copyWithZone:(NSZone *)zone
{
    SIMCellActivityInspector *inspectorCopy = [super copyWithZone:zone];
	inspectorCopy->layerIndex = layerIndex;
	inspectorCopy->variableIndex = variableIndex;
	inspectorCopy->numRows = numRows;
	inspectorCopy->numColumns = numColumns;
	[inspectorCopy->miniActivityView initSize:numRows :numColumns];
    return inspectorCopy;
}


@end
