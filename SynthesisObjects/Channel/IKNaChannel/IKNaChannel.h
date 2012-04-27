#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMChannel.h>
#import <SynthesisCore/SIMCell.h>
#import <PseudoRandomNum/PRNGenerator.h>
#import <Desiderata/ITable.h>
#import <Desiderata/NSValueArray.h>

/*

    Adapted from Compte et al. 2003
    
    This sodium-activated potassium current depends on an internal Na+ concentration which accumulates
    according to the membrane potential of the soma.  Sodium accumulates most during spikes.
    
    The activation of the Na+K+ conductance depends on the internal concentration of sodium.
    This function has been modified for our purposes (from Compte, 2003) in order to use a normalized,
    dimensionless scale of sodium concentration.  The dynamics of the activation are preserved.
    
    

*/


@class PRNUniformGenerator;

@interface IKNaChannel: SIMChannel
{    
    // parameters
    float gPeak; // peak conductance
    float Erev; // Reversal potential
    float sodiumInfluxPeak;
    float sodiumEquilibrium;
    float sodiumTimeConstant;
    float sodiumThreshold;
    float sodiumThresholdSlope;
    
    // state variable indices
    unsigned int G; /* conductance */
    unsigned int NA; /* sodium concentration */

}

- (void)evaluateDerivatives:(SIMStateValue *)dy initialValues:(SIMStateValue *)y
	time:(float)t context:(SIMState *)state;

@end
