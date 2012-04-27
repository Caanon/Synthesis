#import <SynthesisCore/SIMCell.h>
#import <SynthesisCore/SIMType.h>
#import <SynthesisCore/SIMInputChannel.h>
#import <SynthesisCore/Simulator.h>
#import <PseudoRandomNum/PRNGenerator.h>

#define	AbsoluteRefractoryPeriod	@"AbsoluteRefractoryPeriod"
#define	RelativeRefractoryPeriod	@"RelativeRefractoryPeriod"
#define	MeanFiringRate			@"MeanFiringRate"

#define	Refractory			@"Refractory"

#define GeneratorSeed			@"GeneratorSeed"
#define DEFAULT_SEED			1000

@class PRNUniformGenerator, NSMutableValueArray;
@interface PoissonNeuron: SIMCell
{
    float		absoluteRefractoryPeriod, relativeRefractoryPeriod;
    float		meanFiringRate;
    unsigned int	refractory;
    PRNUniformGenerator	*generator;
}

@end
