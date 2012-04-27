
#import <Foundation/Foundation.h>
#import <SynthesisCore/Simulator.h>
#import "SIMNetworkController.h"



int main (int argc, const char *argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    id myController;

    [[NSRunLoop currentRunLoop] configureAsServer];

    myController = [[SIMNetworkController alloc] init]; 

    [[NSRunLoop currentRunLoop] run];

    [myController release];
    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec. 
}
  