#import "SIMDictionaryInspector.h"
#import <Foundation/Foundation.h>
#import <SynthesisCore/Simulator.h>

#define INSPECTOR_CLASS_KEY	@"INSPECTOR_CLASS"
#define INSPECTOR_FRAME_KEY	@"FRAME"
#define INSPECTORS_KEY		@"INSPECTORS"

@implementation SIMDictionaryInspector


- (void)inspect:(id)dict
{
    [super inspect:dict];

    valueInspector = nil;
    objectInspector = nil;

    if([dict conformsToProtocol:@protocol(SIMDictionaryAccess)] || [dict isKindOfClass:[NSDictionary class]]){
        object = [dict retain];
        currentObject = [object retain];  //Need to retain since the first currentObject is autoreleased, yuk.
        [browser loadColumnZero];
        [browser setPathSeparator:SIM_PathSeparator];
    }
    else {
        NSLog(@"The object you asked me to inspect does not behave like a dictionary.");
        return;
    }
}

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)num inMatrix:(NSMatrix *)matrix
{
    id			myCell,myObject;
    id			currentDict;
    NSEnumerator	*enumerator;
    int x=0;

    [sender setPathSeparator:SIM_PathSeparator];

    currentDict = [object objectAtPath:[sender pathToColumn:num]];

    if([currentDict isKindOfClass:[NSArray class]]){
        enumerator = [[currentDict sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    }
    else enumerator = [[[currentDict allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];

    while ((myObject = [enumerator nextObject])){
        // Build browser entries excluding certain keys we would like to remain invisible
        if(![[myObject description] isEqual:SIMParameterRangesKey] &&
           ![[myObject description] isEqual:SIMClassNameKey] &&
           ![[myObject description] isEqual:INSPECTORS_KEY]){
            [matrix addRow];
            myCell = [matrix cellAtRow:x++ column:0];
            [myCell setStringValue:[(NSObject *)myObject description]];
            if([currentDict isKindOfClass:[NSArray class]]){
                if([myObject isKindOfClass:[NSArray class]] ||
                [myObject isKindOfClass:[NSDictionary class]] ||
                [myObject conformsToProtocol:@protocol(SIMDictionaryAccess)])
                    [myCell setLeaf:NO];
                else [myCell setLeaf:YES];
            }
            else if([[currentDict objectForKey:myObject] isKindOfClass:[NSDictionary class]] ||
                    [[currentDict objectForKey:myObject] isKindOfClass:[NSArray class]]||[[currentDict objectForKey:myObject] conformsToProtocol:@protocol(SIMDictionaryAccess)])
                    [myCell setLeaf:NO];
            else [myCell setLeaf:YES];
            [myCell setLoaded:YES];
        }
    }
}


- (void)ok:(id)sender
{
    /* Handle the case where there is no selection */
    if([sender selectedCell]==nil){
            return;
    }

    if(currentPath)[currentPath autorelease];
    if(currentKey)[currentKey autorelease];
    if(currentObject)[currentObject autorelease];

    [sender setPathSeparator:SIM_PathSeparator];

    currentPath = [[sender pathToColumn:[sender selectedColumn]] retain];
    currentObject = [[object objectAtPath:currentPath] retain];
    currentKey = [[[sender selectedCell] stringValue] retain];
    
    if([currentPath isEqual:@"/LAYERS"]){
        [self inspectObject:object withInspectorKey:@"SIMNetworkActivityInspector"];
        return;
    }
    
    if([currentObject respondsToSelector:@selector(objectForKey:)]){
        if([[currentObject objectForKey:currentKey] respondsToSelector:@selector(inspectorClassName)]){
            id thisObject = [currentObject objectForKey:currentKey];
            if([thisObject inspectorClassName])
                [self inspectObject:thisObject withInspectorKey:[thisObject inspectorClassName]];
            [browserPath setStringValue:[NSString stringWithFormat:@"%@%@%@",currentPath,SIM_PathSeparator,[[sender selectedCell] stringValue]]];
            return;
        }
        if([currentObject objectForKey:SIMParameterRangesKey]){
            [self inspectParameter:[NSString stringWithFormat:@"%@%@%@",currentPath,SIM_PathSeparator,currentKey]];
            return;
        }
        if([[sender selectedCell] isLeaf]){
            [self inspectParameter:[NSString stringWithFormat:@"%@%@%@",currentPath,SIM_PathSeparator,currentKey]];
            return;
        }
    }

    [valueView swapView:[emptyInspector contentView]];
}

- (void)inspectObject:(id <SIMInspectable>)anObject withInspectorKey:(NSString *)inspectorKey
{
    id path;
    NSRect frame;


    if(!inspectorDictionary)inspectorDictionary = [[NSMutableDictionary dictionary] retain];

    //if(objectInspector)[objectInspector unregisterForNotifications]; // Unregister the current inspector if it exists
    objectInspector = [inspectorDictionary objectForKey:inspectorKey];

    if(!objectInspector){
        path = [[NSBundle mainBundle] pathForResource:inspectorKey ofType:INSPECTOR_EXTENSION];
        objectInspector = [[[[[NSBundle bundleWithPath:path] principalClass] alloc] init] autorelease];
        NS_DURING
        [inspectorDictionary setObject:objectInspector forKey:inspectorKey];
        NS_HANDLER
        NSLog(@"Object inspector %@ does not exist.  Please check that it is installed.",inspectorKey);
        NS_ENDHANDLER
    }
    [objectInspector setParentWindow:[self window]];
    [objectInspector inspect:anObject];
    [objectView swapView:[objectInspector inspectorView]];
    frame = [[objectInspector inspectorPanel] frame];
    [objectDrawer setContentSize:frame.size]; 
    [objectDrawer open:self];
}

- cloneInspector:sender
{
    SIMInspector *insp = [objectInspector copy];
    if(!inspectorArray)inspectorArray = [[NSMutableArray alloc] init];
    [inspectorArray addObject:insp];

    [[insp inspectorPanel] setTitle:[NSString stringWithFormat:@"%@%@%@",currentPath,SIM_PathSeparator,[[sender selectedCell] stringValue]]];

    [[insp inspectorPanel] makeKeyAndOrderFront:self];
    [objectDrawer close:self];
    // Should add to a list of inspectors
    return self;
}

- (void)inspectParameter:(NSString *)parameterPath
{
    id path;
    id inspectorKey=nil;
    NSDictionary *parameterRanges;
    id paramInfoPath = [NSString stringWithFormat:@"%@%@%@",[parameterPath stringByDeletingLastSimulatorPathComponent],SIM_PathSeparator,SIMParameterRangesKey];

    if(parameterRanges = [object objectAtPath:paramInfoPath]){
        inspectorKey = [[parameterRanges objectForKey:[parameterPath lastSimulatorPathComponent]] objectForKey:SIMParameterInspectorKey];
    }
    if(!inspectorKey)inspectorKey = @"SIMStringInspector";  //Default parameter inspector

    if(!inspectorDictionary)inspectorDictionary = [[NSMutableDictionary dictionary] retain];
    
    //if(valueInspector)[valueInspector unregisterForNotifications];
    valueInspector = [inspectorDictionary objectForKey:inspectorKey];
    
    if(!valueInspector){
        //TimEDIT
        //path = [[NSBundle bundleForClass:[self class]] pathForResource:inspectorKey ofType:@"bundle"];
        path = [[NSBundle mainBundle] pathForResource:inspectorKey ofType:@"bundle"];
        valueInspector = [[[[[NSBundle bundleWithPath:path] principalClass] alloc] init] autorelease];
        NS_DURING
        [inspectorDictionary setObject:valueInspector forKey:inspectorKey];
        NS_HANDLER
        NSLog(@"Value inspector %@ does not exist.  Please check that it is installed.",inspectorKey);
        NS_ENDHANDLER
    }

    [valueInspector inspectParameter:parameterPath forObject:object];
    [valueView swapView:[valueInspector inspectorView]];
    [[self window] makeFirstResponder: [valueInspector inspectorView]];
}

- (void)display
{
    [browser reloadColumn:[browser selectedColumn]+1];
}

- (void)setParentWindow:(NSWindow *)window
{
    [objectDrawer setParentWindow:window];
}

- (void)registerForNotifications
{
    [super registerForNotifications];
    [server addClient:self forNotificationName:SIMParameterDidChangeNotification
        selector:@selector(display) object:nil];
}


- (void)dealloc
{
    [objectDrawer close:self];
    [self unregisterForNotifications];
    if(valueInspector){
        [valueInspector unregisterForNotifications];
    }
    if(objectInspector){
        [objectInspector unregisterForNotifications];
    }
    [inspectorDictionary release];
    [super dealloc];
}
@end
