#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMInputChannel.h>
#import <SynthesisCore/SIMCell.h>
#import <PseudoRandomNum/PRNGenerator.h>
#import <Desiderata/ITable.h>
#import <Desiderata/NSValueArray.h>

#define SYNNMDACHANNEL_BINOMIAL		@"Binomial"
#define SYNNMDACHANNEL_POISSON		@"Poisson"

#define SYNNMDACHANNEL_MEAN_MINIAMPLITUDE	@"MeanMiniAmplitude"
#define SYNNMDACHANNEL_STDEV_MINIAMPLITUDE	@"StdevMiniAmplitude"

#define SYNNMDACHANNEL_TIMECONSTANT1		@"TimeConstant1"
#define SYNNMDACHANNEL_TIMECONSTANT2		@"TimeConstant2"
#define SYNNMDACHANNEL_GPEAK			@"gPeak"
#define SYNNMDACHANNEL_REVERSALPOTENTIAL	@"ReversalPotential"
#define SYNNMDACHANNEL_NOISERATE		@"NoiseRate"
#define SYNNMDACHANNEL_NOISEAMPLITUDE		@"NoiseAmplitude"
#define SYNNMDACHANNEL_NOISEMODE		@"NoiseMode"
#define SYNNMDACHANNEL_CONDUCTANCETABLE		@"ConductanceTable"
#define SYNNMDACHANNEL_NOISECUTOFFTABLE		@"NoiseCutoffTable"
#define SYNNMDACHANNEL_MGTIMECONSTANTFAST	@"MgTimeConstantFast"
#define SYNNMDACHANNEL_MGTIMECONSTANTSLOW	@"MgTimeConstantSlow"



#define SYNNMDACHANNEL_G			@"G"
#define SYNNMDACHANNEL_g			@"g"
#define SYNNMDACHANNEL_dGdt			@"dGdt"
#define SYNNMDACHANNEL_MGUNBLOCKFAST		@"MgUnblockF"
#define SYNNMDACHANNEL_MGUNBLOCKSLOW		@"MgUnblockS"

@class PRNUniformGenerator;


/*"

When conductance table is active the channel will model a voltage and time based unblocking 
of the magnesium ion in the channel according to a two time constant equation from 
Vargas-Cabellero and Robinson, J. Neurophysiol: 89:2778-2783, 2003.  
Blocking of the channel occurs instantly if the voltage is lowered.

"*/


@interface SynNMDAChannelV1: SIMInputChannel
{
    id randomGenerator;    
    id miniGenerator;    
    
    // parameters
    double peakResponse;	/*" peak response to a delta event "*/
    double peakConductance;	/*" maximum effective conductance "*/
    double tc1;			/*" first time constant of channel's response "*/
    double tc2;			/*" second time constant "*/
    double reversalPotential;	/*" channel's reversal potential "*/
    double noiseRate;		/*" noisy activation rate "*/
    double noiseAmplitude;	/*" noisy activation amplitude "*/
    double meanMiniAmplitude;	/*" mean amplitude of a mini "*/
    double stdevMiniAmplitude;	/*" stdev of amplitude of a mini "*/
    double MgTCS;		/*" Mg block slow time constant "*/
    double MgTCF; 		/*" Mg block fast time constant "*/
    NSString *noiseMode;	/*" noisy activation distribution type "*/
    NSString *conductancePath;
    NSString *noiseCutoffPath;
    ITable *conductanceTable;	/*" interpolation table for channel conductance data "*/
    ITable *noiseCutoffTable;	/*" interpolation table for noise cutoff "*/

    // state variable indices
    unsigned int G; /*" channel's response "*/ 
    unsigned int g; /*" effective conductance "*/
    unsigned int dGdt; /*" intermediate variable to integrate G */
    unsigned int MgUnblockS; /*"Fraction of slow NMDA channels not blocked by magnesium"*/
    unsigned int MgUnblockF; /*"Fraction of slow NMDA channels not blocked by magnesium"*/

}

@end
