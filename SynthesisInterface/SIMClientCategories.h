#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSData.h>
#import <Foundation/NSValue.h>
#import <AppKit/AppKit.h>

@interface NSString (SIMClientStringExtensions)

- (NSColor *)colorValue;

@end


@interface NSDictionary (SIMClientDictionaryExtensions)
- (NSColor *)colorForKey:(NSString *)key;
- (NSFont *)fontForKey:(NSString *)key;
@end 

@interface NSMutableDictionary (SIMClientMutableDictionaryExtensions)

- (void)setFont:(NSFont *)font forKey:(NSString *)key;
// Should implement a setColor:forKey: method
@end

@interface NSCell (SIMCellNumberExtensions)
- (NSNumber *)intNumber;
- (NSNumber *)floatNumber;
- (NSNumber *)doubleNumber;
@end

@interface NSControl (SIMControlNumberExtensions)
- (NSNumber *)intNumber;
- (NSNumber *)floatNumber;
- (NSNumber *)doubleNumber;
@end

@interface NSTabView (SIMTabViewExtensions)
- (void)addView:(NSView *)view withLabel:(NSString *)title;
@end
