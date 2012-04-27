/* SIMNetworkActivityInspector.h created by hill on Mon 17-Mar-1997 */

#import <AppKit/AppKit.h>
#import <SynthesisInterface/SIMDataView.h>
#import <SynthesisInterface/SIMColorDataView.h>
#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMCommandServer.h>
#import <SynthesisInterface/SIMInspector.h>
#import <SynthesisInterface/SIMMutableMovie.h>
#import <Desiderata/SIMHistogram.h>

@interface SIMNetworkActivityInspector : SIMInspector
{
    id activityView;
    id histogramView;
    id layerPopup;
    id variablePopup;
    id browser;
	
	id timeField;
    id autoScaleSwitch;
    id minField;
    id maxField;
    id numberOfBinsField;
    id prefixField;
    id saveImageSwitch;
    id selectVariableButton;
    id histogramDrawer;
    id settingsDrawer;
    id selectVariableDrawer;
    
    id myMovieView;
    
    id layer,selectedModel,type,variable;
    
    int	frameIndex,numRows,numColumns,displayMode,variableIndex, typeIndex,layerIndex, modelIndex,modelType;
    int numberOfBins;
    int browserIndex1, browserIndex2, browserIndex3, browserIndex0;
    BOOL saveImageFlag;
    NSArray *layerKeys;
    NSString *layerKey;
#if !__LP64__ // 64 bit Quicktime doesn't exist
    SIMMutableMovie *myMovie;
#endif
    SIMHistogram *histogram;
}

- saveActivityViewAsTIFF:sender;
- saveActivityMovie:sender;

//private
- (void)_autoscaleOn;
- (void)_autoscaleOffWithMin:(float)minVal max:(float)maxVal;

@end
