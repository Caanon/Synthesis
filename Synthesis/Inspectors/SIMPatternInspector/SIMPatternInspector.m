/* SIMPatternInspector.m created by hill on Mon 17-Mar-1997 */

#import "SIMPatternInspector.h"
#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisCore/SIMNetworkInfo.h>
#import <SynthesisCore/SIMNetworkTopology.h>
#import <SynthesisCore/SIMNetworkStatistics.h>

@implementation SIMPatternInspector

- init
{
    [super init];
    
    [patternView initSize:1 :1];
    [patternView setAutoScale:YES];
    layerIndex = 0;
    numRows = 50;
    numColumns = 50;
        
    return self;
}

- (void)display
{
    NSData *values = [object valuesForRows:numRows columns:numColumns layer:layerIndex time:t];
    [patternView setAutoScale:YES];
    if(values)[patternView setData:values];
    [patternView setNeedsDisplay:YES];
}

- (void)run:sender
{
    
}

- (void)ok:sender
{
    numRows = (int)[rowsField intValue];
    numColumns = (int)[columnsField intValue];
    
    t = [timeSlider floatValue];
    [timeField setFloatValue:t];
    layerIndex = [layerSlider intValue];
    
    [patternView initSize:numColumns :numRows];
    [self display];
}

- (void)inspect:anObject
{
    numRows = (int)[rowsField intValue];
    numColumns = (int)[columnsField intValue];
    [patternView initSize:numColumns :numRows];

    [patternView setColorPaletteFromColorListWithName:@"Membrane Potential"];

    [super inspect:anObject];

}

- (void)registerForNotifications
{
    [super registerForNotifications];
    [server addClient:self forNotificationName:SIMParameterDidChangeNotification
        selector:@selector(display) object:nil];
}

- (void)unregisterForNotifications
{
    [super unregisterForNotifications];
}


@end
