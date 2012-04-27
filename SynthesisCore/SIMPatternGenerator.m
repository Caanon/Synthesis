/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/SIMPatternGenerator.h>

@implementation SIMPatternGenerator

- (void) initializeWithCellType:(SIMType *)aType
{
// should/could retrieve layer information such as space constants
}

- (double) valueForPosition:(SIMPosition *)pos
{
    return [self valueForXPosition:pos->x yPosition:pos->y zPosition:pos->z atTime:0.0];
}

- (double) valueForPosition:(SIMPosition *)pos atTime:(float)time
{
    return [self valueForXPosition:pos->x yPosition:pos->y zPosition:pos->z atTime:time];
}

- (double) valueForXPosition:(float)x yPosition:(float)y atTime:(float)time
{
    return [self valueForXPosition:x yPosition:y zPosition:0.0 atTime:time];
}

- (double) valueForXPosition:(float)x yPosition:(float)y zPosition:(float)z atTime:(float)time
{
	return ([self isActive:time])?1.0:0.0;
}

- (BOOL)isActive:(float)time
{
    float t = time - startTime;
    if(duration == 0.0 || (t < 0)) return NO;
    if(t - floor(t/interval)*interval < duration)return YES;
    else return NO;
}

- (NSData *)valuesForRows:(int)nRows columns:(int)nColumns layer:(int)layerIndex time:(float)t
{
        NSMutableData	*data;
        int	i,j;
        float *bytes;

        data = [[NSMutableData dataWithLength:nRows*nColumns*sizeof(float)] retain];
        bytes = (float *)[data mutableBytes];

        for(i = 0; i < nRows; i++){
            for(j = 0; j < nColumns; j++){
                float value = (float)[self valueForXPosition:j yPosition:i zPosition:layerIndex atTime:t];
                bytes[i*nColumns+j] = value;
            }
        }

        return [data autorelease];
}


- (void) updateParameters
{
    // This should be the routine where all values are extracted from the parameter
    // dictionary and the instance variables are set.
    // a = [parameterDictionary floatForKey:AKey];
    // This should then be followed by a call to [super updateParameters]
    // to send the SIMParameterDidChangeNotification.
    [super updateParameters];

    xSpaceConstant = [self floatForKey:SIM_XSpaceConstant];
    ySpaceConstant = [self floatForKey:SIM_YSpaceConstant];
    zSpaceConstant = [self floatForKey:SIM_ZSpaceConstant];

    startTime = [self floatForKey:SIM_StartTime];
    duration = [self floatForKey:SIM_Duration];
    interval = [self floatForKey:SIM_Interval];

    if(duration > interval){interval = duration;} // Makes no sense for duration to be greater than the interval.
}

- (NSString *)description
{
    NSMutableDictionary *descDict = [NSMutableDictionary dictionary];
    [descDict setObject:[mainDictionary objectForKey:SIMClassNameKey] forKey:SIMClassNameKey];
    [descDict setObject:[mainDictionary objectForKey:SIMParametersKey] forKey:SIMParametersKey];
    return [descDict description];
}

- initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
}

- (NSString *) inspectorClassName { return @"SIMPatternInspector"; }

@end
