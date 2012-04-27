#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMPatternGenerator.h>

#define MPLAID_XWAVELENGTH    @"XWavelength"
#define MPLAID_YWAVELENGTH    @"YWavelength"
#define MPLAID_XTHICKNESS     @"XThickness"
#define MPLAID_YTHICKNESS     @"YThickness"
#define MPLAID_XOFFSET        @"XOffset"
#define MPLAID_YOFFSET	      @"YOffset"
#define MPLAID_XCYCLES        @"XCyclesPerSecond"
#define MPLAID_YCYCLES        @"YCyclesPerSecond"
#define MPLAID_PEAKPROB       @"PeakProbability"


@interface MovingPlaid: SIMPatternGenerator
{
    int xWavelength,
        yWavelength,
        xCycles,
        yCycles,
        yThickness,
        xThickness,
        lowerj,
        upperj,
        lowerk,
        upperk,
        xOffset,
        yOffset;
    float peakProb,xVelocity,yVelocity;

}

@end