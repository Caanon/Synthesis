/* SIMEditInspector.h created by shill on Mon 26-Jul-1999 */

#import <AppKit/AppKit.h>
#import <SynthesisInterface/SIMParameterInspector.h>

@interface SIMEditInspector : SIMParameterInspector
{
    id editField;
    id addButton;
    id removeButton;
    id renameButton;
    id titleField;

    NSString *type;
}

- (void)add:sender;
- (void)remove:sender;
- (void)rename:sender;

@end
