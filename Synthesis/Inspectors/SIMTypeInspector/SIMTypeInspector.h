#import <AppKit/AppKit.h>
#import <SynthesisInterface/SIMInspector.h>
#import <SynthesisCore/SIMType.h>

@interface SIMTypeInspector : SIMInspector
{
    id cellView;
    id channelView;
    id cellPopup;
    id channelPopup;
    id stimulusDurationSlider;
    id stimulusMagnitudeSlider;
    id stimulusMagnitudeField;
    id timeWindowField;
    id timeStepField;
    
    @private
        NSString *selectedCell;
        NSString *selectedChannel;
        float duration;
        float dt;
        float stimDuration;
        float stimStrength;
}

- (void)display;
@end
