//
//  GaussianPattern.m
//  SynthesisObjects
//
//  Created by Sean Hill on Thu Dec 05 2002.
//  Copyright (c) . All rights reserved.
//

#import "GaussianPattern.h"


@implementation GaussianPattern

- (void) initializeWithCellType:(SIMType *)type
{
	[super initializeWithCellType:type];
    oldSignal = 0.0;
	strengthGenerator=nil;
	newCenterX = 0;
	newCenterY = 0;

}

- (float)centerX
{
	return newCenterX;
}

- (float)centerY
{
	return newCenterY;
}

- (double) valueForXPosition:(float)xPos yPosition:(float)yPos zPosition:(float)zPos atTime:(float)time
{
    int x2,y2,r2;
    float signal = [super valueForXPosition:xPos yPosition:yPos zPosition:zPos atTime:time];
    float current;
    //float size = (r*2 + 1)/2;
    
	 
	if((oldSignal == 0.0) && (signal == 1.0)){
		newCenterX = [xLocationGenerator nextDouble]*xLimit;
		newCenterY = [yLocationGenerator nextDouble]*yLimit;
		newCenterX = floor(newCenterX/spacing +.5)*spacing + (centerX + [xVarianceGenerator nextDouble]);
		newCenterY = floor(newCenterY/spacing +.5)*spacing + (centerY + [yVarianceGenerator nextDouble]);
	}
	
	//while(newCenterX > xLimit)newCenterX -= centerX;
	//while(newCenterY > yLimit)newCenterY -= centerY;
	//while(newCenterX < 0.0)newCenterX += centerX;
	//while(newCenterY < 0.0)newCenterY += centerY;
	
	
	oldSignal = signal;

    if(signal == 0)return 0.0;

    x2 = (xPos - newCenterX)*(xPos - newCenterX);
    y2 = (yPos - newCenterY)*(yPos - newCenterY);
    r2 = r*r;
    
	current = constant + peak*exp(-(pow(xPos - newCenterX,2)/width+pow(yPos - newCenterY,2)/width));

	if(invertFlag){
		if((current-constant) == 0.0) current = constant;
		else current = 0.0;
	}

    [strengthGenerator setMean:current];

    if(x2 + y2 - r2 <= 0) return (std)?[strengthGenerator nextDouble]:current;
    else return 0.0;
}


- (oneway void)updateParameters
{
    [super updateParameters];

	invertFlag = [self boolForKey:@"Invert"];

    centerX =  [self intForKey:GAUSSPAT_CENTERX];
    centerY =  [self intForKey:GAUSSPAT_CENTERY];
    r = [self intForKey:GAUSSPAT_RADIUS];
    width = [self floatForKey:GAUSSPAT_WIDTH];
    peak = [self floatForKey:GAUSSPAT_PEAK];
    constant = [self floatForKey:GAUSSPAT_CONSTANT];
    
    std = [self floatForKey:GAUSSPAT_STANDARDDEVIATION];
	if(strengthGenerator){[strengthGenerator release];strengthGenerator=nil;}
    strengthGenerator = [[PRNGenerator gaussianGenerator] retain];
    [(PRNGaussianGenerator *)strengthGenerator setMean:constant];
    [(PRNGaussianGenerator *)strengthGenerator setStd:std];

	xVelocity = [self floatForKey:@"VelocityX"];
	yVelocity = [self floatForKey:@"VelocityY"];
	xLimit = [self floatForKey:@"LimitX"];
	yLimit = [self floatForKey:@"LimitY"];
	
	spacing = [self floatForKey:@"Spacing"];

	if(randomSeed != [self intForKey:@"RandomSeed"]){
		//NSLog(@"Resetting random seed");
		randomSeed = [self intForKey:@"RandomSeed"];
		if(yLocationGenerator){[yLocationGenerator release];yLocationGenerator=nil;}
		yLocationGenerator = [[PRNGenerator uniformGenerator] retain];
		[(PRNGaussianGenerator *)yLocationGenerator setSeed:randomSeed+1];

		if(xLocationGenerator){[xLocationGenerator release];xLocationGenerator=nil;}
		xLocationGenerator = [[PRNGenerator uniformGenerator] retain];
		[(PRNGaussianGenerator *)xLocationGenerator setSeed:randomSeed];
		
		if(xVarianceGenerator){[xVarianceGenerator release];xVarianceGenerator=nil;}
		xVarianceGenerator = [[PRNGenerator gaussianGenerator] retain];
		[(PRNGaussianGenerator *)xVarianceGenerator setSeed:randomSeed];

		if(yVarianceGenerator){[yVarianceGenerator release];yVarianceGenerator=nil;}
		yVarianceGenerator = [[PRNGenerator gaussianGenerator] retain];
		[(PRNGaussianGenerator *)yVarianceGenerator setSeed:randomSeed+1];

		[yLocationGenerator setMinimum:0 maximum:1.0];
		[xLocationGenerator setMinimum:0 maximum:1.0];
	}
	[xVarianceGenerator setMean:0 std:[self floatForKey:@"VarianceX"]];
	[yVarianceGenerator setMean:0 std:[self floatForKey:@"VarianceY"]];

}

@end
