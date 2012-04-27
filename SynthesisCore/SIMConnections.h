/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/SIMObject.h>
#import <SynthesisCore/SIMModel.h>

@class NSArray;
@class NSString;
@class NSDictionary;
@class NSValueArray;

@interface SIMConnections:SIMModel
{
}

+ (void)logConnections:(NSArray *)array;
+ (void)logConnection:(SIMConnection *)aConnection;
- (NSValueArray *)connections;
- (NSValueArray *)connectionsForPosition:(SIMPosition)pos;
- (NSValueArray *)connectionsTemplate;

@end
