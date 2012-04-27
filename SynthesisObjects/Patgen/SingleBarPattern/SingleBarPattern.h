//
//  SingleBarPattern.h
//  SynthesisObjects
//
//  Created by Sean Hill on Thu Jun 25 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMPatternGenerator.h>
#import <PseudoRandomNum/PRNGenerator.h>

#define SINGLEBAR_CENTERX @"CenterX"
#define SINGLEBAR_CENTERY @"CenterY"
#define SINGLEBAR_ANGLE @"Angle"
#define SINGLEBAR_LENGTH @"Length"
#define SINGLEBAR_THICKNESS @"Thickness"

@interface SingleBarPattern : SIMPatternGenerator {
    int length, centerX, centerY, thickness;
    float xcoeff,ycoeff,dist;
}

@end
