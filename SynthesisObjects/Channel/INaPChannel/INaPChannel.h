#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMChannel.h>
#import <SynthesisCore/SIMCell.h>
#import <PseudoRandomNum/PRNGenerator.h>
#import <Desiderata/ITable.h>
#import <Desiderata/NSValueArray.h>

/*"
    Default parameters taken from Compte, Sanchez-Vives, McCormick and Wang, 2003
    Model from Fleidervish et al. 1996

    INaP = gNaP*m^3*(V-VNa)

"*/


@class PRNUniformGenerator;

@interface INaPChannel: SIMChannel
{    
    // parameters
    float gPeak; // peak conductance
    float Erev; // Reversal potential
    float threshold;
    float slope;
    
    // state variable indices
    unsigned int G; /* conductance */

}


@end
