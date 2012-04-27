/* SIMNumberInspector.m created by hill on Tue 29-Oct-1996 */

#import "SIMNumberInspector.h"

@implementation SIMNumberInspector

- (void)display
{
    double val = [[object objectAtPath:parameterPath] doubleValue];
    double min = [[rangeArray objectAtIndex:0] doubleValue];
    double max = [[rangeArray objectAtIndex:1] doubleValue];

    if(!formatString)formatString = @"%g";
    [numberSlider setMinValue:min];
    [numberSlider setMaxValue:max];
    [numberField setStringValue:[NSString stringWithFormat:formatString,val]];
    [numberSlider setDoubleValue:val];
}

- (void)ok:sender
{
    id valueString;

    if(!formatString)formatString = @"%g";
    valueString = [NSString stringWithFormat:formatString,[[sender performSelector:selector] doubleValue]];

    [numberSlider setDoubleValue:[sender doubleValue]];
    [numberField setStringValue:valueString];
    [object setParameter:parameterPath value:valueString];
}

@end
