#import <AppKit/AppKit.h>
#import <SynthesisInterface/SIMClientCategories.h>
#import <SynthesisInterface/SIMParameterInspector.h>

@interface SIMDictionaryInspector : SIMInspector
{
    id browser;
    id browserPath;
    id emptyInspector;
    id objectView;
    id objectDrawer;
    id valueView;
@private
    SIMParameterInspector *valueInspector;
    SIMInspector *objectInspector;
    NSString *currentPath;
    NSString *currentKey;
    id currentObject;
    NSMutableDictionary *inspectorDictionary;
    NSMutableArray *inspectorArray;
}

- (void)inspect:object;
- (void)ok:(id)sender;
- (id)cloneInspector:sender;
- (void)setParentWindow:(NSWindow *)window;
- (void)display;

- (void)inspectObject:(id <SIMInspectable>)anObject withInspectorKey:(NSString *)inspectorKey;
- (void)inspectParameter:(NSString *)parameterName;
@end
