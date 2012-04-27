#import "PatternBasedNeuron.h"

@implementation PatternBasedNeuron

- (void) setRandomNumberSeed:(int)seed
{
    [super setRandomNumberSeed:seed];

    if (generator){[generator release];generator = nil;}
    generator = [[PRNGenerator uniformGenerator] retain];
    [generator setSeed: seed+1];
}

- (void) initializeWithCellType:(SIMType *)type
{
    [super initializeWithCellType:type];

    [self setRandomNumberSeed:1];

    patternGenerator = [self objectForKey:SIMPatternGeneratorKey];
    if([patternGenerator isKindOfClass:[NSDictionary class]]){
        id patgenClass = [patternGenerator patternGeneratorClassForKey:SIMClassNameKey];
        id instance = [[patgenClass alloc] initWithDescription:patternGenerator];
        [self setObject:instance forKey:SIMPatternGeneratorKey];
        patternGenerator = [self objectForKey:SIMPatternGeneratorKey];
    }
    else [patternGenerator retain];

    [patternGenerator initializeWithCellType:type];
}

- (void) updateVariableIndexes
{
    [super updateVariableIndexes];
    refractory = [self indexOfVariable: Refractory];
}

- (void) setInitialValuesForState: (SIMState *) element
{
    [super setInitialValuesForState: element];
    element->CELL[CELL_POTENTIAL_INDEX].state.doubleValue = [patternGenerator valueForPosition:&element->position atTime:0.0];
}

- (void) setRandomValuesForState: (SIMState *) element
{
    [super setRandomValuesForState: element];
    element->CELL[CELL_POTENTIAL_INDEX].state.doubleValue = [patternGenerator valueForPosition:&element->position atTime:[stateGenerator uniformDeviate]*100.0];
}

- (void)updateState:(SIMState *)element dt:(float)dt time:(float)time
{
    element->CELL[CELL_POTENTIAL_INDEX].state.doubleValue = [patternGenerator valueForPosition:&element->position atTime:time];

    if ((element->CELL[refractory].state.doubleValue += dt) < 0) {
        // refractory -- can't fire
        element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_RefractoryState;
        return;
    }
    else if ([generator uniformDeviate] < element->CELL[CELL_POTENTIAL_INDEX].state.doubleValue*dt)
        // fire
        element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_SpikingState;
    else {
        element->CELL[CELL_STATE_INDEX].state.activityValue = SIM_RestingState;
    }	

    if (element->CELL[CELL_STATE_INDEX].state.activityValue == SIM_SpikingState) {
        element->CELL[refractory].state.doubleValue = -refractoryPeriod; //Absolute refractory period
    }

}

- (oneway void)updateParameters
{
    [super updateParameters];

    refractoryPeriod = [self floatForKey:SIMRefractoryPeriodKey];
}

- initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    [self setRandomNumberSeed:1];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    SIMPatternGenerator *patGen = [patternGenerator retain];
    NSDictionary *dict = [[patternGenerator description] propertyList];
    [self setObject:dict forKey:SIMPatternGeneratorKey];
    [super encodeWithCoder:coder];
    [self setObject:patGen forKey:SIMPatternGeneratorKey];
    [patGen release];
}

- (Class)_patternGeneratorClassForValue:(NSString *)value
{
    Class class = nil;

    if([value isKindOfClass:[NSString class]])
            class = NSClassFromString(value);
    if(class == nil){
        id path = [[NSBundle mainBundle] pathForResource:value ofType:PATGEN_EXTENSION];
        id b = [NSBundle bundleWithPath:path];
        if(!b){
            NSLog(@"Unable to load class %@ of type %@",value,PATGEN_EXTENSION);
            return nil;
        }
        class = [b classNamed:value];
    }
    return class;
}
@end
