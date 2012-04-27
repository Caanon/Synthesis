#import "SynNMDAChannelV1.h"

@implementation SynNMDAChannelV1


- (void) initializeWithCellType:(SIMType *)type
{
    [super initializeWithCellType:type];
}


- (void) updateVariableIndexes
{
    [super updateVariableIndexes];
    conductancePath = [[NSString alloc] init];
    noiseCutoffPath = [[NSString alloc] init];
    G = [self indexOfVariable:SYNNMDACHANNEL_G];
    g = [self indexOfVariable:SYNNMDACHANNEL_g];
    dGdt = [self indexOfVariable:SYNNMDACHANNEL_dGdt];
    MgUnblockS = [self indexOfVariable:SYNNMDACHANNEL_MGUNBLOCKSLOW];
    MgUnblockF = [self indexOfVariable:SYNNMDACHANNEL_MGUNBLOCKFAST];
}

- (void) setInitialValuesForState: (SIMState *) element
{
    [super setInitialValuesForState: element];
    element->INPUTCHANNEL[G].state.doubleValue = 0.0;
    element->INPUTCHANNEL[g].state.doubleValue = 0.0;
    element->INPUTCHANNEL[dGdt].state.doubleValue = 0.0;
    element->INPUTCHANNEL[MgUnblockS].state.doubleValue = 0.0;
    element->INPUTCHANNEL[MgUnblockF].state.doubleValue = 0.0;
}

- (void) setRandomNumberSeed:(int)seed
{
    [super setRandomNumberSeed:seed];
    
    if(randomGenerator)[randomGenerator release];
    if([noiseMode isEqual:SYNNMDACHANNEL_BINOMIAL])
        randomGenerator = [[PRNGenerator uniformGenerator] retain];
    if([noiseMode isEqual:SYNNMDACHANNEL_POISSON])
        randomGenerator = [[PRNGenerator uniformGenerator] retain];  // Fix this all
    
    if(miniGenerator)[miniGenerator release];
    miniGenerator = [[PRNGenerator gaussianGenerator] retain];
    [miniGenerator setMean:meanMiniAmplitude];
    [miniGenerator setStd:stdevMiniAmplitude];
    
    
    [randomGenerator setSeed:seed+1];
    [miniGenerator setSeed:seed+2];
}


- (oneway void) updateParameters
{
    NSString *newTablePath;
    
    [super updateParameters];
    
    

    peakConductance = [self doubleForKey:SYNNMDACHANNEL_GPEAK];
    tc1 = [self doubleForKey:SYNNMDACHANNEL_TIMECONSTANT1];
    tc2 = [self doubleForKey:SYNNMDACHANNEL_TIMECONSTANT2];
    MgTCF = [self doubleForKey:SYNNMDACHANNEL_MGTIMECONSTANTFAST];
    MgTCS = [self doubleForKey:SYNNMDACHANNEL_MGTIMECONSTANTSLOW];


    if(tc1 == tc2){
        peakResponse = tc1/2.718281828; // exp(1);
    }
    else {
        double tPeak = tc1*tc2/(tc1-tc2)*log(tc1/tc2);
        peakResponse = tc1*tc2/(tc1-tc2)*(expx(-tPeak/tc1) - expx(-tPeak/tc2));
    }

    reversalPotential = [self doubleForKey:SYNNMDACHANNEL_REVERSALPOTENTIAL];
    noiseRate = [self doubleForKey:SYNNMDACHANNEL_NOISERATE];
    noiseAmplitude = [self doubleForKey:SYNNMDACHANNEL_NOISEAMPLITUDE];
    noiseMode = [[self objectForKey:SYNNMDACHANNEL_NOISEMODE] description];

    newTablePath = [self objectForKey:SYNNMDACHANNEL_CONDUCTANCETABLE];
    if(newTablePath && ![newTablePath isEqual:@"None"] && ![conductancePath isEqual:newTablePath]){
        NSString *realPath;
        [conductancePath release];
        conductancePath = [newTablePath retain];
        if(conductanceTable)ITFreeTable(conductanceTable);
        realPath = [[NSBundle bundleForClass:[self class]] pathForResource:conductancePath ofType:@""];
        conductanceTable = ITLoadTable([realPath cString]);
    }

    meanMiniAmplitude = [self doubleForKey:SYNNMDACHANNEL_MEAN_MINIAMPLITUDE];
    stdevMiniAmplitude = [self doubleForKey:SYNNMDACHANNEL_STDEV_MINIAMPLITUDE];

    newTablePath = [self objectForKey:SYNNMDACHANNEL_NOISECUTOFFTABLE];
    if(newTablePath && ![newTablePath isEqual:@"None"] && ![noiseCutoffPath isEqual:newTablePath]){
        NSString *realPath;
        [noiseCutoffPath release];
        noiseCutoffPath = [newTablePath retain];
        if(noiseCutoffTable)ITFreeTable(noiseCutoffTable);
        realPath = [[NSBundle bundleForClass:[self class]] pathForResource:noiseCutoffPath ofType:@""];
        noiseCutoffTable = ITLoadTable([realPath cString]);
    }

}

- (void) updateFrom: (SIMState *) from
                to: (SIMState *) to
                withConnection: (SIMConnection *) connection
                    dt: (float) dt
                  time: (float) time
{
	//if([from->type cellActivityStateValue:from] & SIM_PlasticState) return;

    if([from->type cellActivityStateValue:from] != SIM_MiniSpikeState){
        // the value in INPUT_INDEX is delayed according to the connection.
        if([[from->type cellCompartmentAtIndex:0] isKindOfClass:NSClassFromString(@"PulseIntegrateAndFireV1")])
            to->INPUTCHANNEL[INPUT_INDEX].state.doubleValue += connection->strength*from->cell[0][3].state.doubleValue;
        else 
            to->INPUTCHANNEL[INPUT_INDEX].state.doubleValue += connection->strength;
            
        [super updateFrom:from to:to withConnection:connection dt:dt time:time];
        return;
    }

    if(([[from->type cellCompartmentAtIndex:0] isKindOfClass:NSClassFromString(@"PulseIntegrateAndFireV1")]) &&
        [stateGenerator nextDouble] < .5*from->cell[0][3].state.doubleValue){
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
        if ([noiseMode isEqual:SYNNMDACHANNEL_POISSON]){
            if([randomGenerator nextDouble] <= noiseRate*dt)
                element->INPUTCHANNEL[INPUT_INDEX].state.doubleValue += noiseScalar*noiseAmplitude;
        }
        //if ([noiseMode isEqual:SYNNMDACHANNEL_POISSON]){
        //    [randomGenerator setMean: noiseRate*dt];
        //    element->INPUTCHANNEL[INPUT_INDEX].state.doubleValue += noiseScalar*noiseAmplitude * (double)[randomGenerator poissonDeviate];
        //}
    }
    
    if (conductanceTable){
        double Vm = [(SIMType *)element->type membranePotential:element];
        double fss = ITOutputTable(conductanceTable,Vm);  //Fraction of channels open at steady state
        double MgUbS = element->INPUTCHANNEL[MgUnblockS].state.doubleValue;  //Fraction of slow unblocked NMDA channels unblocked
        double MgUbF = element->INPUTCHANNEL[MgUnblockF].state.doubleValue;  //Fraction of fast unblocked NMDA channels unblocked
        if (MgUbS > fss)element->INPUTCHANNEL[MgUnblockS].state.doubleValue = fss;
        if (MgUbS < fss){
            element->INPUTCHANNEL[MgUnblockS].state.doubleValue = fss + (MgUbS - fss) * exp(-dt / MgTCS);
        }
        if (MgUbF > fss)element->INPUTCHANNEL[MgUnblockF].state.doubleValue = fss;
        if (MgUbF < fss){
            element->INPUTCHANNEL[MgUnblockF].state.doubleValue = fss + (MgUbF - fss) * exp(-dt / MgTCF);
        }
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
    double Vm = [cellModel membranePotential:element];
    if(conductanceTable){
        double A1 = .51 - .0028 * Vm;  //Fraction fast time constant shold account for things
        double A2 = 1 - A1;
        conductance *= A1 * element->INPUTCHANNEL[MgUnblockF].state.doubleValue + A2 * element->INPUTCHANNEL[MgUnblockS].state.doubleValue;
    }
    element->INPUTCHANNEL[OUTPUT_INDEX].state.doubleValue = (reversalPotential - Vm) * conductance;
    return element->INPUTCHANNEL[OUTPUT_INDEX].state.doubleValue;
}

- (void)dealloc
{
    if(conductanceTable)ITFreeTable(conductanceTable);
    [super dealloc];
}

@end
