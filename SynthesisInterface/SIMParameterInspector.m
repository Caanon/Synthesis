/* SIMParameterInspector.m created by hill on Tue 29-Oct-1996 */

#import "SIMParameterInspector.h"

@implementation SIMParameterInspector

- (void)inspectParameter:(NSString *)path forObject:(NSObject *)obj
{
    NSDictionary *parameterRanges;
    NSString *paramInfoPath;

    if (parameterPath) [parameterPath release]; if (parameter) [parameter release];

    parameterPath = [path retain];
    parameter = [[path lastSimulatorPathComponent] retain];
    paramInfoPath = [NSString stringWithFormat:@"%@%@%@",[parameterPath stringByDeletingLastSimulatorPathComponent],SIM_PathSeparator,SIMParameterRangesKey];

   
    if(parameterRanges = [obj objectAtPath:paramInfoPath]){
        if(info) [info release];
        info = [[parameterRanges objectForKey:parameter] retain];
        selector = [info selectorForKey:SIMParameterSelectorKey];
        rangeArray = [[info objectForKey:SIMParameterRangeKey] retain];
        formatString = [[info objectForKey:SIMParameterFormatKey] retain];
    }
    [super inspect:obj];
}

- (void)registerForNotifications
{
    [super registerForNotifications];
    [server addClient:self forNotificationName:SIMParameterDidChangeNotification
        selector:@selector(display) object:object];
}

@end
