#import "XYCategories.h"

/* OPENSTEP VERSION */

#define XY_DEFAULTCOLORLIST	@"Apple"

@implementation NSString (XYStringExtensions)

- (BOOL)boolValue
{
    // If the string begins with a 'y' or 'Y' or contains an integer greater than 0 return YES!
    if( [[self uppercaseString] isEqual:@"YES"] || 
	[[self uppercaseString] isEqual:@"Y"] || 
	([self intValue]>0))
	 return YES;
    return NO;
}

- (NSColor *)colorValue
{
return [[NSColorList colorListNamed:XY_DEFAULTCOLORLIST] colorWithKey:self];
}

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
@end

@implementation NSDictionary (XYDictionaryExtensions)

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
        float aDouble=0.0;
        id	value = [self objectForKey:key];

        if([value respondsToSelector:@selector(doubleValue)])
            aDouble = [value doubleValue];
        return aDouble;
}

- (NSColor *)colorForKey:(NSString *)key
{
        NSColor *aColor = [NSColor clearColor];
        id	value = [self objectForKey:key];

        if([value respondsToSelector:@selector(colorValue)])
                aColor = [value colorValue];
        return aColor;
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

- (NSFont *)fontForKey:(NSString *)key
{
        NSFont *aFont = nil;
 // Default font
        NSString *fontname;
        float size;
        id value = [self objectForKey:key];

        if([value isKindOfClass:[NSDictionary class]]){
                fontname = [value objectForKey:@"name"];
                size = [[value objectForKey:@"pointSize"] floatValue];
                [aFont release];
                aFont = [NSFont fontWithName:fontname size:size];
                [aFont retain];
        }
        return aFont;
}

@end

@implementation NSMutableDictionary (XYMutableDictionaryExtensions)

- (void)setFont:(NSFont *)font forKey:(NSString *)key
{
    [self setObject:
	[[NSString stringWithFormat:@"{name = \"%@\"; pointSize = \"%g pt\"; }",
		[font pointSize],[font fontName]]
 propertyList]
        forKey:key];
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
@end

