/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/SIMCategories.h>
#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMConnections.h>
#import <Desiderata/NSValueArray.h>
#import <stdio.h>

/* OPENSTEP VERSION */


@implementation NSObject (SIMObjectExtensions)

- (NSString *)hostName
{
    return [[NSProcessInfo processInfo] hostName];
}

- (NSString *)serverName
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:SERVER_NAME_KEY];
}

- (unsigned) hostByteOrder
{
    return NSHostByteOrder();
}

- (id)classWithName:(NSString *)value ofType:(NSString *)bundleExtension
{
    Class class = nil;

    if([value isKindOfClass:[NSString class]])
            class = NSClassFromString(value);
    if(class == nil){
        id path = [[NSBundle mainBundle] pathForResource:value ofType:bundleExtension];
        id b = [NSBundle bundleWithPath:path];
        if(!b){
            NSLog(@"Unable to load class %@ of type %@",value,bundleExtension);
            return nil;
        }
        class = [b classNamed:value];
    }
    return class;
}

@end

@implementation NSString (SIMStringExtensions)


- (NSString *)lastSimulatorPathComponent
{
    return [[self simulatorPathComponents] lastObject];
}

- (NSArray *)simulatorPathComponents
{
    return [self componentsSeparatedByString:SIM_PathSeparator];
}

- (NSString *)stringByDeletingLastSimulatorPathComponent
{
    NSString *path;
    NSMutableArray *array =  [[self componentsSeparatedByString:SIM_PathSeparator] mutableCopy];
    [array removeObject:[array lastObject]];
    path = [array componentsJoinedByString:SIM_PathSeparator];
    [array release];
    return path;
}

- (NSString *)stringByAppendingSimulatorPathComponent:(NSString *)string
{
    if([self hasSuffix:SIM_PathSeparator])return [self stringByAppendingString:string];
    else return [self stringByAppendingFormat:@"%@%@",SIM_PathSeparator,string];
}



- (unsigned int)hexValue
{
    unsigned int myValue;
    sscanf ([self UTF8String], "%x", &myValue);
    return myValue;
}

- (double)doubleValue
{
    double myValue;
    sscanf ([self UTF8String], "%lg", &myValue);
    return myValue;
}

- (BOOL)boolValue
{
    // If the case-insensitive string equals 'Y' or 'YES' or an integer other than 0 return YES
    if( [[self uppercaseString] isEqual:@"YES"] ||
        [[self uppercaseString] isEqual:@"Y"] ||
        ([self intValue] != 0))
         return YES;
    return NO;
}

/*
 Should be implemented....
- (SIMPosition)positionValue
{
    double myValue;
    sscanf ([self UTF8String], "<x=%d,y=%d,z=%d>", &myValue);
    return myValue;
}
*/

- (NSRect)rectValue
{
    return NSRectFromString(self);
}

- (NSPoint)pointValue
{
    return NSPointFromString(self);
}

- (NSSize)sizeValue
{
    return NSSizeFromString(self);
}

- (SEL)selectorValue
{
    return NSSelectorFromString(self);
}


@end

@implementation NSDictionary (SIMDictionaryExtensions)

- (NSString *)stringForKey:(NSString *)key
{
        NSString *aString = @"";
        id	value = [self objectForKey:key];

        if([value respondsToSelector:@selector(description)])
                aString = [value description];
        return aString;
}


- (BOOL)boolForKey:(NSString *)key
{
        BOOL aBool= NO;
        id	value = [self objectForKey:key];

        if([value respondsToSelector:@selector(boolValue)])
                aBool = [value boolValue];
        return aBool;
}

- (int)intForKey:(NSString *)key
{
        int anInt = 0;
        id	value = [self objectForKey:key];

        if([value respondsToSelector:@selector(intValue)])
                anInt = [value intValue];
        return anInt;
}

- (float)floatForKey:(NSString *)key
{
        float aFloat=0.0;
        id	value = [self objectForKey:key];

        if([value respondsToSelector:@selector(floatValue)])
                aFloat = [value floatValue];
        return aFloat;
}

- (double)doubleForKey:(NSString *)key
{
        double aDouble=0.0;
        id	value = [self objectForKey:key];

        if([value respondsToSelector:@selector(doubleValue)])
            aDouble = [value doubleValue];
        return aDouble;
}

- (unsigned int)hexForKey:(NSString *)key
{
        unsigned int anInt=0;
        id	value = [self objectForKey:key];

        if([value respondsToSelector:@selector(hexValue)])
            anInt = [value hexValue];
        return anInt;
}


- (NSRect)rectForKey:(NSString *)key
{
    return [[[self objectForKey:key] description] rectValue];
}

- (NSPoint)pointForKey:(NSString *)key
{
    return [[[self objectForKey:key] description] pointValue];
}

- (NSSize)sizeForKey:(NSString *)key
{
    return [[[self objectForKey:key] description] sizeValue];
}

- (SEL)selectorForKey:(NSString *)key
{
    return [[[self objectForKey:key] description] selectorValue];
}

- (id)classForKey:(NSString *)key ofType:(NSString *)bundleExtension
{
    id	value = [self objectForKey:key];
    Class class = nil;
    // TIMEDIT
    NSBundle * timMainBundle;

    if([value isKindOfClass:[NSString class]])
            class = NSClassFromString(value);
    if(class == nil){
        //TIMEDIT
        timMainBundle = [NSBundle mainBundle];
        id path = [timMainBundle pathForResource:value ofType:bundleExtension];
        id b = [NSBundle bundleWithPath:path];
        if(!b){
            NSLog(@"Unable to load class %@ of type %@",value,bundleExtension);
            return nil;
        }
        class = [b classNamed:value];
    }
    return class;
}


- (id)classForKey:(NSString *)key
{
    return [self classForKey:key ofType:@"bundle"];
}

- (id)cellClassForKey:(NSString *)key
{
    return [self classForKey:key ofType:CELL_EXTENSION];
}

- (id)channelClassForKey:(NSString *)key
{
    return [self classForKey:key ofType:CHANNEL_EXTENSION];
}

- (id)connectionsClassForKey:(NSString *)key
{
    return [self classForKey:key ofType:CONNECTIONS_EXTENSION];
}

- (id)patternGeneratorClassForKey:(NSString *)key
{
    return [self classForKey:key ofType:PATGEN_EXTENSION];
}

- (id)agentClassForKey:(NSString *)key
{
    return [self classForKey:key ofType:AGENT_EXTENSION];
}

- (id)typeClassForKey:(NSString *)key
{
    return [self classForKey:key ofType:TYPE_EXTENSION];
}


- (id)objectAtPath:(NSString *)path
{
    NSArray *pathArray = [path componentsSeparatedByString:SIM_PathSeparator];
    NSEnumerator *enumerator;
    id keyObject;
    id currentObject = self;

    if([pathArray count] > 1){
        enumerator = [pathArray objectEnumerator];
        //[enumerator nextObject];
        while ((keyObject = [enumerator nextObject]) && [currentObject respondsToSelector:@selector(objectForKey:)]){
            if([keyObject isEqual:@""])continue;
            currentObject = [currentObject objectForKey:keyObject];
            if(!currentObject){
                NSLog(@"No object found at:%@ in path: %@",keyObject,path);
                break;
            }
        }
    }
    return currentObject;
}


@end

@implementation NSMutableDictionary (SIMMutableDictionaryExtensions)

- (void) updateParameterValues
{
    NSNotification *notification = [NSNotification notificationWithName:SIMParameterDidChangeNotification object:self];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle: NSPostASAP
        coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
}

- (void)setRect:(NSRect)rect forKey:(NSString *)key
{
    [self setObject:NSStringFromRect(rect) forKey:key];
}

- (void)setSize:(NSSize)size forKey:(NSString *)key
{
    [self setObject:NSStringFromSize(size) forKey:key];
}

- (void)setPoint:(NSPoint)point forKey:(NSString *)key
{
    [self setObject:NSStringFromPoint(point) forKey:key];
}

- (void) setInt:(int)val forKey:(NSString *)key
{
	[self setObject:[NSString stringWithFormat:@"%d",val] forKey:key];
}

- (void) setFloat:(float)val forKey:(NSString *)key
{
    [self setObject:[NSString stringWithFormat:@"%g",val] forKey:key];
}

- (void) setDouble:(double)val forKey:(NSString *)key
{
    [self setObject:[NSString stringWithFormat:@"%g",val] forKey:key];
}

- (void)setBool:(BOOL)val forKey:(NSString *)key
{
    [self setObject:val ? @"Yes":@"No" forKey:key];
}

@end

@implementation NSCoder (SIMCoderExtensions)

- (void) decodeStateValue:(SIMStateValue *)value
{    
    [self decodeValueOfObjCType:@encode(SIMValueType) at:&value->type];
    
    switch (value->type) {
	case SIMDoubleType:
            [self decodeValueOfObjCType:@encode(double) at:&value->state.doubleValue];
            break;
	case SIMFloatType:
            [self decodeValueOfObjCType:@encode(float) at:&value->state.floatValue];
            break;
	case SIMActivityType:
            [self decodeValueOfObjCType:@encode(SIMActivityStateValue) at:&value->state.activityValue];
            break;
	case SIMObjectType:
            if(value->state.objectValue != nil){
                [value->state.objectValue release];
            }
            value->state.objectValue = [[self decodeObject] retain];
            break;
        case SIMUnsignedType:
            [self decodeValueOfObjCType:@encode(unsigned) at:&value->state.unsignedValue];
            break;
	case SIMBooleanType:
            [self decodeValueOfObjCType:@encode(BOOL) at:&value->state.booleanValue];
            break;
	case SIMIntegerType:
            [self decodeValueOfObjCType:@encode(int) at:&value->state.intValue];
            break;
        case SIMLongType:
            [self decodeValueOfObjCType:@encode(long) at:&value->state.longValue];
            break;
        default:
            NSLog(@"ERROR: Could not decode state value of unknown type.");
            break;
    }
}

- (void) encodeStateValue:(SIMStateValue *)value
{
    [self encodeValueOfObjCType:@encode(SIMValueType) at:&value->type];
    
    switch (value->type) {
	case SIMDoubleType:
            [self encodeValueOfObjCType:@encode(double) at:&value->state.doubleValue];
            break;
	case SIMFloatType:
            [self encodeValueOfObjCType:@encode(float) at:&value->state.floatValue];
            break;
	case SIMActivityType:
            [self encodeValueOfObjCType:@encode(SIMActivityStateValue) at:&value->state.activityValue];
            break;
	case SIMObjectType:
            [self encodeObject:value->state.objectValue];
            break;
        case SIMUnsignedType:
            [self encodeValueOfObjCType:@encode(unsigned) at:&value->state.unsignedValue];
            break;
	case SIMBooleanType:
            [self encodeValueOfObjCType:@encode(BOOL) at:&value->state.booleanValue];
            break;
	case SIMIntegerType:
            [self encodeValueOfObjCType:@encode(int) at:&value->state.intValue];
            break;
        case SIMLongType:
            [self encodeValueOfObjCType:@encode(long) at:&value->state.longValue];
            break;
        default:
            NSLog(@"ERROR: Could not encode state value of unknown type.");
            break;
    }
}

- (void) encodeConnection:(SIMConnection *)connection
{
    [self encodeValueOfObjCType:@encode(short int) at:&connection->dx];
    [self encodeValueOfObjCType:@encode(short int) at:&connection->dy];
    [self encodeValueOfObjCType:@encode(short int) at:&connection->dz];
    [self encodeValueOfObjCType:@encode(float) at:&connection->strength];
#ifdef CONNECTION_LATENCIES
    [self encodeValueOfObjCType:@encode(float) at:&connection->latency];
#endif
    
    [self encodeValueOfObjCType:@encode(short int) at:&connection->channelCount];
    if(connection->channelCount)[self encodeArrayOfObjCType:@encode(short int) count:connection->channelCount at:connection->channels];
}

- (void) decodeConnection:(SIMConnection *)connection
{
    [self decodeValueOfObjCType:@encode(short int) at:&connection->dx];
    [self decodeValueOfObjCType:@encode(short int) at:&connection->dy];
    [self decodeValueOfObjCType:@encode(short int) at:&connection->dz];
    [self decodeValueOfObjCType:@encode(float) at:&connection->strength];
#ifdef CONNECTION_LATENCIES
    [self decodeValueOfObjCType:@encode(float) at:&connection->latency];
#endif

    [self decodeValueOfObjCType:@encode(short int) at:&connection->channelCount];
    connection->channels = NSZoneMalloc([self zone],(connection->channelCount)*sizeof(short int));
    if(connection->channelCount)[self decodeArrayOfObjCType:@encode(short int) count:connection->channelCount at:connection->channels];
}

/*
- (void) encodeConnectionStates:(SIMConnectionState *)channels count:(int)count
{
    int i;
    
    for(i = 0; i < count; i++){
        [self encodeValueOfObjCType:@encode(int) at:&channels->index];
        [self encodeStateValue:&channels->state];
    }
}
*/

- (void) encodeConnections:(NSValueArray *)connections
{
    const SIMConnection *bytes = [connections bytes];
    int i,count = [connections count];
                
    [self encodeValueOfObjCType:@encode(int) at:&count];
    
    for(i = 0; i < count; i++){
        [self encodeConnection:(void *)&bytes[i]];
    }
}

- (NSValueArray *) decodeConnections
{
    NSValueArray *connections;
    SIMConnection *bytes;
    int i,count;

    [self decodeValueOfObjCType:@encode(int) at:&count];
    
    bytes = NSZoneMalloc([self zone],count*sizeof(SIMConnection));
    
    for(i = 0; i < count; i++){
        [self decodeConnection:&bytes[i]];
    }
    
    connections = [[NSMutableValueArray alloc] initWithValues:bytes count:count withObjCType:@encode(SIMConnection)];
    
    return [connections autorelease];
 }

@end