#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMChannel.h>
#import <SynthesisCore/SIMCell.h>
#import <PseudoRandomNum/PRNGenerator.h>
#import <Desiderata/ITable.h>
#import <Desiderata/NSValueArray.h>

/*"
    Voltage-dependent h-current model
    
    From Huguenard and McCormick, 1992
    
    "Simulation of the Currents Involved in Rhythmic Oscillations in Thalamic Relay Neurons"
    Journal of Neurophysiology, Vol. 68, No. 4, October 1992.

"*/


@class PRNUniformGenerator;

@interface IhChannel: SIMChannel
{    
    // parameters
    float gPeak; // peak conductance
    float Erev; // Reversal potential
    float Vthreshold;
    
    // state variable indices
    unsigned int M; /* activation variable */
    unsigned int G; /* conductance */

}

- (void)evaluateDerivatives:(SIMStateValue *)dy initialValues:(SIMStateValue *)y
	time:(float)t context:(SIMState *)state;

@end
