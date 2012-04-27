/* SIMBoolInspector.m created by hill on Tue 29-Oct-1996 */

#import "SIMBoolInspector.h"

@implementation SIMBoolInspector

- (void)display
{
    [boolMatrix selectCellWithTag:[[object objectAtPath:parameterPath] boolValue]];
}

- (void)ok:sender
{
    [object setParameter:parameterPath value:([[sender selectedCell] tag])?@"Yes":@"No"];
}

@end
