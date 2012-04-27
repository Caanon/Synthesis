#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMInputChannel.h>
#import <SynthesisCore/SIMCell.h>
#import <PseudoRandomNum/PRNGenerator.h>
#import <Desiderata/ITable.h>
#import <Desiderata/NSValueArray.h>

#define SYNCHANNEL_BINOMIAL		@"Binomial"
#define SYNCHANNEL_POISSON		@"Poisson"

#define SYNCHANNEL_MEAN_MINIAMPLITUDE	@"MeanMiniAmplitude"
#define SYNCHANNEL_STDEV_MINIAMPLITUDE	@"StdevMiniAmplitude"

#define SYNCHANNEL_TIMECONSTANT1	@"TimeConstant1"
#define SYNCHANNEL_TIMECONSTANT2	@"TimeConstant2"
#define SYNCHANNEL_GPEAK		@"gPeak"
#define SYNCHANNEL_REVERSALPOTENTIAL	@"ReversalPotential"
#define SYNCHANNEL_NOISERATE		@"NoiseRate"
#define SYNCHANNEL_NOISEAMPLITUDE	@"NoiseAmplitude"
#define SYNCHANNEL_NOISEMODE		@"NoiseMode"
#define SYNCHANNEL_CONDUCTANCETABLE	@"ConductanceTable"
#define SYNCHANNEL_NOISECUTOFFTABLE	@"NoiseCutoffTable"

#define SYNCHANNEL_G			@"G"
#define SYNCHANNEL_g			@"g"
#define SYNCHANNEL_dGdt			@"dGdt"

@class PRNUniformGenerator;

@interface SynChannel: SIMInputChannel
{
    id randomGenerator;    
    id miniGenerator;    
    
    // parameters
    double peakResponse;	/* peak response to a delta event */
    double peakConductance;	/* maximum effective conductance */
    double tc1;			/* first time constant of channel's response */
    double tc2;			/* second time constant */
    double reversalPotential;	/* channel's reversal potential */
    double noiseRate;		/* noisy activation rate */
    double noiseAmplitude;	/* noisy activation amplitude */
    double meanMiniAmplitude;	/* mean amplitude of a mini */
    double stdevMiniAmplitude;	/* stdev of amplitude of a mini */
    NSString *noiseMode;	/* noisy activation distribution type */
    NSString *conductancePath;
    NSString *noiseCutoffPath;
    ITable *conductanceTable;	/* interpolation table for channel conductance data */
    ITable *noiseCutoffTable;	/* interpolation table for noise cutoff */

    // state variable indices
    unsigned int G; /* channel's response */ 
    unsigned int g; /* effective conductance */
    unsigned int dGdt; /* intermediate variable to integrate G */
}

@end
