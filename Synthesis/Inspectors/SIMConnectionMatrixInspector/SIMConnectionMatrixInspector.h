//
//  SIMConnectionMatrixInspector.h
//  Synthesis
//
//  Created by Sean Hill on Mon Jul 12 2004.
//  Copyright (c) 2004. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SynthesisInterface/SIMInspector.h>
#import <Desiderata/SIMHistogram.h>

@interface SIMConnectionMatrixInspector : SIMInspector {

	IBOutlet id matrixView;
	IBOutlet id connectionsView;
	IBOutlet id layerPopup1;
	IBOutlet id layerPopup2;
	IBOutlet id typePopup1;
	IBOutlet id typePopup2;
	IBOutlet id channelPopup;
	IBOutlet id histogramView;
	IBOutlet id selectionField;
	IBOutlet id histogramDrawer;
	IBOutlet id minField;
	IBOutlet id maxField;
	IBOutlet id numBinsField;
	
	int numRows1,numColumns1,numRows2,numColumns2,matrixRows,matrixColumns;
	
	NSString *layer1, *layer2, *type1, *type2, *channel;
	int layerIndex1,layerIndex2;
	
	SIMHistogram *histogram;
	
}

- (void)ok:sender;


@end
