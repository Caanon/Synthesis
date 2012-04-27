/* SIMClientController.h created by hill on Wed 29-Jan-1997 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisCore/SIMCommandClient.h>
#import <SynthesisCore/SIMCommandServer.h>

#define SERVER_KEY			@"Server"
#define HOST_KEY			@"Host"
#define SCRIPT_KEY			@"Script"

@interface SIMClientController : NSObject
{
    SIMCommandClient *commandInterpreter;
}

@end
