
/* Generated by Interface Builder */

#import "RectangularConnections.h"
#import <PseudoRandomNum/PRNGenerator.h>
#import <Desiderata/NSValueArray.h>
#import <stdio.h>

@implementation RectangularConnections


- (void) setRandomNumberSeed:(int)seed
{
    float stdDelay, meanDelay;

    [super setRandomNumberSeed:seed];
    
    stdDelay = [self floatForKey:RCStdDelay];
    meanDelay = [self floatForKey:RCMeanDelay];

    if(generator)[generator autorelease];
    generator = [[PRNGenerator marsagliaGenerator] retain];

    if(delayGenerator)[delayGenerator release];
    delayGenerator = [[PRNGenerator gaussianGenerator] retain];
    [(PRNGaussianGenerator *)delayGenerator setMean:meanDelay];
    [(PRNGaussianGenerator *)delayGenerator setStd:stdDelay];


    [generator setSeed:seed+1];
    [delayGenerator setSeed:seed+2];

}


- (NSValueArray *)connectionsForPosition:(SIMPosition)position
{
    SIMConnection	*newConnect;
    NSMutableValueArray *connections;
    float		j,k;
    int whichBound,lowerj,upperj,lowerk,upperk;

    newConnect = NSZoneMalloc([self zone], sizeof(SIMConnection));

    connections = [[NSMutableValueArray allocWithZone:[self zone]]
					initWithValues:nil
					count:length*width*peakProbability // estimate of number of connections
					withObjCType:@encode(SIMConnection)];

    newConnect->latency = (float)[delayGenerator nextDouble];

    if (length%2 == 0) {
        whichBound = ([stateGenerator uniformDeviate] < 0.5)? 0 : 1;
        lowerj = -length/2 + 1 - whichBound;
        upperj = length/2 - whichBound;
    } else {
        lowerj = -length/2;
        upperj = length/2;
    }
    if (width%2 == 0) {
        whichBound = ([stateGenerator uniformDeviate] < 0.5)? 0 : 1;
      lowerk = -width/2 + 1 - whichBound;
      upperk = width/2 - whichBound;
    } else {
      lowerk = -width/2;
      upperk = width/2;
    }     

    for (j=lowerj;j <= upperj;j++){
        for(k=lowerk;k <= upperk;k++) {
            double r = [generator nextDouble];
            if (r< peakProbability) {
                newConnect->dx = k ;
                newConnect->dy = j ;
                newConnect->dz = 0;
                newConnect->strength= strength;
                [connections addValue:(void *)newConnect];
            }
        }
    }

    NSZoneFree([self zone],newConnect);
    //[SIMConnections logConnections:connections];
    return [connections autorelease];
}


- (oneway void)updateParameters
{
    float stdDelay, meanDelay;

    [super updateParameters];

    length = [self floatForKey:RCLength];
    width = [self floatForKey:RCWidth];
    strength = [self floatForKey:RCStrength];
    peakProbability = [self floatForKey:RCPeakProbability];

    [self setRandomNumberSeed:[self randomNumberSeed]];
}


- (void)dealloc
{
	[generator release];
    	if(userState.connections)[userState.connections release];
	[super dealloc];
}
@end

