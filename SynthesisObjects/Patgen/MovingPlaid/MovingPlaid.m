#import "MovingPlaid.h"
#import <Desiderata/NSValueArray.h>

@implementation MovingPlaid

- (double) valueForXPosition:(float)xPos yPosition:(float)yPos zPosition:(float)zPos atTime:(float)time
{
    int j,k,x = xPos,y = yPos,z = zPos;
    int pSignal = 0;
    float xV,yV;
    float signal = [super valueForXPosition:x yPosition:y zPosition:z atTime:time];

    if(signal == 0)return 0.0;

    xV = xVelocity*time;
    yV = yVelocity*time;

    for(k = lowerk; k <= upperk; k++){
        int x1 = floor(x + k + xV - xOffset);
        pSignal = pSignal || ((x1 % xWavelength) == 0);
    }
    for(j = lowerj; j <= upperj; j++){
        int y1 = floor(y + j + yV - yOffset);
        pSignal = pSignal || ((y1 % yWavelength) == 0);
    }

    return (double)pSignal*peakProb;
}


- (oneway void)updateParameters
{
    [super updateParameters];

    xWavelength =  [self intForKey:MPLAID_XWAVELENGTH];
    yWavelength =  [self intForKey:MPLAID_YWAVELENGTH];
    xCycles = [self intForKey:MPLAID_XCYCLES];
    yCycles = [self intForKey:MPLAID_YCYCLES];
    xOffset = [self intForKey:MPLAID_XOFFSET];
    yOffset = [self intForKey:MPLAID_YOFFSET];
    xThickness = [self intForKey:MPLAID_XTHICKNESS];
    yThickness = [self intForKey:MPLAID_YTHICKNESS];
    peakProb =  [self floatForKey:MPLAID_PEAKPROB];

    if (xThickness%2 == 0) {
        int whichBound = ([stateGenerator uniformDeviate] < 0.5)? 0 : 1;
        lowerj = -xThickness/2 + 1 - whichBound;
        upperj = xThickness/2 - whichBound;
    } else {
        lowerj = -xThickness/2;
        upperj = xThickness/2;
    }
    if (yThickness%2 == 0) {
        int whichBound = ([stateGenerator uniformDeviate] < 0.5)? 0 : 1;
        lowerk = -yThickness/2 + 1 - whichBound;
        upperk = yThickness/2 - whichBound;
    } else {
        lowerk = -yThickness/2;
        upperk = yThickness/2;
    }

    xVelocity = (float)(xCycles*xWavelength)/1000.0; // per second
    yVelocity = (float)(yCycles*yWavelength)/1000.0; // per second   
}

/*
- (double) valueForXPosition:(float)x yPosition:(float)y zPosition:(float)z atTime:(float)time
{
    float xSignal,ySignal;
    float signal = [super valueForXPosition:x yPosition:y zPosition:z atTime:time];


    if(cos( (2*M_PI/xSpaceConstant) *  xSpatialFrequency * ( x - xVelocity * time))>modThres)
       xSignal = signal*xPeakProb;
    else
       xSignal = 0;

    if(cos( (2*M_PI/ySpaceConstant) *  ySpatialFrequency * ( y - yVelocity * time))>modThres)
       ySignal = signal*yPeakProb;
    else
       ySignal = 0;

    //Normalization such that if spatial frequencies are 1, you fit exactly one wavelength
    //into the layer; velocities are in units of  neuron/msec

    if (xSignal > ySignal)
        return xSignal;
    else
        return ySignal;
}
*/


@end