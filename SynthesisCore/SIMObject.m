/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/SIMObject.h>
#import <SynthesisCore/SIMCategories.h>
#import <Desiderata/NSValueArray.h>

@implementation SIMObject

- init
/*"
        Initializes the object by loading the template file with the name
        of the current class (subclasses should use their class name).
"*/
{
    return [self initWithDescription:nil];
}

- initWithDescription:(NSDictionary *)aDescription
/*"
    The designated initializer for this class.  It first loads the template,
    merges the dictionary containing the description with that from the template.
    This then calls initModelWithNetwork: with an argument of nil, in order to provide
    a default initialization.
"*/
{
    NSString *templatePath;
    NSString *className = NSStringFromClass([self class]);
        
    if(aDescription != nil)[aDescription retain];
    
    templatePath = [[NSBundle bundleForClass:[self class]] pathForResource:className ofType:TEMPLATE_EXTENSION];
    NSAssert1(templatePath,@"Template file must exist in the bundle for the class: %@",className);
    mainDictionary = [[NSMutableDictionary dictionaryWithContentsOfFile:templatePath] retain];
    NSAssert1(mainDictionary,@"Problem with template file for the class: %@",className);
    [mainDictionary setObject:className forKey:SIMClassNameKey];
    parameterDictionary = [[mainDictionary objectForKey:SIMParametersKey] mutableCopy];
    [mainDictionary setObject:parameterDictionary forKey:SIMParametersKey];

    // make sure that this description can't overwrite model's
    // template variables.  Models can't handle it if their
    // variables are changed on them.  This also makes it unnecesary
    // to specify variables in network files.

    if(aDescription){
        id variableDictionary = nil;
        variableDictionary = [mainDictionary objectForKey: SIMVariablesKey];
        [parameterDictionary addEntriesFromDictionary:[aDescription objectForKey: SIMParametersKey]];
        [mainDictionary addEntriesFromDictionary: aDescription];
        [mainDictionary setObject:parameterDictionary forKey:SIMParametersKey];
        [mainDictionary setObject:NSStringFromClass([self class]) forKey:SIMClassNameKey];
        if (variableDictionary)
            [mainDictionary setObject: variableDictionary forKey: SIMVariablesKey];
        [aDescription autorelease];
    }

    [self updateParameters];

    return self;
}


- (oneway void) updateParameterValues
{
    // This should be the routine where all values are extracted from the parameter
    // dictionary and the instance variables are set.
    // a = [parameterDictionary floatForKey:AKey];
    // This should then be followed by a call to [super updateParameters]
    // to send the SIMParameterDidChangeNotification.
    NSNotification *notification = [NSNotification notificationWithName:SIMParameterDidChangeNotification object:self];

    [self updateParameters];

    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle: NSPostASAP
        coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
}

- (void) updateParameters
/*"
    This method is responsible for extracting parameter values from the description dictionary.
    All subclasses should override this method to extract values for parameters that they may
    have added.  Be sure to call [super updateParameters], because the base SIMObject extracts
    the integration method from its parameter dictionary with this method.
"*/
{
}

- (void)setParameterDictionary:(NSDictionary *)aDictionary
/*"
    Merges aDictionary with the current parameter dictionary, overwriting any previously
    existing entries.  It then calls updateParameterValues which sends a notification that
    the parameters have changed.
"*/
{
    [parameterDictionary addEntriesFromDictionary:aDictionary];
    [self updateParameterValues];
}

- (NSDictionary *)parameterRanges;
/*"
    Returns a dictionary containing the range information for a particular parameter.
    This typically is used for client applications that want to know the permissible
    values for a parameter.
"*/
{
    return [mainDictionary objectForKey:SIMParameterRangesKey];
}

- (NSDictionary *)parameterDictionary
/*"
    returns the parameter dictionary;
"*/
{
    return [mainDictionary objectForKey:SIMParametersKey];
}

- (void)setObject:(id)object forKey:(in NSString *)key
/*"
    Calls setObject:object forKey:key with the parameter dictionary.
    The calls the method updateParameterValues, to update the new values
    and send a notification that the parameters have been updated.
"*/
{
    [parameterDictionary setObject:object forKey:key];
    [self updateParameterValues];
}

- (id)objectForKey:(in NSString *)key
/*"
    If the key is equal to SIMParameterRangesKey this returns a value from the
    main dictionary.  Otherwise returns objectForKey:key from the parameter dictionary.
"*/
{
    if([key isEqual:SIMParameterRangesKey])return [mainDictionary objectForKey:SIMParameterRangesKey];
    return [parameterDictionary objectForKey:key];
}

- (id)objectAtPath:(NSString *)path
{
    if([[path lastSimulatorPathComponent] isEqual:SIMParameterRangesKey])return [mainDictionary objectForKey:SIMParameterRangesKey];
    return [mainDictionary objectAtPath:path];
}

- (NSArray *)allKeys
/*"
    Returns all keys in the parameter dictionary.
"*/
{
    return [parameterDictionary allKeys];
}

- (NSEnumerator *) keyEnumerator
/*"
    Returns an enumerator for all keys in the parameter dictionary.
"*/
{
    return [[self allKeys] objectEnumerator];
}

- (BOOL)boolForKey:(NSString *)key
/*"
    Returns the boolean value of the object in the parameter dictionary for key.
"*/
{
        BOOL aBool= NO;
        id	value = [self objectForKey:key];

        if([value respondsToSelector:@selector(boolValue)])
                aBool = [value boolValue];
        return aBool;
}

- (int)intForKey:(NSString *)key
/*"
    Returns the integer value of the object in the parameter dictionary for key.
"*/
{
        int anInt = 0;
        id	value = [self objectForKey:key];

        if([value respondsToSelector:@selector(intValue)])
                anInt = [value intValue];
        return anInt;
}

- (float)floatForKey:(NSString *)key
/*"
    Returns the float value of the object in the parameter dictionary for key.
"*/
{
        float aFloat=0.0;
        id	value = [self objectForKey:key];

        if([value respondsToSelector:@selector(floatValue)])
                aFloat = [value floatValue];
        return aFloat;
}

- (double)doubleForKey:(NSString *)key
/*"
    Returns the double value of the object in the parameter dictionary for key.
"*/
{
        double aDouble=0.0;
        id	value = [self objectForKey:key];

        if([value respondsToSelector:@selector(doubleValue)])
            aDouble = [value doubleValue];
        return aDouble;
}


- (NSString *)description
/*"
    Returns the description of the object.  This is in property list format and
    contains entries describing the class name and the parameter values necessary to
    instantiate this object.
"*/
{
    NSMutableDictionary *descDict = [NSMutableDictionary dictionary];
    [descDict setObject:[mainDictionary objectForKey:SIMClassNameKey] forKey:SIMClassNameKey];
    [descDict setObject:[mainDictionary objectForKey:SIMParametersKey] forKey:SIMParametersKey];
    return [descDict description];
}

- (NSString *)inspectorClassName
/*"
    Returns the inspector name for this class.  This is currently: <CLASSNAME>Inspector
"*/
{
    NSString *inspectorClassName = nil;
    /* If there is no INSPECTOR_CLASS entry in the description then default to class name followed by "Inspector" */

    inspectorClassName = [mainDictionary objectForKey:INSPECTOR_CLASS_KEY];
    if(inspectorClassName && ![inspectorClassName isEqual:@""])return inspectorClassName;
    else return [NSString stringWithFormat:@"%@Inspector",NSStringFromClass([self class])];
}

- (NSString *)iconName
/*"
    Returns the name of an icon that could be used to represent this class.
"*/
{
    return @"SIMObject";
}

- (id)initWithCoder:(NSCoder *)coder
/*"
    Initializes a new instance of this class from coder.
"*/
{
    mainDictionary = [[coder decodeObject] retain];
    parameterDictionary = [mainDictionary objectForKey:SIMParametersKey];
    [self updateParameters];

    return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
/*"
    Encodes the current object with coder, see NSCoding.
"*/
{
    [coder encodeObject:mainDictionary];
}

- (void)dealloc
/*"
    Deallocates the model.
"*/
{
    [mainDictionary release];
    [super dealloc];
}


// Very simple and basic add/remove client methods

- (void)addClient:aClient forNotificationName:(NSString *)name selector:(SEL)aSelector object:anObject
{
    if(!clients)clients = [[NSMutableArray array] retain];

    [clients addObject:aClient];
    [[NSNotificationCenter defaultCenter] addObserver:aClient selector:aSelector name:name object:anObject];

    //NSLog(@"A client has connected from host: \"%@\".",[aClient hostName]);
}

- (void)removeClient:aClient forNotificationName:(NSString *)name object:anObject
{
    [[NSNotificationCenter defaultCenter] removeObserver:aClient name:name object:anObject];
    [clients removeObject:aClient];
    //NSLog(@"Removed a client connected from host: \"%@\".",[aClient hostName]);
}

- (void)removeClient:aClient
{
    [[NSNotificationCenter defaultCenter] removeObserver:aClient];
    [clients removeObject:aClient];
    //NSLog(@"Removed a client connected from host: \"%@\".",[aClient hostName]);
}

- (void)removeAllClients:sender
{
    [self removeAllClients];
}

- (void)removeAllClients
{
    NSEnumerator *enumerator = [clients objectEnumerator];
    id next;
    id nCenter = [NSNotificationCenter defaultCenter];

    while(next = [enumerator nextObject]) {
        [nCenter removeObserver:next];
    }
    [clients removeAllObjects];
    NSLog(@"Removed all connected clients.");
}


@end
