//
//  SingleBarPattern.m
//  SynthesisObjects
//
//  Created by Sean Hill on Thu Jun 25 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "SingleBarPattern.h"


@implementation SingleBarPattern

- (double) valueForXPosition:(float)xPos yPosition:(float)yPos zPosition:(float)zPos atTime:(float)time
{
    float signal = [super valueForXPosition:xPos yPosition:yPos zPosition:zPos atTime:time];
    float output = thickness;
    float x,y,x2,y2,r2;
        
    if( !signal) return 0.0;
    
            
    x = (xPos - centerX);
    y = (yPos - centerY);

    x2 = x*x;
    y2 = y*y;
    float temp = ((length)*.5 + thickness);
    r2 = temp*temp;
    
    if(x2 + y2 - r2 < 0) output = abs((x*xcoeff + y*ycoeff)/dist);
    
    return (output < thickness)?1.0:0.0;
}


- (oneway void)updateParameters
{
    float angle;
    
    [super updateParameters];

    centerX =  [self intForKey:SINGLEBAR_CENTERX];
    centerY =  [self intForKey:SINGLEBAR_CENTERY];
    angle = [self floatForKey:SINGLEBAR_ANGLE];
    length = [self intForKey:SINGLEBAR_LENGTH];
    thickness = [self floatForKey:SINGLEBAR_THICKNESS];

    xcoeff = cos(angle*M_PI/180.0);
    ycoeff = sin(angle*M_PI/180.0);

    dist = sqrt(xcoeff*xcoeff + ycoeff*ycoeff);

}

@end
