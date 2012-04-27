/* Generated by Interface Builder */

#import <SynthesisCore/SIMConnections.h>
@class PRNGenerator;

#define	GS_SobolConnection			@"Sobol"
#define	GS_RandomConnection			@"Random"
#define	GS_SmoothConnection			@"Smooth"
#define	GS_RandomSmoothConnection		@"RandomSmooth"
#define GS_GaussianStrengthConnection		@"GaussianStrength"


#define	RCLength		@"Length"
#define	RCWidth			@"Width"
#define	RCStrength		@"Strength"
#define	RCPeakProbability	@"PeakProbability"
#define	RCType			@"Type"
#define RCStdDelay		@"StdDelay"
#define RCMeanDelay		@"MeanDelay"	


@interface RectangularConnections:SIMConnections
{
    int 		length,width;
    float		strength,peakProbability;
    NSString		*type;
    PRNGenerator 	*generator,*delayGenerator;
}

@end