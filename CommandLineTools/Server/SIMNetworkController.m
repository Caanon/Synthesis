/* SIMNetworkController.m created by hill on Wed 29-Jan-1997 */

#import "SIMNetworkController.h"

@implementation SIMNetworkController

- init
{
    NSString *name;
    NSTimer *runTimer = [NSTimer timerWithTimeInterval:3.0
        target:[SIMCommandClient class]
        selector:@selector(runCommandPrompt)
        userInfo:nil
        repeats:NO];

    printf("--         S Y N T H E S I S   S e r v e r           --\n");
    printf("--              by Sean Hill (c) 2006                --\n");
    printf("--      Launched at: %s       --\n",[[[NSDate date] description] UTF8String]);    

    //[NSThread detachNewThreadSelector:@selector(runNetworkServer) toTarget:[SIMCommandServer class] withObject:nil];
    
#if 0
    name = [[NSUserDefaults standardUserDefaults] stringForKey:SERVER_NAME_KEY];
    if(!name){
        name = DEFAULT_SERVERNAME;
        [[NSUserDefaults standardUserDefaults] setObject:name forKey:SERVER_NAME_KEY];
    }

    commandController = [[SIMCommandServer alloc] init];

    [commandController runNetworkServer:name];
#endif

    [SIMCommandServer runNetworkServer];

    //[[NSRunLoop currentRunLoop] addTimer:runTimer forMode: NSDefaultRunLoopMode];
    return self;
}


- (void) showUsage
{
    printf("Usage:\n");
    printf("-Network <filename>\t---- loads model network in <filename>\n");
    printf("-State <filename>\t---- loads network state from <filename>\n");
    printf("-Script <filename>\t---- loads and executes script from <filename>\n");
    printf("-Experiment <filename>\t---- loads experiment configuration in <filename>\n");
    //printf("-Autostart <Y|N>\t---- should automatically start running network/experiment\n");
    printf("-ServerName <servername>\t---- registers server on network using <servername>\n");
    printf("\n");
}

@end