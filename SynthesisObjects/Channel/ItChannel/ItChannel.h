#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMChannel.h>
#import <SynthesisCore/SIMCell.h>
#import <PseudoRandomNum/PRNGenerator.h>
#import <Desiderata/ITable.h>
#import <Desiderata/NSValueArray.h>

/*"
    Low-threshold calcium current It model
    
    From Huguenard and McCormick, 1992
    
    "Simulation of the Currents Involved in Rhythmic Oscillations in Thalamic Relay Neurons"
    Journal of Neurophysiology, Vol. 68, No. 4, October 1992.
    
    with a temperature-adjusted and modified inactivation function from  Destexhe et al. 1996.
    "Ionic Mechanisms Underlying Synchronized Oscillations and Propagating Waves in a Model of Ferret
     Thalamic Slices" Journal of Neurophysiology, Vol. 76, No. 3, September 1996.

"*/


@class PRNUniformGenerator;

@interface ItChannel: SIMChannel
{    
    /*" parameters "*/
    float gPeak; /*" peak conductance "*/
    float Erev;  /*" Reversal potential "*/
    
    /*" state variable indices "*/
    unsigned int H; /*" index of fraction of activated receptor "*/
    unsigned int M; /*" index of fraction of activated G-protein  "*/
    unsigned int G; /*" index of conductance "*/

}

- (void)evaluateDerivatives:(SIMStateValue *)dy initialValues:(SIMStateValue *)y
	time:(float)t context:(SIMState *)state;

@end
