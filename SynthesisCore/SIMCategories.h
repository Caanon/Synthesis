/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/Simulator.h>

/*"

These categories are designed to extend a number of common objects with capabilities needed for the SynthesisCore framework.
This includes extending NSString and NSDictionary to provide easy access to numeric values as well as data structures such
as NSRect, NSSize and NSPoint.

NSCoder is extended to handle archiving and unarchiving the key SIMState structures as well as SIMConnections.  These are
crucial to the ability to save the state of a network as well as serializing state variables for transport between simulator nodes.
"*/


@interface NSObject (SIMObjectExtensions)

- (NSString *)hostName;
- (NSString *)serverName;
- (unsigned) hostByteOrder;
- (id)classWithName:(NSString *)value ofType:(NSString *)bundleExtension;

@end

@interface NSString (SIMStringExtensions)

- (NSString *)lastSimulatorPathComponent;
- (NSArray *)simulatorPathComponents;
- (NSString *)stringByDeletingLastSimulatorPathComponent;
- (NSString *)stringByAppendingSimulatorPathComponent:(NSString *)string;


- (BOOL)boolValue;
- (unsigned int)hexValue;
- (NSRect)rectValue;
- (NSPoint)pointValue;
- (NSSize)sizeValue;
- (SEL)selectorValue;

@end


@interface NSDictionary (SIMDictionaryExtensions)

- (NSString *)stringForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (int)intForKey:(NSString *)key;
- (float)floatForKey:(NSString *)key;
- (double)doubleForKey:(NSString *)key;

- (unsigned int)hexForKey:(NSString *)key
;

- (NSRect)rectForKey:(NSString *)key;
- (NSPoint)pointForKey:(NSString *)key;
- (NSSize)sizeForKey:(NSString *)key;
- (SEL)selectorForKey:(NSString *)key;

- (id)classForKey:(NSString *)key;
- (id)classForKey:(NSString *)key ofType:(NSString *)bundleExtension;
- (id)cellClassForKey:(NSString *)key;
- (id)channelClassForKey:(NSString *)key;
- (id)connectionsClassForKey:(NSString *)key;
- (id)patternGeneratorClassForKey:(NSString *)key;
- (id)typeClassForKey:(NSString *)key;
- (id)agentClassForKey:(NSString *)key;

- (id)objectAtPath:(NSString *)path;


@end 

@interface NSMutableDictionary (SIMMutableDictionaryExtensions)
- (void)setRect:(NSRect)rect forKey:(NSString *)key;
- (void)setSize:(NSSize)size forKey:(NSString *)key;
- (void)setPoint:(NSPoint)point forKey:(NSString *)key;
- (void) setFloat:(float)val forKey:(NSString *)key;
- (void) setDouble:(double)val forKey:(NSString *)key;
- (void)setFloat:(float)val forKey:(NSString *)key;
- (void)setInt:(int)val forKey:(NSString *)key;
- (void)setBool:(BOOL)val forKey:(NSString *)key;
- (void) updateParameterValues;

@end

@interface NSCoder (SIMCoderExtensions)

- (void) encodeConnection:(SIMConnection *)c;
- (void) decodeConnection:(SIMConnection *)c;
- (void) encodeConnections:(NSValueArray *)connections;
- (NSValueArray *) decodeConnections;
- (void) decodeStateValue:(SIMStateValue *)value;
- (void) encodeStateValue:(SIMStateValue *)value;

@end
