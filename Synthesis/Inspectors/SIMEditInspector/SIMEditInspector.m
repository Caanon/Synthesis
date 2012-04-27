/* SIMEditInspector.m created by shill on Mon 26-Jul-1999 */

#import "SIMEditInspector.h"

@implementation SIMEditInspector

- (void)inspectParameter:(NSString *)parameterName forObject:anObject
{
    [super inspectParameter:parameterName forObject:anObject];

    if(type)[type release];
    type = [[info objectForKey:@"TYPE"] retain];

    [self display];
}


- (void)display
{
    if([type isEqual:SIMLayersKey])
        [editField setStringValue:@"NewLayer"];
    else if([type isEqual:SIMTypesKey])
        [editField setStringValue:@"NewCellType"];
    else if([type isEqual:SIMCellCompartmentsKey])
        [editField setStringValue:@"NewCellCompartment"];
    else if([type isEqual:SIMEfferentConnectionsKey ])
        [editField setStringValue:@"NewEfferents"];
    else if([type isEqual:SIMAfferentConnectionsKey ])
        [editField setStringValue:@"NewAfferents"];
    else [editField setStringValue:@""];
}

- (void)ok:sender
{
#define LAYERNAME 2
#define TYPENAME 4

    NSArray *pathComponents = [parameterPath simulatorPathComponents];
    if(![[editField stringValue] isEqual:@""]){
        if([type isEqual:SIMLayersKey])
            [object addLayerWithName:[editField stringValue]];
        else if([type isEqual:SIMTypesKey]){
            [object addTypeWithName:[editField stringValue] layer:[pathComponents objectAtIndex:LAYERNAME]];
        }
        else if([type isEqual:SIMCellCompartmentsKey]){
            [object setObject:[SIMCell new]
                atPath:[NSString stringWithFormat:@"%@/%@",parameterPath,[editField stringValue]]];
            NSLog([NSString stringWithFormat:@"%@/%@",parameterPath,[editField stringValue]]);
        }
        else if([type isEqual:SIMEfferentConnectionsKey ])
            [object addEfferentConnectionsWithName:[editField stringValue]
                type:[pathComponents objectAtIndex:TYPENAME]
                layer:[pathComponents objectAtIndex:LAYERNAME]];
        else if([type isEqual:SIMAfferentConnectionsKey ])
            [object addAfferentConnectionsWithName:[editField stringValue]
                type:[pathComponents objectAtIndex:TYPENAME]
                layer:[pathComponents objectAtIndex:LAYERNAME]];
    }
#undef LAYERNAME
#undef TYPENAME
}

- (void)remove:sender
{
    [object removeLayerWithName:[editField stringValue]];
}

@end
