/* PatternBasedCurrentChannel.h created by shill on Wed 14-Feb-2003 */

#import <SynthesisCore/SIMChannel.h>
#import <SynthesisCore/SIMCell.h>
#import <SynthesisCore/SIMPatternGenerator.h>


#define	SIMPatternGeneratorKey	@"PatternGenerator"
#define SIMCurrentKey @"Current"

@interface PatternBasedCurrentChannel : SIMChannel
{
    id patternGenerator;
    float current;
    BOOL injectCurrentFlag;
    NSArray *channels;
}

- (void)encodeWithCoder:(NSCoder *)coder;


@end
