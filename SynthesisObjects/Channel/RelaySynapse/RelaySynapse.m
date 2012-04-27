#import "RelaySynapse.h"
#import <math.h>

@implementation RelaySynapse


- (void) setInitialValuesForState: (SIMState *) element 
{
/*"
    Initialize internal states to initial values.
"*/
    [super setInitialValuesForState: element];
    element->INPUTCHANNEL[INPUT_INDEX].state.doubleValue = 4*[stateGenerator uniformDeviate];
    element->INPUTCHANNEL[OUTPUT_INDEX].state.doubleValue = 4*[stateGenerator uniformDeviate];
}


- (void)updateFrom:(SIMState *)from 
		to:(SIMState *)to
		withConnection:(SIMConnection *)connection
		dt:(float)dt
		time:(float)time
{
    //[super updateFrom:from to:to withConnection:connection dt:dt time:time]; // call to support delayed connections
    to->INPUTCHANNEL[INPUT_INDEX].state.doubleValue += connection->strength;
}

- (void)updateState:(SIMState *)element
                dt:(float)dt
                time:(float)time
{
    [super updateState:element dt:dt time:time];
    element->INPUTCHANNEL[OUTPUT_INDEX].state.doubleValue = element->INPUTCHANNEL[INPUT_INDEX].state.doubleValue;
    element->INPUTCHANNEL[INPUT_INDEX].state.doubleValue = 0.0;
}
 
@end
