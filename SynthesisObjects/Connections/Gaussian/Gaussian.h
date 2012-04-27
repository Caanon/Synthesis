/* Generated by Interface Builder */

#import <SynthesisCore/SIMConnections.h>
@class PRNGenerator;

#define	GS_SobolConnection			@"Sobol"
#define	GS_RandomConnection			@"Random"
#define	GS_SmoothConnection			@"Smooth"
#define	GS_RandomSmoothConnection		@"RandomSmooth"
#define GS_GaussianStrengthConnection		@"GaussianStrength"
#define GS_SparseSmoothConnection		@"SparseSmooth"


#define	GSConstant		@"Constant"
#define	GSHeight		@"Height"
#define	GSNormalized		@"Normalized"
#define	GSRadius		@"Radius"
#define	GSStrength		@"Strength"
#define	GSStd			@"Std"
#define	GSType			@"Type"
#define	GSWidth			@"Width"
#define GSStdDelay		@"StdDelay"
#define GSMeanDelay		@"MeanDelay"	
#define GSStrengthStd		@"StrengthStd"

@interface Gaussian:SIMConnections
{
	float		height,width,strength,constant,strengthStd;
	int		radius,size,normalized;
	BOOL addNullConnectionsFlag;
	NSString	*type;
	PRNGenerator 	*generator,*delayGenerator,*strengthGenerator;
}

@end
