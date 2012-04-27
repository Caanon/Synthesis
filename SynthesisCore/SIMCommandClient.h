/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisCore/SIMCommands.h>
#import <SynthesisCore/SIMCommandServer.h>

#define SERVER_KEY			@"Server"
#define SCRIPT_KEY			@"Script"
#define INTERACTIVE_KEY			@"Interactive"
#define HOST_KEY			@"Host"

#define SEPCHARS " ;{}'"

/*"
    Instances of this class connect to an instance of SIMCommandServer and provide an interactive command line interface
    for issuing commands to a simulation.
"*/

@interface SIMCommandClient : NSObject
{
    SIMCommandServer *server;
    NSFileHandle *inputHandle;
}

+ (void) runCommandPrompt;
- initWithServer:(NSString *)serverName host:(NSString *)hostName;
- (BOOL)registerWithServer:(NSString *)serverName host:(NSString *)hostName;

- loadScript:(NSArray *)argumentArray;
- (BOOL) interpretCommand:(NSString *)commandString;
- (BOOL) interpretScript:(NSString *)script;

- (NSString *)prompt;
- (void)runCommandPrompt;
- (void)runCommandPromptWithReadline;

- clientShellCommand:(NSArray *)argumentArray;
- disconnect:(NSArray *)argumentArray;
- connect:(NSArray *)argumentArray;

- (void) logEvents:(NSNotification *)n;
- (void) logErrors:(NSNotification *)n;


@end
