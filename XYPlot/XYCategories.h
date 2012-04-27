#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSData.h>
#import <Foundation/NSValue.h>
#import <AppKit/AppKit.h>

@interface NSString (XYStringExtensions)

- (BOOL)boolValue;
- (NSColor *)colorValue;

- (NSRect)rectValue;
- (NSPoint)pointValue;
- (NSSize)sizeValue;
@end


@interface NSDictionary (XYDictionaryExtensions)


- (BOOL)boolForKey:(NSString *)key;
- (int)intForKey:(NSString *)key;
- (float)floatForKey:(NSString *)key;
- (double)doubleForKey:(NSString *)key
;
- (NSColor *)colorForKey:(NSString *)key;
- (NSRect)rectForKey:(NSString *)key;
- (NSPoint)pointForKey:(NSString *)key;
- (NSSize)sizeForKey:(NSString *)key;
- (NSFont *)fontForKey:(NSString *)key;

@end 

@interface NSMutableDictionary (XYMutableDictionaryExtensions)

- (void)setFont:(NSFont *)font forKey:(NSString *)key;
- (void)setRect:(NSRect)rect forKey:(NSString *)key;
- (void)setSize:(NSSize)size forKey:(NSString *)key;
- (void)setPoint:(NSPoint)point forKey:(NSString *)key
;
@end
