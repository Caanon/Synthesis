#import "SIMClientCategories.h"

/* OPENSTEP VERSION */

#define SIM_DEFAULTCOLORLIST	@"Apple"

@implementation NSString (SIMClientStringExtensions)

- (NSColor *)colorValue
{
/*
    if([self isEqual:@"Black"])return [NSColor blackColor];
    if([self isEqual:@"DarkGray"])return [NSColor darkGrayColor];
    if([self isEqual:@"LightGray"])return [NSColor lightGrayColor];
    if([self isEqual:@"White"])return [NSColor whiteColor];
    if([self isEqual:@"Gray"])return [NSColor grayColor];
    if([self isEqual:@"Red"])return [NSColor redColor];
    if([self isEqual:@"Green"])return [NSColor whiteColor];
    if([self isEqual:@"Blue"])return [NSColor blueColor];
    if([self isEqual:@"Cyan"])return [NSColor cyanColor];
    if([self isEqual:@"Yellow"])return [NSColor yellowColor];
    if([self isEqual:@"Magenta"])return [NSColor magentaColor];
    if([self isEqual:@"Orange"])return [NSColor orangeColor];
    if([self isEqual:@"Purple"])return [NSColor purpleColor];
    if([self isEqual:@"Brown"])return [NSColor brownColor];
    if([self isEqual:@"Clear"])return [NSColor clearColor];
 */
   return [[NSColorList colorListNamed:SIM_DEFAULTCOLORLIST] colorWithKey:self];
}

@end

@implementation NSDictionary (SIMClientDictionaryExtensions)

- (NSColor *)colorForKey:(NSString *)key
{
        NSColor *aColor = [NSColor clearColor];
        id	value = [self objectForKey:key];

        if([value respondsToSelector:@selector(colorValue)])
                aColor = [value colorValue];
        return aColor;
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
                aFont = [NSFont fontWithName:fontname size:size
];
        }
        else {
            aFont = [NSFont fontWithName:@"Helvetica" size:12];
            [aFont retain];
        }
        return aFont;
}

@end

@implementation NSMutableDictionary (SIMClientMutableDictionaryExtensions)

- (void)setFont:(NSFont *)font forKey:(NSString *)key
{
    [self setObject:
	[[NSString stringWithFormat:@"{name = \"%@\"; pointSize = \"%g pt\"; }",
		[font pointSize],[font fontName]]
 propertyList]
        forKey:key];
}

@end


@implementation NSCell (SIMCellNumberExtensions)

- (NSNumber *)intNumber
{
    return [NSNumber numberWithInt:[self intValue]];
}

- (NSNumber *)floatNumber
{
    return [NSNumber numberWithFloat:[self floatValue]];
}

- (NSNumber *)doubleNumber
{
    return [NSNumber numberWithDouble:[self doubleValue]];
}

@end

@implementation NSControl (SIMControlNumberExtensions)

- (NSNumber *)intNumber
{
    return [NSNumber numberWithInt:[self intValue]];
}

- (NSNumber *)floatNumber
{
    return [NSNumber numberWithFloat:[self floatValue]];
}

- (NSNumber *)doubleNumber
{
    return [NSNumber numberWithDouble:[self doubleValue]];
}

@end

@implementation NSTabView (SIMTabViewExtensions)

- (void)addView:(NSView *)view withLabel:(NSString *)label
{
    NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:label];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [item setLabel:label];
    [item setView:view];
    [self addTabViewItem:item];
}

@end