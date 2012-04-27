/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <Foundation/Foundation.h>
#import <SynthesisCore/SIMModel.h>
#import <SynthesisCore/Simulator.h>

#define SIM_XSpaceConstant	@"XSpaceConstant"
#define SIM_YSpaceConstant	@"YSpaceConstant"
#define SIM_ZSpaceConstant	@"ZSpaceConstant"
#define SIM_StartTime		@"StartTime"
#define SIM_Duration		@"Duration"
#define SIM_Interval		@"Interval"


@interface SIMPatternGenerator : SIMModel
{
    float xSpaceConstant,ySpaceConstant,zSpaceConstant;
    float startTime,duration,interval;
}

- (BOOL)isActive:(float)time;
- (double) valueForPosition:(SIMPosition *)pos;
- (double) valueForPosition:(SIMPosition *)pos atTime:(float)time;
- (double) valueForXPosition:(float)x yPosition:(float)y atTime:(float)time;
- (double) valueForXPosition:(float)x yPosition:(float)y zPosition:(float)z atTime:(float)time;
- (NSData *)valuesForRows:(int)nRows columns:(int)nColumns layer:(int)layer time:(float)time;

@end
