/* SIMFilePathInspector.m created by hill on Tue 29-Oct-1996 */

#import "SIMFilePathInspector.h"

@implementation SIMFilePathInspector

- (void)display
{
    [pathField setStringValue:[object objectAtPath:parameterPath]];    
}

- (void)ok:sender
{
    if(sender == pathButton){
        int result;
        NSString *filename;
        NSOpenPanel *oPanel = [NSOpenPanel openPanel];

        [oPanel setAllowsMultipleSelection:NO];
        result = [oPanel runModalForDirectory:NSHomeDirectory() file:nil types:nil];
        if (result == NSOKButton) {
           filename = [[oPanel filenames] objectAtIndex:0];
           [pathField setStringValue:filename];
        }
        return;
    }
    [object setParameter:parameterPath value:[pathField stringValue]];
}

@end
