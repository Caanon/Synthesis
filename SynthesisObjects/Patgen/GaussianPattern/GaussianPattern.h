//
//  GaussianPattern.h
//  SynthesisObjects
//
//  Created by Sean Hill on Thu Dec 05 2002.
//  Copyright (c) . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMPatternGenerator.h>
#import <PseudoRandomNum/PRNGenerator.h>

#define GAUSSPAT_CENTERX @"CenterX"
#define GAUSSPAT_CENTERY @"CenterY"
#define GAUSSPAT_RADIUS @"Radius"
#define GAUSSPAT_PEAK @"Peak"
#define GAUSSPAT_WIDTH @"Width"
#define GAUSSPAT_CONSTANT @"Constant"
#define GAUSSPAT_STANDARDDEVIATION @"StandardDeviation"

@interface GaussianPattern : SIMPatternGenerator {
	BOOL invertFlag;
    float constant, peak, width, std, spacing;
	float xVelocity,yVelocity,xLimit,yLimit;
	float oldSignal;
    int r, centerX, centerY;
	float newCenterX, newCenterY;
    PRNGenerator *strengthGenerator;
    PRNGenerator *xLocationGenerator;
    PRNGenerator *yLocationGenerator;
	PRNGenerator *xVarianceGenerator;
	PRNGenerator *yVarianceGenerator;	
}

- (float)centerX;
- (float)centerY;


@end
