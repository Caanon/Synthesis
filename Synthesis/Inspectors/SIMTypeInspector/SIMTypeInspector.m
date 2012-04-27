#import "SIMTypeInspector.h"
#import <XYPlot/XYPlotView.h>
#import <SynthesisCore/Simulator.h>

@implementation SIMTypeInspector

- init
{
    [super init];
    selectedCell = @"All";
    selectedChannel = @"All";
    duration = 100.0;
    dt = .1;
    stimDuration = 10;
    stimStrength = 1.0;
    return self;
}

- (void)display
{
    double i;
    NSMutableValueArray *ref = [NSMutableValueArray valueArrayWithObjCType:@encode(double)];
    NSValueArray *array = [object membranePotentialForCellModel:[cellPopup titleOfSelectedItem]
                                   usingChannelModel:[channelPopup titleOfSelectedItem]
                                    forDuration:duration
                                    stimulusDuration:stimDuration
                                    magnitude:stimStrength dt:dt];


    for(i = 0; i < duration; i+=dt){
        [ref addValue:&i];
    }

    [cellView removeAllPlots:self];
    [cellView plotValues:ref :array];
}

- (void)ok:sender
{
    selectedCell = [cellPopup titleOfSelectedItem];
    selectedChannel = [channelPopup titleOfSelectedItem];
    duration = [timeWindowField floatValue];
    dt = [timeStepField floatValue];
    stimDuration = [stimulusDurationSlider floatValue];
    stimStrength = [stimulusMagnitudeSlider floatValue];
    
    [stimulusDurationSlider setMaxValue:duration];
    [stimulusMagnitudeField setFloatValue:stimStrength];
    
    [self display];
}

- (void)inspect:anObject
{
    [super inspect:anObject];

    [timeWindowField setFloatValue:duration];
    [timeStepField setFloatValue:dt];
    [stimulusDurationSlider setFloatValue:stimDuration];
    [stimulusMagnitudeSlider setFloatValue:stimStrength];
    [stimulusDurationSlider setMaxValue:duration];
    [stimulusMagnitudeField setFloatValue:stimStrength];

    [cellView setMainTitle:@"Cell Activity"];
    [cellView setXTitle:@"Time (ms)"];
    [cellView setYTitle:@"Membrane potential"];

    [cellPopup removeAllItems];
    [cellPopup addItemWithTitle:@"All"];
    [cellPopup addItemsWithTitles:[(SIMType *)anObject allCellCompartmentKeys]];
    [cellPopup selectItemWithTitle:selectedCell];
    [channelPopup removeAllItems];
    [channelPopup addItemWithTitle:@"All"];
    [channelPopup addItemsWithTitles:[(SIMType *)anObject allInputChannelKeys]];
    [channelPopup selectItemWithTitle:selectedChannel];
    [self display];
}

- (void)registerForNotifications
{
    [super registerForNotifications];
    [server addClient:self forNotificationName:SIMParameterDidChangeNotification
        selector:@selector(display) object:nil];
}

- copyWithZone:(NSZone *)zone
{
    SIMTypeInspector *inspectorCopy = [super copyWithZone:zone];
    inspectorCopy->selectedCell = [selectedCell copy];
    inspectorCopy->selectedChannel = [selectedChannel copy];
    inspectorCopy->duration = duration;
    inspectorCopy->dt = dt;
    inspectorCopy->stimDuration = stimDuration;
    inspectorCopy->stimStrength = stimStrength;
    
    [inspectorCopy inspect:object];
    
    return inspectorCopy;
}


@end
