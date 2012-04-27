/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <Foundation/Foundation.h>
#import <PseudoRandomNum/PRNGenerator.h>
#import <SynthesisCore/Simulator.h>

@interface SIMObject : NSObject <NSCoding,SIMInspectable>
{
    NSMutableDictionary *mainDictionary;
    NSMutableDictionary *parameterDictionary;
    NSMutableArray *clients;
}

- init;
- initWithDescription:(NSDictionary *)aDescription;

- (void) updateParameterValues;
- (void) updateParameters;
- (NSString *) description;

- (BOOL) boolForKey:(NSString *)key;
- (int) intForKey:(NSString *)key;
- (float) floatForKey:(NSString *)key;
- (double) doubleForKey:(NSString *)key;

- (NSDictionary *)parameterDictionary;

- (void) dealloc;

- (id) initWithCoder:(NSCoder *)coder;
- (void) encodeWithCoder: (NSCoder *) coder;

- (void)addClient:aClient forNotificationName:(NSString *)name selector:(SEL)aSelector object:anObject;
- (void)removeClient:aClient forNotificationName:(NSString *)name object:anObject;
- (void)removeClient:aClient;
- (void)removeAllClients:sender;
- (void)removeAllClients;

@end