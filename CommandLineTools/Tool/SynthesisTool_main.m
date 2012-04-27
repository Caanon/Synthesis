
#import <Foundation/Foundation.h>
#import "SIMClientController.h"

int main (int argc, const char *argv[])
{
   NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

   // insert your code here
    [[SIMClientController alloc] init];

   [pool release];
   exit(0);       // insure the process exit status is 0
   return 0;      // ...and make main fit the ANSI spec.
}
