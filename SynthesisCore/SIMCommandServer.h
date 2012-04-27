/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */


#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisCore/SIMNetworkTopology.h>

#define NETWORK_KEY			@"Network"
#define STATE_KEY			@"State"
#define SCRIPT_KEY			@"Script"
#define EXPERIMENT_KEY			@"Experiment"
#define AUTOSTART_KEY			@"Autostart"
#define SERVER_KEY			@"Server"

@interface SIMCommandServer : NSObject
{
    SIMNetwork *network;
    NSMutableArray *nodes;
    NSMutableArray *clients;
    NSMutableString *currentPath;
    NSString *serverName;
    BOOL running,timingFlag;
    int localNode;
    float stopTime;
    float updateInterval;
    NSTimer *runTimer;
    NSDate *startDate,*timingDate;
    NSLock *lock;
}

+ (void) runNetworkServer;
+ (int) numberOfProcessors;
- initWithNodeIdentifier:(int)nodeID;
- initWithNetworkDescription:(NSDictionary *)dict node:(int)nodeID;
- (void)registerNode;

- (void) loadNetworkWithDescription:(NSDictionary *)dict;
- (void) loadExperimentWithDescription:(NSDictionary *)dict;
- (SIMCommandServer *)_connectToNode:(NSDictionary *)nodeInfo;
- (id)interpretCommand:(NSString *)commandString;
- (BOOL) interpretScript:(NSString *)script;
- (int) nodeIdentifier;
- currentObject;
- currentPath;
- (void)setCurrentPath:(NSString *)path;
- (SIMNetwork *) network;
- (void)run;
- (void)stop;
- (void)terminate;
- (unsigned) hostByteOrder;
- (NSDate *)startDate;
- (BOOL) isRunning;
- (void)update;

- (NSMutableDictionary *)rootDictionary;
- (void)serverConnectionDidDie:(NSNotification *)n;
- (void)clientConnectionDidDie:(NSNotification *)n;
- (void)addClient:aClient forNotificationName:(NSString *)name selector:(SEL)aSelector object:anObject;
- (void)removeClient:aClient forNotificationName:(NSString *)name object:anObject;
- (void)removeClient:aClient;
- (void)removeAllClients;
- (void)removeAllClients:sender;
- (int) clientCount;

@end


