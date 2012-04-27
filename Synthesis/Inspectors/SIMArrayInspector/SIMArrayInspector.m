/* SIMArrayInspector.m created by hill on Tue 29-Oct-1996 */

#import "SIMArrayInspector.h"

@implementation SIMArrayInspector

- (void)inspectParameter:(NSString *)parameterName forObject:anObject
{
    [super inspectParameter:parameterName forObject:anObject];
    [arrayPopUp removeAllItems];
    [arrayPopUp addItemsWithTitles:[rangeArray copy]];
    [self display];
}

- (void)display
{
    [arrayPopUp selectItemWithTitle:[[object objectAtPath:parameterPath] description]];
}

- (void)ok:sender
{
    [object setParameter:parameterPath value:[sender titleOfSelectedItem]];
}


@end
