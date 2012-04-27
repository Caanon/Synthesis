/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMModel.h>
#import <SynthesisCore/SIMChannel.h>
#import <PseudoRandomNum/PRNGenerator.h>
#import <Desiderata/NSValueArray.h>
#import <math.h>

#define SIMInputStatisticsFlag	@"INPUT_STATISTICS"

#define	SIMInputState		@"InputState"
#define	SIMOutputState		@"OutputState"
#define SIMDelayKey		@"DELAY"
#define SIMActiveKey		@"Active"
#define SIMDistributionKey	@"Distribution"
#define SIMMeanKey		@"Mean"
#define SIMStdKey		@"Std"
#define SIMMinKey		@"Min"
#define SIMMaxKey		@"Max"

#define SIMChannelInputQueue	@"SIMChannelInputQueue"

typedef struct {
    float time;
    float strength;
} DelayedInput;

#define INPUTCHANNEL	inputChannel[_assignedIndex]
/*"
    The state of a channel should always be accessed by using element->INPUTCHANNEL[] rather than
    element->inputChannel[][].  This guarantees that you will access the state variables
    at the appropriate internal index for this model.
"*/

/*"
	The default random number generator seed value is defined in the SIMModel.template.  To override this place an entry
	like "STATE_GENERATOR_SEED = 2001;" in the parameter dictionary for the model.
"*/

@interface SIMInputChannel: SIMChannel
{
    BOOL DELAY;
    BOOL INPUT_STATISTICS;
    NSMutableDictionary *delayDictionary;
    PRNGaussianGenerator *_chanRandomDelayGenerator;
    float meanDelay,stdDelay;
#if !__LP64__
    unsigned int INPUT_QUEUE;
    unsigned int INPUT_INDEX;
    unsigned int INPUT_COUNT;
    unsigned int INPUT_WEIGHT;
    unsigned int INPUT_LATENCY;
#else
    unsigned long long INPUT_QUEUE;
    unsigned long long INPUT_INDEX;
    unsigned long long INPUT_COUNT;
    unsigned long long INPUT_WEIGHT;
    unsigned long long INPUT_LATENCY;
#endif
}

- (void) initializeConnection:(SIMConnection *)connection toState:(SIMState *)element;
- (int) totalNumberOfInputs:(SIMState *)element;
- (float) totalWeightOfInputs:(SIMState *)element;
- (float) totalLatencyOfInputs:(SIMState *)element;

- (void) updateFrom: (SIMState *) from to: (SIMState *) to
     withConnection: (SIMConnection *) connection dt: (float) timeStep time:(float) t;
- (double) channelCurrent: (SIMState *)element forCellModel:(SIMCell *)cellModel;
- (void) setInitialValuesForState: (SIMState *) element;
- (void) setRandomValuesForState: (SIMState *) element;
- (void) setNullValuesForState: (SIMState *) element;
- (void) allocState: (SIMState *) element;
- (void) reallocState:(SIMState *)state;
- (void) deallocState: (SIMState *) element;

@end

@interface SIMInputChannel (SIMChannelDelay)
- (void)_delaySetup;
- (void) _addToQueue: (DelayedInput *)t forElement: (SIMState *) element;
- (BOOL) _nextQueueValue:(DelayedInput *)t forElement: (SIMState *) element atTime:(float)t;
@end