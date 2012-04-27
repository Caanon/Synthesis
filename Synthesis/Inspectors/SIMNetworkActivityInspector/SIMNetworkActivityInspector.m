/* SIMNetworkActivityInspector.m created by hill on Mon 17-Mar-1997 */

#import "SIMNetworkActivityInspector.h"
#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisCore/SIMNetworkInfo.h>
#import <SynthesisCore/SIMNetworkTopology.h>
#import <SynthesisCore/SIMNetworkStatistics.h>

#define DISPLAY_OTHER -1
#define DISPLAY_TYPE 0
#define DISPLAY_STATE 1
#define DISPLAY_POTENTIAL 2
#define DISPLAY_INPUT 3

#define MODEL_CELL 0
#define MODEL_INTRINSIC_CHANNEL 1
#define MODEL_INPUT_CHANNEL 2

@implementation SIMNetworkActivityInspector

- init
{
    [super init];
    layerIndex = 0;
    displayMode = DISPLAY_STATE;
    variableIndex = 1;
    layerIndex = 0;
    modelIndex = 0;
    //
    
    histogram = [[SIMHistogram histogramWithNumberOfBins:30 rangeStart:0 end:1] retain];
    
    frameIndex = 0;
    
    //myMovie = [SIMMutableMovie emptyMovie];
    //[myMovieView setMovie:myMovie];
    //[myMovieView showController:YES adjustingSize:YES];

    return self;
}

- (void)display
{
    NSData *displayData = nil;

    if([autoScaleSwitch state] == NSOnState){
        [activityView setAutoScale:YES];
    }
    else [activityView setMin:[minField floatValue] andMax:[maxField floatValue]];

    switch (displayMode){
        case DISPLAY_TYPE:
           displayData = [(SIMNetwork *) object typeDataForLayer:layerIndex];
           break;
        case DISPLAY_STATE:
            displayData = [(SIMNetwork *) object swappedValuesForCellCompartment:modelIndex atIndex:CELL_STATE_INDEX withType:type forLayer:layerIndex];
            break;
        case DISPLAY_POTENTIAL:
            displayData = [(SIMNetwork *) object swappedValuesForCellCompartment:modelIndex atIndex:CELL_POTENTIAL_INDEX withType:type forLayer:layerIndex];
            break;
        case DISPLAY_INPUT:
            displayData = [(SIMNetwork *) object swappedSummedInputChannelCurrentsForLayer:layerIndex];
            break;
        case DISPLAY_OTHER:
            if (modelType == MODEL_INTRINSIC_CHANNEL)
                displayData = [(SIMNetwork *) object swappedValuesForIntrinsicChannel:modelIndex atIndex:variableIndex withType:type forLayer:layerIndex];
            else
            if (modelType == MODEL_INPUT_CHANNEL)
                displayData = [(SIMNetwork *) object swappedValuesForInputChannel:modelIndex atIndex:variableIndex withType:type forLayer:layerIndex];
            else
                displayData = [(SIMNetwork *) object swappedValuesForCellCompartment:modelIndex atIndex:variableIndex withType:type forLayer:layerIndex];
            break;
        default:
            break;
    }
    [activityView setData:displayData byteOrder:[object hostByteOrder]];
    [activityView setNeedsDisplay:YES];
    

    if([autoScaleSwitch state] == NSOnState){
        [minField setFloatValue:[activityView min]];
        [maxField setFloatValue:[activityView max]];
    }

    if([histogramDrawer state] == NSDrawerOpenState)
    {
        NSSwappedFloat 	*swappedData;
        int i,count;
        
        [histogram clearBins];
        [histogram setRangeStart:[minField doubleValue] end:[maxField doubleValue]];        
        swappedData = (NSSwappedFloat *)[displayData bytes];
        count = [displayData length]/sizeof(NSSwappedFloat);
        for(i = 0; i < count; i++){
            double val =  (double)NSConvertSwappedFloatToHost(swappedData[i]);
            [histogram addDouble:val];
        }
        [histogramView setPlotStyle:@"FilledBar"];
        [histogramView plotValues:[histogram rangeValues] :[histogram binValues]];
    }  
    


    //NSImage *myImage = [[NSImage alloc] initWithSize:[myMovieView frame].size];
    //[myImage setScalesWhenResized:YES];
    //[myImage addRepresentation:[activityView bitmapImageRep]];
    
    //[myMovie insertImage:myImage  sourceStartTime:[object time]*60
    //                               sourceDurationTime:60];

    //[myMovieView gotoEnd:nil];

    if(saveImageFlag)[activityView saveTIFFToFile:[NSString stringWithFormat:@"/tmp/%@%04d.tif",[prefixField stringValue],(int)[object time]]];

    [timeField setStringValue:[NSString stringWithFormat:@"%0.2f ms",[object time]]];

}

- saveActivityMovie:sender
{
    [myMovieView writeToFile:@"~/Movies/test.mov" atomically:YES];
    return self;
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
        switch (displayMode){
            case DISPLAY_TYPE:
                [selectVariableDrawer close:self];
                [self _autoscaleOn];
                break;
            case DISPLAY_STATE:
                [selectVariableDrawer close:self];
                [self _autoscaleOffWithMin:SIM_RefractoryState max:(SIM_PlasticState | SIM_SpikingState)];
                break;
            case DISPLAY_POTENTIAL:
                [selectVariableDrawer close:self];
                [self _autoscaleOffWithMin:-90.0 max:30.0];
                break;
            case DISPLAY_INPUT:
                [selectVariableDrawer close:self];
                [self _autoscaleOn];
                break;
            case DISPLAY_OTHER:
                [selectVariableDrawer open:self];
                [self _autoscaleOn];
                break;
            default:
                break;
        }
    }
    if(sender == selectVariableButton){
        if([selectVariableDrawer state] == NSDrawerClosedState){
            [variablePopup selectItemWithTitle:@"Other"];
            displayMode = DISPLAY_OTHER;
        }
        [selectVariableDrawer toggle:sender];
    }
    if(sender == autoScaleSwitch){
        BOOL state = ([autoScaleSwitch state] == NSOnState);
        [minField setEnabled:!state];
        [maxField setEnabled:!state];
        [activityView setAutoScale:state];
    }
    if((sender == minField) || (sender == maxField)){
        [autoScaleSwitch setState:NSOffState];
        //[activityView setAutoScale:NO];
        //[activityView setMin:[minField floatValue] andMax:[maxField floatValue]];
        //NSLog(@"%g %g",[minField floatValue],[maxField floatValue]);
    }
    if(sender==saveImageSwitch){
        saveImageFlag = !saveImageFlag;
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

    [self display];
}

- (void)_autoscaleOn
{
    [autoScaleSwitch setState:NSOnState];
    [minField setEnabled:NO];
    [maxField setEnabled:NO];
    [activityView setAutoScale:YES];
}

- (void)_autoscaleOffWithMin:(float)minVal max:(float)maxVal
{
    [autoScaleSwitch setState:NSOffState];
    [minField setEnabled:YES];
    [maxField setEnabled:YES];
    [minField setFloatValue:minVal];
    [maxField setFloatValue:maxVal];
    [activityView setAutoScale:NO];
    [activityView setMin:minVal andMax:maxVal];
}

- (void) mouseDown:(NSEvent *)event
{
	//NSLog([event description]);
}

- saveActivityViewAsTIFF:sender
{
//    static int count = 0;
    [activityView saveTIFFToFile:[NSString stringWithFormat:@"/tmp/%@%04d.tif",[prefixField stringValue],(int)[object time]]];
	return self;
}


- (void)inspect:(id)anObject
{

	if([anObject isProxy])[anObject setProtocolForProxy:@protocol(SIMRemoteNetwork)];
    [layerPopup removeAllItems];
    [layerPopup addItemsWithTitles:[[anObject allLayers] sortedArrayUsingSelector:@selector(compare:)]];
    numRows = (int)[(SIMNetwork *)anObject numRowsInLayer:layerIndex];
    numColumns = (int)[(SIMNetwork *)anObject numColumnsInLayer:layerIndex];
    [activityView initSize:numColumns :numRows];

    [activityView setColorPaletteFromColorListWithName:@"Membrane Potential"];

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
        selector:@selector(display) object:[server network]];
}

- (void)unregisterForNotifications
{
    [super unregisterForNotifications];
}

- copyWithZone:(NSZone *)zone
{
    SIMNetworkActivityInspector *inspectorCopy = [super copyWithZone:zone];
	inspectorCopy->layerIndex = layerIndex;
	inspectorCopy->variableIndex = variableIndex;
	inspectorCopy->numRows = numRows;
	inspectorCopy->numColumns = numColumns;
	[inspectorCopy->activityView initSize:numRows :numColumns];
    return inspectorCopy;
}


@end
