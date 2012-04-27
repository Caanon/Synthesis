//
//  SIMConnectionMatrixInspector.m
//  Synthesis
//
//  Created by Sean Hill on Mon Jul 12 2004.
//  Copyright (c) 2004. All rights reserved.
//

#import "SIMConnectionMatrixInspector.h"
#import <SynthesisInterface/SIMColorDataView.h>
#import <XYPlot/XYPlotView.h>
#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMNetworkTopology.h>
#import <SynthesisCore/SIMNetworkInfo.h>

@implementation SIMConnectionMatrixInspector

- init
{
    [super init];
    layerIndex1 = 0;
    layerIndex2 = 0;
    
	histogram = [[SIMHistogram histogramWithNumberOfBins:6 rangeStart:0 end:6] retain];
    	
    return self;
}

- (void)display
{
    NSData *displayData = nil;
	
	[matrixView setAutoScale:YES];
	[matrixView setImageSmoothing:YES];
	
	displayData = [(SIMNetwork *) object connectionMatrixFromLayer:layer1 andType:type1 toLayer:layer2 andType:type2 channel:channel];
    
	[matrixView setData:displayData];// byteOrder:[object hostByteOrder]];
    [matrixView setNeedsDisplay:YES];
    

    //if([histogramDrawer state] == NSDrawerOpenState)
    {
        float 	*bytes;
        int i,count;
        [histogram clearBins];
        bytes = (float *)[displayData bytes];
        count = [displayData length]/sizeof(float);
        for(i = 0; i < count; i++){
            double val =  (double)bytes[i];
            if(val)[histogram addDouble:val];
        }
        [histogramView setPlotStyle:@"FilledBar"];
        [histogramView plotValues:[histogram rangeValues] :[histogram binValues]];
    }  
	
}

- (void)ok:sender
{


	layer1 = [layerPopup1 titleOfSelectedItem];
	layer2 = [layerPopup2 titleOfSelectedItem];
	type1 = [typePopup1 titleOfSelectedItem];
	type2 = [typePopup2 titleOfSelectedItem];
	channel = [channelPopup titleOfSelectedItem];


	if(sender == layerPopup1){
		[typePopup1 removeAllItems];
		[typePopup1 addItemsWithTitles:[[object allTypesForLayer:[layerPopup1 titleOfSelectedItem]] sortedArrayUsingSelector:@selector(compare:)]];
		type1 = [typePopup1 titleOfSelectedItem];
	}
		
	if(sender == layerPopup2){
		[typePopup2 removeAllItems];
		[typePopup2 addItemsWithTitles:[[object allTypesForLayer:[layerPopup2 titleOfSelectedItem]] sortedArrayUsingSelector:@selector(compare:)]];
		type2 = [typePopup2 titleOfSelectedItem];
		[channelPopup removeAllItems];
		[channelPopup addItemsWithTitles:[[object allInputChannelsForType:type2 
			inLayer:layer2] sortedArrayUsingSelector:@selector(compare:)]];
		channel = [channelPopup titleOfSelectedItem];
	}

		
        layerIndex1 = (int)[object indexForLayerWithKey:layer1];
        layerIndex2 = (int)[object indexForLayerWithKey:layer2];
        numRows1 = (int)[object numRowsInLayer:layerIndex1];
        numColumns1 = (int)[object numColumnsInLayer:layerIndex1];
        numRows2 = (int)[object numRowsInLayer:layerIndex2];
        numColumns2 = (int)[object numColumnsInLayer:layerIndex2];

		matrixRows = numColumns1*numRows1;
		matrixColumns = numColumns2*numRows2;
		
        [matrixView initSize:matrixRows :matrixColumns];
		
		[selectionField setStringValue:[NSString stringWithFormat:@"%@%@%@%C%@%@%@%@%@",layer1,SIM_TypeSeparator,type1,0x21D2,layer2,SIM_TypeSeparator,type2,SIM_TypeSeparator,channel]];
		
		if(histogram)[histogram release];
		histogram = [[SIMHistogram histogramWithNumberOfBins:[numBinsField doubleValue] rangeStart:[minField doubleValue] end:[maxField doubleValue]] retain];

    //}
	
	
    [self display];
}


- (void)inspect:anObject
{
    [layerPopup1 removeAllItems];
    [layerPopup1 addItemsWithTitles:[[anObject allLayers] sortedArrayUsingSelector:@selector(compare:)]];
	[typePopup1 removeAllItems];
	[typePopup1 addItemsWithTitles:[[anObject allTypesForLayer:[layerPopup1 titleOfSelectedItem]] sortedArrayUsingSelector:@selector(compare:)]];

    [layerPopup2 removeAllItems];
    [layerPopup2 addItemsWithTitles:[[anObject allLayers] sortedArrayUsingSelector:@selector(compare:)]];
	[typePopup2 removeAllItems];
	[typePopup2 addItemsWithTitles:[[anObject allTypesForLayer:[layerPopup2 titleOfSelectedItem]] sortedArrayUsingSelector:@selector(compare:)]];

	[channelPopup removeAllItems];
	[channelPopup addItemsWithTitles:[[anObject allInputChannelsForType:[typePopup2 titleOfSelectedItem] 
		inLayer:[layerPopup2 titleOfSelectedItem]] sortedArrayUsingSelector:@selector(compare:)]];


	numRows1 = (int)[(SIMNetwork *)anObject numRowsInLayer:layerIndex1];
    numColumns1 = (int)[(SIMNetwork *)anObject numColumnsInLayer:layerIndex1];

	numRows2 = (int)[(SIMNetwork *)anObject numRowsInLayer:layerIndex2];
    numColumns2 = (int)[(SIMNetwork *)anObject numColumnsInLayer:layerIndex2];

	[matrixView initSize:numColumns1*numRows1 :numColumns2*numRows2];
	
    [matrixView setColorPaletteFromColorListWithName:@"Membrane Potential"];
	
    [histogramView removeAllPlots:self];
    [histogramView setAutoScale:YES];
    [histogramView setMainTitle:@"Histogram"];
    [histogramView setXTitle:@"Value"];
    [histogramView setYTitle:@"Count"];
		
    [super inspect:anObject];
	
}

- copyWithZone:(NSZone *)zone
{
    SIMConnectionMatrixInspector *inspectorCopy = [super copyWithZone:zone];
	inspectorCopy->layer1 = [layer1 copy];
	inspectorCopy->layerIndex1 = layerIndex1;
	inspectorCopy->layer2 = [layer2 copy];
	inspectorCopy->layerIndex2 = layerIndex2;
	inspectorCopy->numRows1 = numRows1;
	inspectorCopy->numColumns1 = numColumns1;
	[inspectorCopy->matrixView initSize:numRows1*numColumns1 :numRows2*numColumns2];
    return inspectorCopy;
}


@end
