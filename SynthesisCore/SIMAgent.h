/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMObject.h>
#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMCommandServer.h>

#define SIM_NOTIFICATION_KEY	@"NOTIFICATION"
#define SIM_SELECTOR_KEY	@"SELECTOR"

@interface SIMAgent : SIMObject
{
    SIMCommandServer *server;
    SIMNetwork *network;
    NSString *notificationName,*selectorName;
}

- initWithDescription:(NSDictionary *)desc forNetwork:(SIMNetwork *)net;
- (NSString *) filePathForKey:(NSString *)key;
- (BOOL)createDataDirectory;
- (void) setNetwork:(SIMNetwork *)net;
- (SIMNetwork *)network;
- (void) registerWithServer:(NSString *)sName onHost:(NSString *)hName;
- (void) startAgent;
- (void) stopAgent;
- (NSValueArray *)dataBuffer;
- (NSValueArray *)times;
- (float)dt;

- (NSString *) description;


@end
