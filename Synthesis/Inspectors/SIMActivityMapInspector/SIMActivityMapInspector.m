/* SIMActivityMapInspector.m created by hill on Mon 19-Aug-1997 */

#import "SIMActivityMapInspector.h"
#import <Desiderata/NSValueArray.h>
#import <SynthesisCore/SIMNetworkStatistics.h>

#define DISPLAY_OTHER -1
#define DISPLAY_TYPE 0
#define DISPLAY_STATE 1
#define DISPLAY_POTENTIAL 2
#define DISPLAY_INPUT 3

#define MODEL_CELL 0
#define MODEL_INTRINSIC_CHANNEL 1
#define MODEL_INPUT_CHANNEL 2

@implementation SIMActivityMapInspector

- (void)display
{
    NSData *displayData = [[object swappedCellDataAtIndex:variableIndex forCells:cellArray] retain];
    NSSwappedFloat *activityBytes = (void *)[activityData mutableBytes];
    NSSwappedFloat *displayBytes = (void *)[displayData bytes];
    int i,time = [object time] * (1/(float)[object dt]);
    
    for(i = 0; i < numCells; i++){
        activityBytes[i*duration+(time % duration)] = displayBytes[i];
    }
    
    [activityView setAutoScale:YES];
    [activityView setData:activityData byteOrder:[object hostByteOrder]];
    [activityView setNeedsDisplay:YES];
    [displayData release];
}

- (void)ok:sender
{
    if(sender == layerPopup){
        layer = [layerPopup titleOfSelectedItem];
        layerIndex = (int)[object indexForLayerWithKey:layer];
        numRows = (int)[object numRowsInLayer:layerIndex];
        numColumns = (int)[object numColumnsInLayer:layerIndex];
        [activityView initSize:numColumns :numRows];
        browserIndex0 = [browser selectedRowInColumn:0];
        browserIndex1 = [browser selectedRowInColumn:1];
        browserIndex2 = [browser selectedRowInColumn:2];
        browserIndex3 = [browser selectedRowInColumn:3];
        [browser loadColumnZero];
        [browser selectRow:browserIndex0 inColumn:0];
        [browser selectRow:browserIndex1 inColumn:1];
        [browser selectRow:browserIndex2 inColumn:2];
        [browser selectRow:browserIndex3 inColumn:3];
    }
    if(sender == variablePopup){
        displayMode = (int)[[sender selectedItem] tag];
        if(displayMode == DISPLAY_OTHER) [selectVariableDrawer open:self];
    }
    if(sender == selectVariableButton){
        if([selectVariableDrawer state] == NSDrawerClosedState){
            [variablePopup selectItemWithTitle:@"Other"];
            displayMode = DISPLAY_OTHER;
        }
        [selectVariableDrawer toggle:sender];
    }

    if(sender == durationField){
        duration = [sender intValue];
    }
    
    if(sender == numCellsField){
        numCells = [sender intValue];
    }

    if(sender == autoScaleSwitch){
        BOOL state = ([autoScaleSwitch state] == NSOnState);
        [minField setEnabled:!state];
        [maxField setEnabled:!state];
        [activityView setAutoScale:state];
    }
    if((sender == minField) || (sender == maxField)){
        [autoScaleSwitch setState:NSOffState];
    }
    
    type = [[browser selectedCellInColumn:0] stringValue];
    modelType = [browser selectedRowInColumn:1];
    selectedModel = [[browser selectedCellInColumn:2] stringValue];
    variable = [[browser selectedCellInColumn:3] stringValue];
    numberOfBins = [numberOfBinsField intValue];
    
    [histogram setNumberOfBins:numberOfBins];
        
    if(layer && type && selectedModel && variable){
        if(modelType == MODEL_INTRINSIC_CHANNEL){
            modelIndex = [object indexForIntrinsicChannel:selectedModel inType:type layer:layer];
            variableIndex = [object indexForIntrinsicChannelVariable:variable inModel:selectedModel inType:type layer:layer];
        }
        else
        if(modelType == MODEL_INPUT_CHANNEL){
            modelIndex = [object indexForInputChannel:selectedModel inType:type layer:layer];
            variableIndex = [object indexForInputChannelVariable:variable inModel:selectedModel inType:type layer:layer];
        }
        else {
            modelIndex = [object indexForCell:selectedModel inType:type layer:layer];        
            variableIndex = [object indexForCellVariable:variable inModel:selectedModel inType:type layer:layer];
        }
    }

    if(cellArray)[cellArray autorelease];
    cellArray = [[object arrayOfCells:numCells inLayer:layerIndex ] retain];
    if(activityData)[activityData release];
    activityData = [[NSMutableData dataWithLength:sizeof(NSSwappedFloat)*duration*[cellArray count]] retain];
    [activityView initSize:duration :[cellArray count]];

    [self display];
}

- saveActivityViewAsTIFF:sender
{
    static int count = 0;
	int result;
    NSSavePanel *sPanel = [NSSavePanel savePanel];
	
    if(!savePath)savePath = [NSHomeDirectory() retain];

    [sPanel setRequiredFileType:@"tiff"];
    result = [sPanel runModalForDirectory:savePath
        file:[NSString stringWithFormat:@"Snapshot%d.tiff",count++]];
	if (result == NSOKButton) {
        [activityView saveTIFFToFile:[sPanel filename]];
        [savePath autorelease];
        savePath = [[sPanel directory] retain];
	}
	return self;
}


- (void)inspect:anObject
{
    duration = 250; //timesteps
    numCells = 10;
    variableIndex = 0;
    layerIndex = 0;
    
    [layerPopup removeAllItems];
    [layerPopup addItemsWithTitles:[anObject layerKeys]];
    [layerPopup selectItemAtIndex:layerIndex];
    
    if(cellArray)[cellArray autorelease];
    cellArray = [[anObject arrayOfCells:numCells inLayer:layerIndex ] retain];
    
    if(activityData)[activityData release];
    activityData = [[NSMutableData dataWithLength:sizeof(NSSwappedFloat)*duration*[cellArray count]] retain];
    
    [activityView initSize:duration :[cellArray count]];
    [activityView setPreserveAspectRatio:NO];
    [activityView setColorPaletteFromColorListWithName:@"Membrane Potential"];
    [activityView setAutoScale:YES];
    
    [super inspect:anObject];
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


- (void)registerForNotifications
{
    [super registerForNotifications];
    [server addClient:self forNotificationName:SIMNetworkDidUpdateNotification
        selector:@selector(display) object:[server network]];
}

- (void)unregisterForNotifications
{
    [super unregisterForNotifications];
}

- copyWithZone:(NSZone *)zone
{
    SIMActivityMapInspector *inspectorCopy = [super copyWithZone:zone];
	inspectorCopy->layerIndex = layerIndex;
	inspectorCopy->variableIndex = variableIndex;
        inspectorCopy->duration = duration;
        inspectorCopy->numCells = numCells;
        [inspectorCopy->activityView initSize:duration :numCells];

    return inspectorCopy;
}


@end
