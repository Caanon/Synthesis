#import "PRNGenerator.h"

@implementation PRNGaussianGenerator
- init 
{
    [super init];
	std = 0.5;
	return self;
}

- (double) std 
{ return std; }

- setStd: (double) s
{ std = s; return self;}

- (void)setMean:(double)m std:(double)s
{
	[self setMean:m];
	[self setStd:s];
}

- (double) gaussianDeviate
	// returns a deviate with mean = [self mean] and 
	// standard deviation = [self std]
	// See:  Numerical Recipes Ch 7 gasdev()
	// Box-Muller transformation method
	// based on the Marsaglia uniform distribution.
{
    //static int iset = 0;
    //static double gset;
    double fac, r, v1, v2;
	
	if ((std == 0.0) && (mean == 0.0)) return 0.0;
	
	//if  (iset == 0) {
		do {
			v1 = 2.0 * [super nextDouble] - 1.0;
			v2 = 2.0 * [super nextDouble] - 1.0;
			r = v1 * v1 + v2 * v2;
		} while (r >= 1.0 || r == 0);
		fac = sqrt (- 2.0 * log (r) / r);
//		gset = std * (v1 * fac) + mean;
//		iset = 1;
		return std * (v2 * fac) + mean;
    //}
	//else {
	//	iset = 0;
	//	return gset;
    //}
}

- (double) nextDouble
{
    return [self gaussianDeviate];
}

@end
