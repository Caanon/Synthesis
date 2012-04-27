/* SIMNetworkController.h created by hill on Wed 29-Jan-1997 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisCore/SIMCommandClient.h>
#import <SynthesisCore/SIMCommandServer.h>

#define NETWORK_KEY			@"Network"
#define STATE_KEY			@"State"
#define EXPERIMENT_KEY			@"Experiment"
#define AUTOSTART_KEY			@"Autostart"
#define SERVER_KEY			@"Server"
#define HOST_KEY			@"Host"
#define SCRIPT_KEY			@"Script"
#define INTERACTIVE_KEY			@"Interactive"

@interface SIMNetworkController : NSObject
{
    SIMCommandServer *commandController;
    //SIMCommandClient *commandInterpreter;
    //SIMNetwork *network;
    //SIMExperiment *experiment;
    //NSMutableArray *clients;
    //NSTimer *runTimer;
    //NSDate *startDate;
    //BOOL running,isExperiment;
}

- init;

@end
