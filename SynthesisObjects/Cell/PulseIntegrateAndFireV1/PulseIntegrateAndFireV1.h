/*   PulseIntegrateAndFireV1
 *   by Sean Hill
 *   (c) 2003 All rights reserved.
 *   Usage and/or disclosure of this source code is restricted to authorized persons only.
 *
 */

#import <SynthesisCore/SIMCell.h>
#import <SynthesisCore/SIMType.h>
#import <SynthesisCore/SIMInputChannel.h>
#import <SynthesisCore/SIMNetwork.h>
#import <SynthesisCore/Simulator.h>
#import <Desiderata/ITable.h>

#define INTANDFIRE_LeakReversalPotential		@"LeakReversalPotential"
#define INTANDFIRE_LeakConductance			@"LeakConductance"
#define INTANDFIRE_PotassiumLeakConductance		@"PotassiumLeakConductance"
#define INTANDFIRE_SodiumLeakConductance		@"SodiumLeakConductance"
#define INTANDFIRE_MembraneTimeConstant			@"MembraneTimeConstant"
#define INTANDFIRE_RestingThreshold			@"RestingThreshold"
#define INTANDFIRE_ThresholdTimeConstant		@"ThresholdTimeConstant"
#define INTANDFIRE_SpikeDuration			@"SpikeDuration"
#define INTANDFIRE_SpikeTimeConstant			@"SpikeTimeConstant"
#define INTANDFIRE_MiniThreshold			@"MiniThreshold"
#define INTANDFIRE_PeakMiniRate				@"PeakMiniRate"
#define INTANDFIRE_VesiclePeak				@"VesiclePeak"
#define INTANDFIRE_VesicleRelease			@"VesicleRelease"
#define INTANDFIRE_VesicleRecoveryTimeConstant		@"VesicleRecoveryTimeConstant"


#define INTANDFIRE_PotassiumReversalPotential		@"PotassiumReversalPotential"
#define INTANDFIRE_SodiumReversalPotential		@"SodiumReversalPotential"


#define MEMBRANE_POTENTIAL	@"MembranePotential"
#define THRESHOLD 		@"Threshold"
#define LASTSPIKE 		@"LastSpikeTime"
#define VESICLEPOOL_VARIABLE	 @"VesiclePool"

@interface PulseIntegrateAndFireV1:SIMCell
{
    float E_Leak;	/* resting potential */
    float E_Threshold;	/* resting threshold */
    float tcV;			/* voltage time constant */
    float E_K;			/* potassium reversal */
    float E_Na;			/* sodium reversal */
    float tcTh;			/* threshold time constant */
    float spikeDuration;	/* spike duration in milliseconds */
    float tcSpike,gKLeak,gNaLeak;
    float miniThreshold,peakMiniRate,vesiclePeak,vesicleRelease, vesicleRecoveryTC; // vesicle pool parameters
    SIMNetwork *network;
    // indices for variables
    unsigned int Vm,		// output membrane potential - includes spikes
                Th,		// firing threshold
                lastSpike,	// time of the last spike
                VP;	// Vesicle pool
}

@end
