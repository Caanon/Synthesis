#import "PRNGenerator.h"

@implementation PRNGammaGenerator

- init
{
	[super init];
	nextEventNum = 1;
	return self;
}

- setNextEventNum: (int) n
{ 
	if (n > 0) 
		nextEventNum = n; 
	else 
		NSLog (@"PRNGammaGenerator: order parameter must be > 0");
	return self; 
}

- (int) nextEventNum
{ return nextEventNum; }

- (double) gammaDeviate
{
	return [self gammaDeviateOfOrder: nextEventNum];
} 

- (double) gammaDeviateOfOrder: (int) ia; 
	// See: NR 7.3 gamdev() - returns deviate distributed as a 
	// gamma distribution of integer order = ia 
	// -- i.e. a waiting time to the ia-th event in a Poisson process  
	// with mean = [self mean]
	// Rejection method, using the Marsaglia uniform distribution.

{
	int j;
	double am, e, s, v1, v2, x, y;

	if (ia < 1) {
		NSLog( @"PRNGammaGenerator: order parameter < 1");
		return 0;
	}
	if (ia < 6) {
		x = 1.0;
		for (j = 1; j <= ia; j++) 
			x *= [super nextDouble];
		x = -log (x);
	} else {
                double val = [super nextDouble];
		do {
			do {
				do {
					v1 = 2.0 * [super nextDouble] - 1.0;
					v2 = 2.0 * [super nextDouble] - 1.0;
				} while (v1 * v1 + v2 * v2 > 1.0);
				y = v2 / v1;
				am = ia - 1;
				s = sqrt (2.0 * am + 1.0);
				x = s * y + am;
			} while (x <= 0.0);
			e = (1.0 + y * y) * exp (am * log (x / am) - s * y);
		} while (val > e);
	}
	return ([self mean] * x);
}

- (double) nextDouble
{
    return [self gammaDeviate];
}


@end