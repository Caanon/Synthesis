/* SIMParameterInspector.h created by hill on Tue 29-Oct-1996 */

#import <AppKit/AppKit.h>
#import "SIMInspector.h"
#import <SynthesisCore/SIMNetwork.h>

@interface SIMParameterInspector:SIMInspector
{
    NSString *parameterPath,*parameter;
    NSDictionary *info;
    SEL selector;
    NSArray *rangeArray;
    NSString *formatString;
    id network;
}

- (void)inspectParameter:(NSString *)paramName forObject:anObject;

@end
