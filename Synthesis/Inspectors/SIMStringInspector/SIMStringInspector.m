/* SIMStringInspector.m created by hill on Tue 29-Oct-1996 */

#import "SIMStringInspector.h"

@implementation SIMStringInspector

- (void)display
{
    [stringField setStringValue:[object objectAtPath:parameterPath]];
}

- (void)ok:sender
{
    [object setParameter:parameterPath value:[stringField stringValue]];
}

@end
