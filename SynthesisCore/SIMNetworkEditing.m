/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */


#import <SynthesisCore/SIMNetworkEditing.h>

@implementation SIMNetwork (SIMNetworkEditing)

- (void)addLayerWithName:(NSString *)name
/*"
    Adds a layer to the network using name as the key.
"*/
{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Layer" ofType:TEMPLATE_EXTENSION];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    NSMutableDictionary *layerDict = [self layerDictionary];
    if(!layerDict || ![layerDict isKindOfClass:[NSMutableDictionary class]]){
        layerDict = [NSMutableDictionary dictionary];
        [descriptionDictionary setObject:layerDict forKey:SIMLayersKey];
    }
    [layerDict setObject:dict forKey:name];

    [self sendParameterChangeNotification];

}

- (void) setTypesDictionary:(NSMutableDictionary *)dict forLayerWithKey:(NSString *)key
/*"
    Sets the types dictionary dict for the layer with key.
"*/
{
    id myLayer = [[self layerDictionary] objectForKey:key];
    [myLayer setObject:dict forKey:SIMTypesKey];
}

- (void)addTypeWithName:(NSString *)name layer:(NSString *)layer
/*"
    Adds a type (called name) to layer in the network.
"*/
{
    NSMutableDictionary *typesDict = [self typesDictionaryForLayerWithKey:layer];
    if(!typesDict || ![typesDict isKindOfClass:[NSMutableDictionary class]]){
        typesDict = [NSMutableDictionary dictionary];
        [self setTypesDictionary:typesDict forLayerWithKey:layer];
    }

    [[self typesDictionaryForLayerWithKey:layer] setObject:[SIMType new] forKey:name];

    [self sendParameterChangeNotification];
}

- (void)addCellCompartment:(SIMCell *)cell withName:(NSString *)name type:(NSString *)type layer:(NSString *)layer
/*"
    Adds a cell compartment using name to the type in layer.
"*/

{
    NSMutableDictionary *cellsDict = [[[self typesDictionaryForLayerWithKey:layer] objectForKey:type] objectForKey:SIMCellCompartmentsKey];
    if(!cellsDict || ![cellsDict isKindOfClass:[NSMutableDictionary class]]){
        cellsDict = [NSMutableDictionary dictionary];
        [[[self typesDictionaryForLayerWithKey:layer] objectForKey:type] setObject:cellsDict forKey:SIMCellCompartmentsKey];
    }
    [cellsDict setObject:cell forKey:SIMCellCompartmentsKey];
    [self sendParameterChangeNotification];
}

- (void)addEfferentConnectionsWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer
/*"
    Adds efferent connections using a connection generator of name to the type in layer.
"*/
{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Connection" ofType:TEMPLATE_EXTENSION];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];

    NSMutableDictionary *connectDict = [[[self typesDictionaryForLayerWithKey:layer] objectForKey:type] objectForKey:SIMEfferentConnectionsKey];
    if(!connectDict || ![connectDict isKindOfClass:[NSMutableDictionary class]]){
        connectDict = [NSMutableDictionary dictionary];
        [[[self typesDictionaryForLayerWithKey:layer] objectForKey:type] setObject:connectDict forKey:SIMEfferentConnectionsKey];
    }
    [connectDict setObject:dict forKey:name];
    [self sendParameterChangeNotification];
}

- (void)addAfferentConnectionsWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer
/*"
    Adds afferent connections using a connection generator of name to the type object in layer.
"*/
{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Connection" ofType:TEMPLATE_EXTENSION];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];

    NSMutableDictionary *connectDict = [[[self typesDictionaryForLayerWithKey:layer] objectForKey:type] objectForKey:SIMAfferentConnectionsKey];
    if(!connectDict || ![connectDict isKindOfClass:[NSMutableDictionary class]]){
        connectDict = [NSMutableDictionary dictionary];
        [[[self typesDictionaryForLayerWithKey:layer] objectForKey:type] setObject:connectDict forKey:SIMAfferentConnectionsKey];
    }
    [connectDict setObject:dict forKey:name];

    [self sendParameterChangeNotification];

}

- (void)sendParameterChangeNotification
/*"
    Sends a SIMParameterDidChangeNotification notifcation to all registered listeners.
"*/
{
    NSNotification *notification;

    notification = [NSNotification notificationWithName:SIMParameterDidChangeNotification object:self];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle: NSPostASAP
        coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
}

- (void)removeLayerWithName:(NSString *)name
/*"
    Removes the layer specified by name.
"*/
{
    [[self layerDictionary] removeObjectForKey:name];
    [self sendParameterChangeNotification];
}

- (void)removeTypeWithName:(NSString *)name layer:(NSString *)layer
/*"
    Removes the type specified by name in layer.
"*/
{
    [[self typesDictionaryForLayerWithKey:layer] removeObjectForKey:name];
    [self sendParameterChangeNotification];
}

- (void)removeCellCompartmentWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer
/*"
    Removes the cell compartment specified by name from the type in layer.
"*/
{
    [[[[self typesDictionaryForLayerWithKey:layer] objectForKey:type] objectForKey:SIMCellCompartmentsKey] removeObjectForKey:name];
    [self sendParameterChangeNotification];
}

- (void)removeEfferentConnectionsWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer
/*"
    Removes the efferent connections entry specified by name from the type in layer.
"*/
{
    [[[[self typesDictionaryForLayerWithKey:layer] objectForKey:type] objectForKey:SIMEfferentConnectionsKey] removeObjectForKey:name];
    [self sendParameterChangeNotification];
}

- (void)removeAfferentConnectionsWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer
/*"
    Removes the afferent connections entry specified by name from the type in layer.
"*/
{
    [[[[self typesDictionaryForLayerWithKey:layer] objectForKey:type] objectForKey:SIMAfferentConnectionsKey] removeObjectForKey:name];
    [self sendParameterChangeNotification];
}

- (NSArray *)connectionsModels
/*"
    Returns an array containing the class names of the connections models available to the simulator.
"*/
{
    NSEnumerator *pathEnum = [[[NSBundle mainBundle] pathsForResourcesOfType:CONNECTIONS_EXTENSION inDirectory:@""] objectEnumerator];
    NSMutableArray *array = [NSMutableArray array];
    NSString *path;
    while(path = [pathEnum nextObject]){
        [array addObject:[[path lastPathComponent] stringByDeletingPathExtension]];
    }
    return array;
}

- (NSArray *)cellModels
/*"
    Returns an array containing the class names of the cell models available to the simulator.
"*/
{
    NSEnumerator *pathEnum = [[[NSBundle mainBundle] pathsForResourcesOfType:CELL_EXTENSION inDirectory:@""] objectEnumerator];
    NSMutableArray *array = [NSMutableArray array];
    NSString *path;
    while(path = [pathEnum nextObject]){
        [array addObject:[[path lastPathComponent] stringByDeletingPathExtension]];
    }
    return array;
}

- (NSArray *)channelModels
/*"
    Returns an array containing the class names of the channel models available to the simulator.
"*/
{
    NSEnumerator *pathEnum = [[[NSBundle mainBundle] pathsForResourcesOfType:CHANNEL_EXTENSION inDirectory:@""] objectEnumerator];
    NSMutableArray *array = [NSMutableArray array];
    NSString *path;
    while(path = [pathEnum nextObject]){
        [array addObject:[[path lastPathComponent] stringByDeletingPathExtension]];
    }
    return array;
}

@end
