#import <SynthesisCore/SIMCell.h>
#import <SynthesisCore/SIMType.h>
#import <SynthesisCore/SIMInputChannel.h>
#import <SynthesisCore/Simulator.h>
#import <PseudoRandomNum/PRNGenerator.h>


@interface BinaryCell: SIMCell
{
    float initialDensity;
    BOOL lifeMode;
}


@end
