/* SIMClientController.m created by hill on Wed 29-Jan-1997 */

#import "SIMClientController.h"

@implementation SIMClientController

- init
{
    NSString *server,*host,*script;
 
    printf("--          S Y N T H E S I S   T o o l              --\n");
    printf("--             by Sean Hill (c) 2006                 --\n");
    printf("--      Launched at: %s       --\n",[[[NSDate date] description] UTF8String]);    

    [SIMCommandClient runCommandPrompt];

    return self;
}


- (void) showUsage
{
    printf("Usage:\n");
    printf("-Network <filename>\t---- loads model network in <filename>\n");
    printf("-Experiment <filename>\t---- loads experiment configuration in <filename>\n");
    printf("-Autostart <Y|N>\t---- should automatically start running network/experiment\n");
    printf("-ServerName <servername>\t---- registers server on network using <servername>\n");
    printf("\n");
}

/*
- (void) dealloc
{
    if(running)[self stop];
    [runTimer release];
	[network release];
	[clients release];
    return [super dealloc];
}
*/

@end