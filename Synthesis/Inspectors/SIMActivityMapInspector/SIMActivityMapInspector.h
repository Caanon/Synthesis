/* SIMActivityMapInspector.h created by hill on Mon 17-Mar-1997 */

#import <AppKit/AppKit.h>
#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisInterface/SIMDataView.h>
#import <SynthesisInterface/SIMInspector.h>
#import <Desiderata/SIMHistogram.h>

@interface SIMActivityMapInspector : SIMInspector
{
    id	activityView;
    id	layerPopup;
    id	variablePopup;
    id  browser;
    id  durationField;
    id  numCellsField;
    id	cellArray;

    id autoScaleSwitch;
    id minField;
    id maxField;
    id numberOfBinsField;

    id histogramDrawer;
    id settingsDrawer;
    id selectVariableButton;
    id selectVariableDrawer;

    id layer,selectedModel,type,variable;
    
    int	duration,numCells,frameIndex,numRows,numColumns,displayMode,variableIndex, typeIndex,layerIndex, modelIndex,modelType;
    int numberOfBins;
    int browserIndex1, browserIndex2, browserIndex3, browserIndex0;
    
    SIMHistogram *histogram;    
    
    NSArray *layerKeys;
    NSString *layerKey;
    NSMutableData *activityData;
    NSString *savePath;
}

- saveActivityViewAsTIFF:sender;

@end
