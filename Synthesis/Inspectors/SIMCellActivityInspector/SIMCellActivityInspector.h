/* SIMCellActivityInspector.h created by hill on Wed 20-Feb-2002 */

#import <AppKit/AppKit.h>
#import <SynthesisInterface/SIMDataView.h>
#import <SynthesisInterface/SIMColorDataView.h>
#import <SynthesisCore/Simulator.h>
#import <SynthesisInterface/SIMInspector.h>
#import <XYPlot/XYPlotView.h>

@interface SIMCellActivityInspector : SIMInspector
{
    IBOutlet XYPlotView *plotView;
    IBOutlet XYPlotView *histogramView;
    IBOutlet SIMColorDataView *miniActivityView;
    id layerPopup;
    id variablePopup;
    id browser;
    id positionField;
    id timeWindowField;
    id sampleIntervalField;
    id numberOfBinsField;
    id minValueField;
    id maxValueField;
    id advancedButton;
    id drawer;
    
    NSString *layer,*selectedModel,*type,*variable;
    
    int	numRows,numColumns,displayMode,variableIndex, typeIndex,layerIndex, modelIndex,modelType;
    int browserIndex1, browserIndex2, browserIndex3, browserIndex0;
    int sampleInterval,timeWindow,numberOfBins,minValue,maxValue;
    BOOL saveImageFlag;
    NSArray *layerKeys;
    NSString *layerKey;
    NSMutableValueArray *buffer,*times;
    SIMPosition aCell;
}

- (void)gatherData;
- saveActivityData:sender;
- (void)clearData:sender;
- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)num inMatrix:(NSMatrix *)matrix;


@end
