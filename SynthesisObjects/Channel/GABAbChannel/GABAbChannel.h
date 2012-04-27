#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMInputChannel.h>
#import <SynthesisCore/SIMCell.h>
#import <PseudoRandomNum/PRNGenerator.h>
#import <Desiderata/ITable.h>
#import <Desiderata/NSValueArray.h>

/*

	Minimal kinetic model for GABA-B receptors
	==========================================

	Minimal model of GABAB currents including nonlinear stimulus 
	dependency (fundamental to take into account for GABAB receptors).


	Features:

  	  - peak at 100 ms; time course fit from experimental PSC
	  - NONLINEAR SUMMATION (psc is much stronger with bursts)
	    due to cooperativity of G-protein binding on K+ channels

	Approximations:

	  - single binding site on receptor	
	  - model of alpha G-protein activation (direct) of K+ channel
	  - G-protein dynamics is second-order; simplified as follows:
		- saturating receptor
		- no desensitization
		- Michaelis-Menten of receptor for G-protein production
		- "resting" G-protein is in excess
		- Quasi-stat of intermediate enzymatic forms
	  - binding on K+ channel is fast


	Kinetic Equations:

	  dR/dt = K1 * T * (1-R) - K2 * R

	  dG/dt = K3 * R - K4 * G

	  R : activated receptor
	  T : transmitter
	  G : activated G-protein
	  K1,K2,K3,K4 = kinetic rate cst

  n activated G-protein bind to a K+ channel:

	n G + C <-> O		(Alpha,Beta)

  If the binding is fast, the fraction of open channels is given by:

	O = G^n / ( G^n + KD )

  where KD = Beta / Alpha is the dissociation constant

-----------------------------------------------------------------------------

  Based on voltage-clamp recordings of GABAB receptor-mediated currents in rat
  hippocampal slices (Otis et al, J. Physiol. 463: 391-407, 1993), this model 
  was fit directly to experimental recordings in order to obtain the optimal
  values for the parameters (see Destexhe and Sejnowski, 1995).

-----------------------------------------------------------------------------

  This model includes a mechanism to describe the time course of transmitter
  on the receptors.  The time course is approximated here as a brief pulse
  triggered when the presynaptic compartment produces an action potential.
  
-----------------------------------------------------------------------------

  See details in:

  Destexhe, A. and Sejnowski, T.J.  G-protein activation kinetics and
  spill-over of GABA may account for differences between inhibitory responses
  in the hippocampus and thalamus.  Proc. Natl. Acad. Sci. USA  92:
  9515-9519, 1995.

  See also: 

  Destexhe, A., Mainen, Z.F. and Sejnowski, T.J.  Kinetic models of 
  synaptic transmission.  In: Methods in Neuronal Modeling (2nd edition; 
  edited by Koch, C. and Segev, I.), MIT press, Cambridge, 1996.


  Written by Alain Destexhe, Laval University, 1995
  Adapted for SYNTHESIS by Sean Hill, University of Wisconsin - Madison, 

*/

#define GABABCHANNEL_MEAN_MINIAMPLITUDE		@"MeanMiniAmplitude"
#define GABABCHANNEL_STDEV_MINIAMPLITUDE	@"StdevMiniAmplitude"

#define GABABCHANNEL_TIMECONSTANT1	@"K1"
#define GABABCHANNEL_TIMECONSTANT2	@"K2"
#define GABABCHANNEL_TIMECONSTANT3	@"K3"
#define GABABCHANNEL_TIMECONSTANT4	@"K4"
#define GABABCHANNEL_GMAX		@"gmax"
#define GABABCHANNEL_EK			@"Erev"
#define GABABCHANNEL_N			@"n"
#define GABABCHANNEL_KD			@"KD"

#define GABABCHANNEL_G			@"G"
#define GABABCHANNEL_R			@"R"
#define GABABCHANNEL_g			@"g"
#define GABABCHANNEL_lastSpike		@"lastSpike"

@class PRNUniformGenerator;

@interface GABAbChannel: SIMInputChannel
{    
    // parameters
    double Cmax;		// (mM) max transmitter concentration
    float Cdur;			// (ms)	transmitter duration (rising phase)
    float lastRelease;		// time of last spike
    double Prethresh;		// voltage level nec for release
    double Deadtime;		// (ms) mimimum time between release events
    
/*
    Parameters obtained from simplex fitting of the model directly to
    experimental data.  In order to activate GABAB currents sufficiently
    a long pulse of transmitter was used for the fit (5ms 0.5mM)
*/
    double K1;		// (/ms mM) : forward binding rate to receptor
    double K2;		// (/ms)    : backward (unbinding) rate of receptor
    double K3; 		// (/ms)    : rate of G-protein production
    double K4;		// (/ms)    : rate of G-protein decay
    double KD;		// dissociation constant of K+ channel
    double n;		// nb of binding sites of G-protein on K+
    double Erev;	// reversal potential (E_K)
    double gmax;	// (umho) maximum conductance
    double input;

    // state variable indices
    unsigned int R_index; /* fraction of activated receptor */
    unsigned int G_index; /* fraction of activated G-protein  */
    //unsigned int lastSpike_index; /* time of last spike */
    unsigned int g_index; /* conductance */

}

- (void)evaluateDerivatives:(SIMStateValue *)dy initialValues:(SIMStateValue *)y
	time:(float)t context:(SIMState *)state;


@end
