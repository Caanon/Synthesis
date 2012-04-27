#import "BinaryCell.h"

@implementation BinaryCell

#define SIMInitialDensity 	@"InitialDensity"
#define SIMLifeMode 		@"LifeMode"

- (void) setInitialValuesForState: (SIMState *) element
{
/*"
    Initialize internal states to initial values.
"*/
    [super setInitialValuesForState: element];
    CELL_BOOLEAN_VALUE(element,CELL_POTENTIAL_INDEX) = ([stateGenerator uniformDeviate] < initialDensity) ? YES:NO;
    if(CELL_BOOLEAN_VALUE(element,CELL_POTENTIAL_INDEX)) CELL_ACTIVITY_VALUE(element,CELL_STATE_INDEX) = SIM_FiringState;
    else CELL_ACTIVITY_VALUE(element,CELL_STATE_INDEX) = SIM_RestingState;
}

- (void)updateParameters
{
    [super updateParameters];

    initialDensity = [self floatForKey:SIMInitialDensity];
    lifeMode = [self boolForKey:SIMLifeMode];
}

- (void) updateState: (SIMState *) element dt: (float) dt time:(float)time
{
    if(lifeMode){
        int input = (int)[self summedChannelCurrents:element];
        if (input == 3)
            CELL_BOOLEAN_VALUE(element,CELL_POTENTIAL_INDEX) = YES;
        if (input == 2 || time == 0)
            CELL_BOOLEAN_VALUE(element,CELL_POTENTIAL_INDEX) = CELL_BOOLEAN_VALUE(element,CELL_POTENTIAL_INDEX);
        else if (input <= 1 || input >= 4)
            CELL_BOOLEAN_VALUE(element,CELL_POTENTIAL_INDEX) = NO;
   }
    else{
        if ([self summedChannelCurrents:element])
            CELL_BOOLEAN_VALUE(element,CELL_POTENTIAL_INDEX) = !CELL_BOOLEAN_VALUE(element,CELL_POTENTIAL_INDEX);
    }

    if (CELL_BOOLEAN_VALUE(element,CELL_POTENTIAL_INDEX))
        CELL_ACTIVITY_STATE(element) = SIM_SpikingState;
    else CELL_ACTIVITY_STATE(element) = SIM_RestingState;
}


@end
