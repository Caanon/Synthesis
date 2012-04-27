#import "SynChannel.h"

@implementation SynChannel


- (void) initializeWithCellType:(SIMType *)type
{
    [super initializeWithCellType:type];
}


- (void) updateVariableIndexes
{
    [super updateVariableIndexes];
    conductancePath = [[NSString alloc] init];
    noiseCutoffPath = [[NSString alloc] init];
    G = [self indexOfVariable:SYNCHANNEL_G];
    g = [self indexOfVariable:SYNCHANNEL_g];
    dGdt = [self indexOfVariable:SYNCHANNEL_dGdt];
}

- (void) setInitialValuesForState: (SIMState *) element
{
    [super setInitialValuesForState: element];
    element->INPUTCHANNEL[G].state.doubleValue = 0.0;
    element->INPUTCHANNEL[g].state.doubleValue = 0.0;
    element->INPUTCHANNEL[dGdt].state.doubleValue = 0.0;
}

- (void) setRandomNumberSeed:(int)seed
{
    [super setRandomNumberSeed:seed];
    
    if(randomGenerator)[randomGenerator release];
    if([noiseMode isEqual:SYNCHANNEL_BINOMIAL])
        randomGenerator = [[PRNGenerator uniformGenerator] retain];
    if([noiseMode isEqual:SYNCHANNEL_POISSON])
        randomGenerator = [[PRNGenerator uniformGenerator] retain];  // Fix this all
    
    //if(miniGenerator)[miniGenerator release];
    //miniGenerator = [[PRNGenerator gaussianGenerator] retain];
    //[miniGenerator setMean:meanMiniAmplitude];
    //[miniGenerator setStd:stdevMiniAmplitude];
    
    
    [randomGenerator setSeed:seed+1];
    //[miniGenerator setSeed:seed+2];
}


- (oneway void) updateParameters
{
    NSString *newTablePath;
    
    [super updateParameters];

    peakConductance = [self doubleForKey:SYNCHANNEL_GPEAK];
    tc1 = [self doubleForKey:SYNCHANNEL_TIMECONSTANT1];
    tc2 = [self doubleForKey:SYNCHANNEL_TIMECONSTANT2];

    if(tc1 == tc2){
        peakResponse = tc1/2.718281828; // exp(1);
    }
    else {
        double tPeak = tc1*tc2/(tc1-tc2)*log(tc1/tc2);
        peakResponse = tc1*tc2/(tc1-tc2)*(expx(-tPeak/tc1) - expx(-tPeak/tc2));
    }

    reversalPotential = [self doubleForKey:SYNCHANNEL_REVERSALPOTENTIAL];
    noiseRate = [self doubleForKey:SYNCHANNEL_NOISERATE];
    noiseAmplitude = [self doubleForKey:SYNCHANNEL_NOISEAMPLITUDE];
    noiseMode = [[self objectForKey:SYNCHANNEL_NOISEMODE] description];

    newTablePath = [self objectForKey:SYNCHANNEL_CONDUCTANCETABLE];
    if(newTablePath && ![newTablePath isEqual:@"None"] && ![conductancePath isEqual:newTablePath]){
        NSString *realPath;
        [conductancePath release];
        conductancePath = [newTablePath retain];
        if(conductanceTable)ITFreeTable(conductanceTable);
        realPath = [[NSBundle bundleForClass:[self class]] pathForResource:conductancePath ofType:@""];
        conductanceTable = ITLoadTable([realPath UTF8String]);
    }
    //else {
    //    if(conductanceTable)ITFreeTable(conductanceTable);
    //    conductanceTable = (ITable *)nil;
    //}

    meanMiniAmplitude = [self doubleForKey:SYNCHANNEL_MEAN_MINIAMPLITUDE];
    stdevMiniAmplitude = [self doubleForKey:SYNCHANNEL_STDEV_MINIAMPLITUDE];

    newTablePath = [self objectForKey:SYNCHANNEL_NOISECUTOFFTABLE];
    if(newTablePath && ![newTablePath isEqual:@"None"] && ![noiseCutoffPath isEqual:newTablePath]){
        NSString *realPath;
        [noiseCutoffPath release];
        noiseCutoffPath = [newTablePath retain];
        if(noiseCutoffTable)ITFreeTable(noiseCutoffTable);
        realPath = [[NSBundle bundleForClass:[self class]] pathForResource:noiseCutoffPath ofType:@""];
        noiseCutoffTable = ITLoadTable([realPath UTF8String]);
    }
    //else {
    //    if(noiseCutoffTable)ITFreeTable(noiseCutoffTable);
    //    noiseCutoffTable = (ITable *)nil;
    //}

}

- (void) updateFrom: (SIMState *) from
                to: (SIMState *) to
                withConnection: (SIMConnection *) connection
                    dt: (float) dt
                  time: (float) time
{
	double shortTermPlasticity = 1.0;
	if(!([from->type cellActivityStateValue:from] & SIM_SpikingState)) return;


	SIMChannel *channelModel = nil;
	channelModel = [from->type intrinsicChannelWithName:@"VesiclePool"];
	if(channelModel){
		shortTermPlasticity = [channelModel doubleValueOfVariable:@"VesiclePool" forState:from];
	}
	
	if(![from->type isCellMiniSpiking:from]){
        // the value in INPUT_INDEX is delayed according to the connection.
			to->INPUTCHANNEL[INPUT_INDEX].state.doubleValue += connection->strength*shortTermPlasticity;
            
        [super updateFrom:from to:to withConnection:connection dt:dt time:time];
        return;
    }
    else if([stateGenerator nextDouble] < (0.5 * shortTermPlasticity)){
            double mini = [miniGenerator nextDouble];
            if(mini < 0)mini =0;
            to->INPUTCHANNEL[INPUT_INDEX].state.doubleValue += mini;
    }
    
}

- (void) updateState: (SIMState *) element
            dt: (float) dt
            time:(float)time
{
    double decay;
    double newdGdt;
    double noiseScalar = 1.0;

    [super updateState:element dt:dt time:time];

    if(noiseCutoffTable) noiseScalar = (double)ITOutputTable(noiseCutoffTable,[element->type membranePotential:element atIndex:0]);

    if (noiseRate > 0.0) {
        if ([noiseMode isEqual:SYNCHANNEL_POISSON]){
            if([randomGenerator nextDouble] <= noiseRate*dt)
                element->INPUTCHANNEL[INPUT_INDEX].state.doubleValue += noiseScalar*noiseAmplitude;
        }
        //if ([noiseMode isEqual:SYNCHANNEL_POISSON]){
        //    [randomGenerator setMean: noiseRate*dt];
        //    element->INPUTCHANNEL[INPUT_INDEX].state.doubleValue += noiseScalar*noiseAmplitude * (double)[randomGenerator poissonDeviate];
        //}
    }

    decay = expx(-dt/tc1);
    newdGdt = element->INPUTCHANNEL[dGdt].state.doubleValue * decay + element->INPUTCHANNEL[INPUT_INDEX].state.doubleValue / dt * tc1 * (1. - decay);
    decay = expx(-dt/tc2);
    element->INPUTCHANNEL[G].state.doubleValue = element->INPUTCHANNEL[G].state.doubleValue * decay + element->INPUTCHANNEL[dGdt].state.doubleValue * tc2 * (1. - decay);
    element->INPUTCHANNEL[dGdt].state.doubleValue = newdGdt;
    element->INPUTCHANNEL[g].state.doubleValue = element->INPUTCHANNEL[G].state.doubleValue / peakResponse * peakConductance;
    element->INPUTCHANNEL[INPUT_INDEX].state.doubleValue = 0.0;
}

- (double) channelCurrent: (SIMState *)element forCellModel:(SIMCell *)cellModel
/*"
    Use the conductance to calculate the current output.
"*/
{
    float conductance = element->INPUTCHANNEL[g].state.doubleValue;
    if(conductanceTable) conductance *= ITOutputTable(conductanceTable,[cellModel membranePotential:element]);
    element->INPUTCHANNEL[OUTPUT_INDEX].state.doubleValue = (reversalPotential - [cellModel membranePotential:element]) * conductance;
    return element->INPUTCHANNEL[OUTPUT_INDEX].state.doubleValue;
}

- (void)dealloc
{
    if(conductanceTable)ITFreeTable(conductanceTable);
    [super dealloc];
}

@end
