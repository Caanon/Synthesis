#import "PRNGenerator.h"

@implementation PRNExponentialGenerator

- (double) exponentialDeviate
	// See: NR 7.2 expdev() - returns exponentially distributed deviate  
	// (positive, mean = [self mean])
	// Rejection method, based on the Marsaglia uniform distribution.
{
	double dum;
	do 
		dum = [super nextDouble];
	while (dum == 0.0);
	return -[self mean] * log (dum);
}

- (double) nextDouble
{
    return [self exponentialDeviate];
}


@end