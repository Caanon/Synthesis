#import "PRNGenerator.h"

#define raiseInvalidInitMessage()	[NSException raise:NSInvalidArgumentException format:@"*** initialization method %s cannot be sent to an abstract object of class %@: Create an [sic] concrete instance!", sel_getName( _cmd), [[self class] description]]

#define raiseInvalidMessage()	[NSException raise:NSInvalidArgumentException format:@"*** method %s cannot be sent to an abstract object of class %@: Create an [sic] concrete instance!", sel_getName( _cmd), [[self class] description]]



@implementation PRNGenerator (PRNAdditionalMethods)
+ marsagliaGenerator
{
	return [[[PRNMarsagliaGenerator alloc] init] autorelease];
}

+ uniformGenerator
{
	return [[[PRNMarsagliaGenerator alloc] init] autorelease];
}

+ sobolGenerator
{
	return [[[PRNSobolGenerator alloc] init] autorelease];
}

+ gaussianGenerator
{
	return [[[PRNGaussianGenerator alloc] init] autorelease];
}
+ poissonGenerator
{
	return [[[PRNPoissonGenerator alloc] init] autorelease];
}

+ exponentialGenerator
{
	return [[[PRNExponentialGenerator alloc] init] autorelease];
}

+ gammaGenerator
{
	return [[[PRNGammaGenerator alloc] init] autorelease];
}

+ tableBasedGenerator
{
	return [[[PRNTableBasedGenerator alloc] init] autorelease];
}

@end

@implementation PRNGenerator

- init
{
	return self;
}

// Should always return values between 0 and 1, inclusive.
// This is the primitive method to be overridden in subclasses.
- (double) nextDouble
{
	return -1.0;
}

- (NSNumber *) nextNumber;
{
	return [NSNumber numberWithDouble: [self nextDouble]];
}

- setSeed: (int) seed { return self; }
- setSeeds: (int) seed_a: (int) seed_b { return self; }
- setSeeds: (int) seed_a: (int) seed_b: (int) seed_c { return self; }


@end

