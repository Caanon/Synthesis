/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMNetwork.h>

@interface SIMNetwork (SIMNetworkEditing)

- (void)sendParameterChangeNotification;

- (NSArray *)connectionsModels;
- (NSArray *)cellModels;
- (NSArray *)channelModels;

- (void)addLayerWithName:(NSString *)name;
- (void)addTypeWithName:(NSString *)name layer:(NSString *)layer;
- (void)addCellCompartment:(SIMCell *)cell withName:(NSString *)name type:(NSString *)type layer:(NSString *)layer;
- (void)addEfferentConnectionsWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer;
- (void)addAfferentConnectionsWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer;

- (void) setTypesDictionary:(NSMutableDictionary *)dict forLayerWithKey:(NSString *)key;

- (void)removeLayerWithName:(NSString *)name;
- (void)removeTypeWithName:(NSString *)name layer:(NSString *)layer;
- (void)removeCellCompartmentWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer ;
- (void)removeEfferentConnectionsWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer;
- (void)removeAfferentConnectionsWithName:(NSString *)name type:(NSString *)type layer:(NSString *)layer;

@end
