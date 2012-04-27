#ifndef NEXTSTEP
#import <Foundation/Foundation.h>
#else
#import <foundation/foundation.h>
#endif
#import <math.h>

/* ---------------------------------------------------------------------- *
	PRNGenerator - class cluster for random number generation.
	Classes one would use:
	
		PRNMarsagliaGenerator
		PRNUniformGenerator -- same as PRNMarsagliaGenerator
		PRNSobolGenerator
		PRNExponentialGenerator
		PRNGammaGenerator
		PRNPoissonGenerator
		
	Except for the Marsaglia generator, all use Numerical Recipes code.
	Warning: Gamma generator order = 1 gives results that 
	appear to differ from the Exponential generator results, whereas 
	NR says they ought to be pretty similar.
	
	Brief synopses of how to use each class:
	
	1a) To generate uniform deviates distributed in the range 0.0 to 2.0
	
		PRNUniformGenerator *g = [PRNGenerator uniformGenerator];
		double deviate;
		[g setMinimum: 0.0 maximum: 2.0];
		deviate = [g uniformDeviate];	
		
	1b) To generate uniform deviates distributed in the range 0.0 to 2.0
		
		PRNUniformGenerator *g = [PRNGenerator uniformGenerator];
		double deviate;
		[[g setMean: 1.0] scale: 2.0];	// defaults are 0.5 and 1.0
		deviate = [g uniformDeviate];

	1c) To explicitly set the seeds for the uniform generator
	
		[g setSeeds: seed_a: seed_b];	// default is 1000: 1000

	1d) To set the seeds for the uniform generator with only one arg
	
		[g setSeed: seed];	// implementation: [self setSeeds: seed: seed];

	2a) To generate numbers according to a Sobol sequence (distributed
	between 0.0 and 1.0) (the 1st Sobol sequence that is):

		PRNSobolGenerator *g = [PRNGenerator sobolGenerator];
		double deviate;
		deviate = [g nextDouble];		// scale it yourself
		
	2b) To generate numbers according to the 3rd Sobol sequence,
	then switch to the 4th Sobol sequence:

		PRNSobolGenerator *g = [[PRNGenerator sobolGenerator] 
								setSequenceNum: 3];
		double deviate;
		deviate = [g nextDouble];		// scale it yourself
		[[g init] setSequenceNum: 4];	// note: max is 6 (MAXDIM below)
		deviate = [g nextDouble];
		
	2c) Note that for PRNSobolGenerator, the implementation of setSeed: 
	is:
		[self setSequenceNum: seed %(MAXDIM-1)];  // any better ideas?
		
	3) To generate deviates distributed according to an exponential 
	distribution of mean 4.0:
		PRNExponentialGenerator *g = [PRNGenerator exponentialGenerator];
		double deviate;
		[g setMean 4.0];				// default is 1.0
		deviate = [g exponentialDeviate];
		
	4a) To generate deviates distributed according to a gamma 
	distribution of order 4:
		PRNGammaGenerator *g = [PRNGenerator gammaGenerator];
		double deviate;
		[g setNextEventNum: 4];			// default is 1
		deviate = [g gammaDeviate];
		
	4b) To generate deviates distributed according to a gamma 
	distribution of order N:
		PRNGammaGenerator *g = [PRNGenerator gammaGenerator];
		int N;
		N = ...;
		deviate = [g gammaDeviateOfOrder: N];
		
	5) To generate deviates distributed according to a poisson 
	distribution of mean 4.0:
		PRNPoissonGenerator *g = [PRNGenerator poissonGenerator];
		double deviate;
		[g setMean 4.0];				// default is 1.0
		deviate = [g poissonDeviate];
		
 * ---------------------------------------------------------------------- */

// Abstract class with subclass creation methods.
@interface PRNGenerator: NSObject 
{
}
- init;
- (double) nextDouble;
- (NSNumber *) nextNumber;

- setSeed: (int) seed;
- setSeeds: (int) seed_a : (int) seed_b;
- setSeeds: (int) seed_a : (int) seed_b: (int) seed_c;
@end

@interface PRNGenerator (PRNAdditionalMethods)
+ marsagliaGenerator;	
+ uniformGenerator;	// Sears Best uniform generator == marsagliaGenerator
+ sobolGenerator;	// NR sobol() sequence 
+ gaussianGenerator;	// NR gasdev() transformation, based on marsaglia
+ poissonGenerator;	// NR poidev() rejection method, based on marsaglia
+ exponentialGenerator;	// NR expdev() transformation, based on marsaglia
+ gammaGenerator;	// NR gamdev() rejection method, based on marsaglia
+ tableBasedGenerator;	// reads values from a file
@end

// Here is the documentation that was included in the 
// original random_number.h:
/*  
 *  This package makes available Marsaglia's highly portable generator 
 *  of uniformly distributed pseudo-random numbers.
 *  
 *  The sequence of 24 bit pseudo-random numbers produced has a period 
 *  of about 2**144, and has passed stringent statistical tests 
 *  for randomness and independence.
 *  
 *  Supplying two seeds to start_random_number is required once
 *  at program startup before requesting any random numbers, like this:
 *      start_random_number(101, 202);
 *      r := next_random_number();
 *  The correspondence between pairs of seeds and generated sequences 
 *  of pseudo-random numbers is many-to-one.
 *  
 *  This package should compile and run identically on any 
 *  machine/compiler which supports >=16 bit integer arithmetic
 *  and >=24 bit floating point arithmetic.
 *  
 *  References:
 *      M G Harmon & T P Baker, ``An Ada Implementation of Marsaglia's
 *      "Universal" Random Number Generator'', Ada Letters, late 1987.
 *      
 *      G Marsaglia, ``Toward a universal random number generator'',
 *      to appear in the Journal of the American Statistical Association.
 *  
 *  George Marsaglia is at the Supercomputer Computations Research Institute
 *  at Florida State University.
 */  

@interface PRNMarsagliaGenerator: PRNGenerator
{
	double mean, scale, scale2;
	int ni;
	int nj;
	double *u;
	double c, cd, cm;
}
- initWithSeeds: (int) seed_a: (int) seed_b;
- setSeed: (int) seed;
- setSeeds: (int) seed_a: (int) seed_b;
- setMean: (double) m;
- (double) mean;
- setScale: (double) s;
- (double) scale;
- setMinimum: (double) min maximum: (double) max;
- (double) minimum;
- (double) maximum; 
- (double) uniformDeviate; 	// uniformly distributed between min and max
@end

@interface PRNUniformGenerator: PRNMarsagliaGenerator
@end

#define	MAXDIM	6 			// num of sobol sequences allowed
#define	MAXBIT	30			// bits in word generated
@interface PRNSobolGenerator: PRNGenerator
{
    int				seqNum,numSeq;
	double 			seq[MAXDIM+1];
	double 			fac;
    unsigned long 	in, ix[MAXDIM+1], *iu[MAXBIT+1];
    unsigned long 	mdeg[MAXDIM+1];
    unsigned long 	ip[MAXDIM+1];
    unsigned long 	iv[MAXDIM*MAXBIT+1];
}
- (void) startSobol;
- (void) setNumSequences: (int) n;	// how many sequences to cycle over
- (void) setSequenceNum: (int) n;	// which sequence 0..MAXDIM-1
- (double) sobseqd: (int) n;
- (void) sobseqd: (int) n : (double *) x;
@end

@interface PRNExponentialGenerator: PRNMarsagliaGenerator
{
}
- (double) exponentialDeviate;
	// See: NR 7.2 expdev() - returns exponentially distributed deviate  
	// (positive, unit mean)
	// Rejection method, based on the Marsaglia uniform distribution.
	// The exponential distribution occurs in problems such as the
	// distribution of waiting times between independent Poisson-random
	// events.
	// (The waiting time to the a-th event in a Poisson process is given
	// by the gamma distribution; when a = 1, it reduces to the exponential
	// distribution)
@end

@interface PRNGammaGenerator: PRNMarsagliaGenerator
{
	int nextEventNum;
}
- setNextEventNum: (int) n;
- (int) nextEventNum;
- (double) gammaDeviate;
- (double) gammaDeviateOfOrder: (int) ia; 
	// See: NR 7.3 gamdev() - returns deviate distributed as a gamma 
	// distribution of integer order = ia 
	// -- i.e. a waiting time to the ia-th event in a Poisson process  
	// with mean = [self mean]
	// Rejection method, based on the Marsaglia uniform distribution.

@end

@interface PRNGaussianGenerator: PRNMarsagliaGenerator
{
	double std;
}
- (double) gaussianDeviate; 
	// returns a deviate with mean = [self mean] and 
	// standard deviation = [self std]
	// See:  Numerical Recipes Ch 7 gasdev()
	// Box-Muller transformation method
	// based on the Marsaglia uniform distribution.
- setStd: (double) s;
- (double) std;
- (void)setMean:(double)m std:(double)s;
@end

@interface PRNPoissonGenerator: PRNMarsagliaGenerator
{
}
- (double) poissonDeviate; 
	// See: NR 7.3 poidev() - returns an integer value (as a double) 
	// that is a random deviate drawn from a Poisson distribution  
	// with mean = [self mean]
	// Rejection method, 
	// based on the Marsaglia uniform distribution.

@end

@class NSMutableValueArray;
@interface PRNTableBasedGenerator: PRNGenerator
{
	unsigned long index;
	NSMutableValueArray *table;
}
- setTable: (NSMutableValueArray *) array;
- addDoubleToTable: (double) d;
- loadFromFileAtPath: (NSString *) path;
- saveToFileAtPath: (NSString *) path;
@end

