
#import "NSValueArray.h"
#import <Foundation/NSData.h>
#import <Foundation/NSArchiver.h>
#import <Foundation/NSException.h>

#define raiseInvalidInitMessage() [NSException raise:NSInvalidArgumentException format:@"*** initialization method %s cannot be sent to an abstract object of class %@: Create an [sic] concrete instance!", sel_getName( _cmd), [[self class] description]]

#define raiseInvalidMessage() [NSException raise:NSInvalidArgumentException format:@"*** method %s cannot be sent to an abstract object of class %@: Create an [sic] concrete instance!", sel_getName( _cmd), [[self class] description]]

    // Private interfaces for value arrays.
@interface NSConcreteValueArray : NSValueArray
{
    NSString *objCType;
    unsigned valueSize;
    NSData *storage;
}
@end
@interface NSConcreteMutableValueArray : NSMutableValueArray
{
    NSString *objCType;
    unsigned valueSize;
    NSMutableData *storage;
}
@end

// Implementations for abstract value array classes.  These
// provide default behaviour and exceptions when default
// behavior is not sensible.
@implementation NSValueArray
+ allocWithZone:(NSZone *)zone
{
	// If this message is being sent to NSValueArray itself,
	// use NSConcreteValueArray instead.
    if( [self class]==[NSValueArray class]) {
	return [NSConcreteValueArray allocWithZone:zone];
    } else {
	return [super allocWithZone:zone];
    }
}

+ valueArray:(const void *)values count:(unsigned)count withObjCType:(const char *)type
{
    return [[[self alloc] initWithValues:values count:count withObjCType:type] autorelease];
}

- initWithValues:(const void *)values count:(unsigned)count withObjCType:(const char *)type
{
    [self autorelease];
    raiseInvalidInitMessage();
    return nil;
}

-(void)getValue:(void *)value atIndex:(unsigned)index
{
    raiseInvalidMessage();
}

- (NSValueArray *)valueArrayFromRange:(NSRange)range
{
    raiseInvalidMessage();
    return (NSValueArray *)nil;
}

-(const char *)objCType
{
    raiseInvalidMessage();
    return NULL;
}
-(unsigned)valueSize
{
    raiseInvalidMessage();
    return 0;
}
-(BOOL)hasNumberValues
{
	return NO;
}
-(const void *)bytes
{
    raiseInvalidMessage();
    return NULL;
}

- copyFromZone:(NSZone *)zone
{
    return [[NSValueArray allocWithZone:zone] initWithValues:[self bytes] count:(unsigned int)[self count] withObjCType:[self objCType]];
}

- mutableCopy
{
    return [self mutableCopyFromZone:[self zone]];
}

- mutableCopyFromZone:(NSZone *)zone
{
    return [[NSMutableValueArray allocWithZone:zone] initWithValues:[self bytes] count:(unsigned int)[self count] withObjCType:[self objCType]];
}

@end


@implementation NSMutableValueArray
+ allocWithZone:(NSZone *)zone
{
	// If this message is being sent to NSMutableValueArray itself,
	// use NSConcreteMutableValueArray instead.
    if( [self class]==[NSMutableValueArray class]) {
	return [NSConcreteMutableValueArray allocWithZone:zone];
    } else {
	return [super allocWithZone:zone];
    }
}

+ valueArray:(const void *)values count:(unsigned)count withObjCType:(const char *)type
{
    return [[[self alloc] initWithValues:values count:count withObjCType:type] autorelease];
}

+(id)valueArrayWithObjCType:(const char *)type
{
    return [[[self alloc] initWithValues:&self count:0 withObjCType:type] autorelease];
}

+(id)valueArrayWithCount:(unsigned)count withObjCType:(const char *)type
{
    return [[[self alloc] initWithCount:count withObjCType:type] autorelease];
}

- initWithValues:(const void *)values count:(unsigned)count withObjCType:(const char *)type
{
    [self autorelease];
    raiseInvalidInitMessage();
    return nil;
}

- initWithCount:(unsigned)count withObjCType:(const char *)type
{
    [self autorelease];
    raiseInvalidInitMessage();
    return nil;
}

-(void)getValue:(void *)value atIndex:(unsigned)index
{
    raiseInvalidMessage();
}

- (NSMutableValueArray *)valueArrayFromRange:(NSRange)range
{
    raiseInvalidMessage();
    return (NSMutableValueArray *)nil;
}

-(const char *)objCType
{
    raiseInvalidMessage();
    return NULL;
}
-(unsigned)valueSize
{
    raiseInvalidMessage();
    return 0;
}
-(BOOL)hasNumberValues
{
	return NO;
}
-(const void *)bytes
{
    raiseInvalidMessage();
    return NULL;
}
-(void *)mutableBytes
{
    raiseInvalidMessage();
    return NULL;
}
-(void)addValue:(const void *)value
{
    [self addValues:value count:1];
}

-(void)addValues:(const void *)values count:(unsigned)count
{
    raiseInvalidMessage();
}

-(void)replaceValue:(const void *)value atIndex:(unsigned)index
{
    raiseInvalidMessage();
}
-(void)insertValue:(const void *)value atIndex:(unsigned)index
{
    raiseInvalidMessage();
}
-(void)removeValueAtIndex:(unsigned)index
{
    raiseInvalidMessage();
}
-(void)addObject:anObject
{
    NSMutableData *value = [NSMutableData dataWithCapacity:[self valueSize]];
    
	// Make certain it's an NSValue of the appropriate type.
    NSAssert( [anObject isKindOfClass:[NSValue class]],@"Objects must be NSValues.");
    NSAssert( !strcmp( [self objCType], [anObject objCType]),@"NSValues must be of the same type.");

    [anObject getValue:[value mutableBytes]];
    [self addValue:[value mutableBytes]];
}

-(void)replaceObjectAtIndex:(unsigned)index withObject:anObject
{
    NSMutableData *value = [NSMutableData dataWithCapacity:[self valueSize]];
    
	// Make certain it's an NSValue of the appropriate type.
    NSAssert( [anObject isKindOfClass:[NSValue class]],@"Objects must be NSValues.");
    NSAssert( !strcmp( [self objCType], [anObject objCType]),@"NSValues must be of the same type.");
    
    [anObject getValue:[value mutableBytes]];
    [self replaceValue:[value mutableBytes] atIndex:index];
}

-(void)insertObject:anObject atIndex:(unsigned)index
{
    NSMutableData *value = [NSMutableData dataWithCapacity:[self valueSize]];

    // Make certain it's an NSValue of the appropriate type.
    NSAssert( [anObject isKindOfClass:[NSValue class]],@"Objects must be NSValues.");
    NSAssert( !strcmp( [self objCType], [anObject objCType]),@"NSValues must be of the same type.");
    
    [anObject getValue:[value mutableBytes]];
    [self insertValue:[value mutableBytes] atIndex:index];
}

-(void)removeObjectAtIndex:(unsigned)index
{
    [self removeValueAtIndex:index];
}

-(void)removeLastObject
{
    [self removeObjectAtIndex:[self count]-1];
}

// Should this make immutable copies of contents?  _Can_ it?

- copyFromZone:(NSZone *)zone
{
    return [[NSValueArray allocWithZone:zone] initWithValues:[self bytes] count:[self count] withObjCType:[self objCType]];
}

- mutableCopy
{
    return [self mutableCopyFromZone:[self zone]];
}

- mutableCopyFromZone:(NSZone *)zone
{
    return [[NSMutableValueArray allocWithZone:zone] initWithValues:[self bytes] count:[self count] withObjCType:[self objCType]];
}

@end

@implementation NSConcreteValueArray

- initWithValues:(const void *)values count:(unsigned)count withObjCType:(const char *)type
{
    unsigned int size,dummy;
    NSGetSizeAndAlignment(type,&size,&dummy);

    self=[super init];
    if( self!=nil) {
	objCType=[[NSString stringWithUTF8String:type] retain];
	valueSize=size;
	storage=[[NSData alloc] initWithBytes:values length:count*valueSize];
    }
    return self;
}

- initWithObjects:(id *)objects count:(unsigned)count
{
    // TIMFIX from Mutable to NonMutable
    self = [[NSConcreteValueArray alloc] initWithObjects:objects count:count];
    return [[self autorelease] copy];
}

-(unsigned)count
{
	if(storage)return [storage length]/valueSize;
	return 0;
}

-(void)getValue:(void *)value atIndex:(unsigned)index
{
    NSAssert( index<[self count], @"Invalid index.");
    [storage getBytes:value range:NSMakeRange(index*valueSize,valueSize)];
}

- (NSValueArray *)valueArrayFromRange:(NSRange)range
{
    NSMutableData *values = [NSMutableData dataWithCapacity:range.length*valueSize];
    [storage getBytes:[values mutableBytes] range:NSMakeRange(range.location*valueSize,range.length*valueSize)];
    return [[NSValueArray alloc] initWithValues:[values mutableBytes] count:range.length withObjCType:[self objCType]];
}

-(const char *)objCType
{
    return [objCType UTF8String];
}

-(unsigned)valueSize
{
    return valueSize;
}

-(const void *)bytes
{
    return [storage bytes];
}

- objectAtIndex:(unsigned)index
{
    NSMutableData *value = [NSMutableData dataWithCapacity:[self valueSize]];

    NSAssert( index<[self count], @"Invalid index.");
    [storage getBytes:[value mutableBytes] range:NSMakeRange(index*valueSize,valueSize)];
    return [NSNumber value:[value mutableBytes] withObjCType:[self objCType]];
}

- classForCoder
{
    return [NSValueArray class];
}

- (id)initWithCoder:(NSCoder *)coder
{
    int count = 0;
    
    void *values = nil;
    unsigned int dummy;
    const char *type;

    objCType = [[coder decodeObject] retain];
    [coder decodeValueOfObjCType:@encode(int) at:&count];
    type = [objCType UTF8String];
            
    NSGetSizeAndAlignment(type,&valueSize,&dummy);
            
            
    NS_DURING
        values = NSZoneCalloc ([self zone], count, valueSize);
        if(count > 0)[coder decodeArrayOfObjCType:type count:count at:values];
    NS_HANDLER
        NSLog(@"ERROR: Couldn't decode stored array (%d,%d,%s).",count,valueSize,type);
        NSLog (@"%@",[localException name]);
        NSLog (@"%@",[localException reason]);
    NS_ENDHANDLER
    storage = [[NSMutableData alloc] initWithBytes:values length:count*valueSize];
        
    return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
    int count = [self count];

    NS_DURING
        [coder encodeObject:objCType];
        [coder encodeValueOfObjCType:@encode(int) at:&count];
        if(count > 0)[coder encodeArrayOfObjCType:[objCType UTF8String] count:count at:[storage bytes]];
    NS_HANDLER
        NSLog(@"ERROR: Couldn't encode stored array (%d,%d,%s).",count,valueSize,[objCType UTF8String]);
        NSLog (@"%@",[localException name]);
        NSLog (@"%@",[localException reason]);
    NS_ENDHANDLER

}

@end

@implementation NSConcreteMutableValueArray

- initWithValues:(const void *)values count:(unsigned)count withObjCType:(const char *)type
{
    // This line caused me a HUGE problem... used to be unsigned int: now it's 
    NSUInteger size,dummy;
    NSGetSizeAndAlignment(type,&size,&dummy);

    self=[super init];
    if( self!=nil) {
    
//#if !__LP64__
        objCType= [[NSString stringWithUTF8String:type] retain];
//#else
//        if (type == 0x100000000) {
//            objCType = @"";
//        }
//        else {
            objCType= [[NSString stringWithUTF8String:type] retain];
//        }
//#endif
	valueSize=size;
	storage = [[NSMutableData dataWithCapacity:count*valueSize] retain];
	if(values)[storage replaceBytesInRange:NSMakeRange(0,count*valueSize) withBytes:values];
    }
    return self;
}

- initWithObjects:(id *)objects count:(unsigned)count
{
    NSUInteger size, dummy;
    NSInteger i;

    //  This routine is dependent on the existence of NSGetSizeAndAlignment(type,size,align)
	
    objCType = [[NSString stringWithUTF8String:[objects[0] objCType]] retain];
    NSGetSizeAndAlignment([objCType UTF8String],&size,&dummy);
    valueSize = size;
    storage=[[NSMutableData dataWithCapacity:count*valueSize] retain];

    for(i=0;i<count;i++){
        [self addObject:objects[i]];
    }
    return self;
}

- initWithCount:(unsigned)count withObjCType:(const char *)type
{
    NSUInteger size,dummy;
    NSGetSizeAndAlignment(type,&size,&dummy);

    self=[super init];
    if( self!=nil) {
	objCType= [[NSString stringWithUTF8String:type] retain];
	valueSize=size;
	storage = [[NSMutableData dataWithLength:count*valueSize] retain];
    }
    return self;
}

-(unsigned)count
{
	if(storage)return [storage length]/valueSize;
	return 0;
}

- objectAtIndex:(unsigned)index
{
    NSMutableData *value = [NSMutableData dataWithCapacity:[self valueSize]];
    
    NSAssert( index<[self count], @"Invalid index.");
    [storage getBytes:[value mutableBytes] range:NSMakeRange(index*valueSize,valueSize)];
    return [NSNumber value:[value mutableBytes] withObjCType:[self objCType]];
}

-(void)getValue:(void *)value atIndex:(unsigned)index
{
    NSAssert( index<[self count], @"Invalid index.");
    [storage getBytes:value range:NSMakeRange(index*valueSize,valueSize)];
}

- (NSMutableValueArray *)valueArrayFromRange:(NSRange)range
{
    NSMutableData *values = [NSMutableData dataWithCapacity:range.length*valueSize];
    [storage getBytes:[values mutableBytes] range:NSMakeRange(range.location*valueSize,range.length*valueSize)];
    return [[NSMutableValueArray alloc] initWithValues:[values mutableBytes] count:range.length withObjCType:[self objCType]];
}

-(const char *)objCType
{
    return [objCType UTF8String];
}
-(unsigned)valueSize
{
    return valueSize;
}

-(const void *)bytes
{
    return [storage bytes];
}

-(void *)mutableBytes
{
    return [storage mutableBytes];
}

-(void)addValues:(const void *)values count:(unsigned)count
{    
    // Add space to storage and put the value in there.
    [storage appendBytes:values length:valueSize*count];
}

-(void)replaceValue:(const void *)value atIndex:(unsigned)index
{    
    NSAssert( index<[self count], @"Invalid index.");
    // Overlay the value on existing data.
    [storage replaceBytesInRange:NSMakeRange(index*valueSize,valueSize) withBytes:value];
}

-(void)insertValue:(const void *)value atIndex:(unsigned)index
{
    NSRange fromRange,toRange;
    NSMutableData *bytes;
    
    // Make certain the index is not too big.This is <= because we would like
    // to be able to insert an object into an empty array.  The size increase is handled
    // so it should be ok.
    NSAssert( index<=[self count], @"Invalid index.");
    
    // Add space to storage and insert the value somewhere inside.
    [storage increaseLengthBy:valueSize];
	
    fromRange.location = index*valueSize;
    fromRange.length = [storage length]-fromRange.location;
    toRange.location = (index+1)*valueSize;
    toRange.length = fromRange.length;

    bytes = [NSMutableData dataWithCapacity:fromRange.length];
    
    if([storage length]>0){
        [storage getBytes:[bytes mutableBytes] range:fromRange];
        [storage replaceBytesInRange:toRange withBytes:[bytes mutableBytes]];
    }
    fromRange.length = valueSize;
    [storage replaceBytesInRange:fromRange withBytes:value];
}

-(void)removeValueAtIndex:(unsigned)index
{
    NSRange fromRange,toRange;
    int newLength = [storage length]-valueSize;
    NSMutableData *bytes;
    
    NSAssert( index<[self count], @"Invalid index.");

    fromRange.location = (index+1)*valueSize;
    fromRange.length = [storage length]-fromRange.location;
    toRange.location = (index)*valueSize;
    toRange.length = fromRange.length;

    bytes = [NSMutableData dataWithCapacity:fromRange.length];

    if([storage length]>0){
        [storage getBytes:[bytes mutableBytes] range:fromRange];
        [storage replaceBytesInRange:toRange withBytes:[bytes mutableBytes]];
    }
    [storage setLength:newLength];
}

- classForCoder
{
    return [NSMutableValueArray class];
}

- (id)initWithCoder:(NSCoder *)coder
{
    int count = 0;
    
    void *values = nil;
    unsigned int dummy;
    const char *type;

    objCType = [[coder decodeObject] retain];
    [coder decodeValueOfObjCType:@encode(int) at:&count];
    type = [objCType UTF8String];
            
    NSGetSizeAndAlignment(type,&valueSize,&dummy);
            
            
    NS_DURING
        values = NSZoneCalloc ([self zone], count, valueSize);
        if(count > 0)[coder decodeArrayOfObjCType:type count:count at:values];
    NS_HANDLER
        NSLog(@"ERROR: Couldn't decode stored array (%d,%d,%s).",count,valueSize,type);
        NSLog (@"%@",[localException name]);
        NSLog (@"%@",[localException reason]);
    NS_ENDHANDLER
    storage = [[NSMutableData alloc] initWithBytes:values length:count*valueSize];
        
    return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
    int count = [self count];
    
    NS_DURING
        [coder encodeObject:objCType];
        [coder encodeValueOfObjCType:@encode(int) at:&count];
        if(count > 0)[coder encodeArrayOfObjCType:[objCType UTF8String] count:count at:[storage bytes]];
    NS_HANDLER
        NSLog(@"ERROR: Couldn't encode stored array. (%d,%d,%s).",count,valueSize,[objCType UTF8String]);
		NSLog (@"%@",[self description]);
        NSLog (@"%@",[localException name]);
        NSLog (@"%@",[localException reason]);
    NS_ENDHANDLER
    
}

@end

// This category was added so that in case a value could be a NSNumber
// (which is a subclass of NSValue) it _will_be_ a NSNumber.
// This allows efficient convenient storage of numbers in an array.

@implementation NSNumber (NSValueArrayNumberExtensions)

+ (NSValue *)value:(const void *)value withObjCType:(const char *)type
/* Creation method */
{
	if(!strcmp(type,@encode(char)))
		return [NSNumber numberWithChar:*(char *)value];
	if(!strcmp(type,@encode(double)))
		return [NSNumber numberWithDouble:*(double *)value];
	if(!strcmp(type,@encode(float)))
		return [NSNumber numberWithFloat:*(float *)value];
	if(!strcmp(type,@encode(int)))
		return [NSNumber numberWithInt:*(int *)value];
	if(!strcmp(type,@encode(BOOL)))
		return [NSNumber numberWithBool:*(BOOL *)value];
	if(!strcmp(type,@encode(long)))
		return [NSNumber numberWithLong:*(long *)value];
	if(!strcmp(type,@encode(long long)))
		return [NSNumber numberWithLongLong:*(long long *)value];
	if(!strcmp(type,@encode(short)))
		return [NSNumber numberWithShort:*(short *)value];
	if(!strcmp(type,@encode(unsigned char)))
		return [NSNumber numberWithUnsignedChar:*(unsigned char *)value];
	if(!strcmp(type,@encode(unsigned int)))
		return [NSNumber numberWithUnsignedInt:*(unsigned int *)value];
	if(!strcmp(type,@encode(unsigned long)))
		return [NSNumber numberWithUnsignedLong:*(unsigned long *)value];
	if(!strcmp(type,@encode(unsigned long long)))
		return [NSNumber numberWithUnsignedLongLong:*(unsigned long long *)value];
	if(!strcmp(type,@encode(unsigned short)))
		return [NSNumber numberWithUnsignedShort:*(unsigned short *)value];

	return [NSValue value:value withObjCType:type];
}

@end