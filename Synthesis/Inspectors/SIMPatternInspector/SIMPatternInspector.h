/* SIMPatternInspector.h created by hill on Mon 17-Mar-1997 */

#import <AppKit/AppKit.h>
#import <SynthesisInterface/SIMDataView.h>
#import <SynthesisInterface/SIMColorDataView.h>
#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMPatternGenerator.h>
#import <SynthesisInterface/SIMInspector.h>
#import <SynthesisInterface/SIMMutableMovie.h>

@interface SIMPatternInspector : SIMInspector
{
    id patternView;
    id timeField;
    id dtField;
    id rowsField;
    id columnsField;
    id timeSlider;
    id layerSlider;
            
    int	numRows,numColumns,displayMode,layerIndex;
    float t,dt;
}

- (void)ok:sender;
- (void)run:sender;

- (NSData *)imageData;

@end
