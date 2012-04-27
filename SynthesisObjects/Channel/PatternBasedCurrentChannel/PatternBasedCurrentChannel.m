#import "PatternBasedCurrentChannel.h"
#import <SynthesisCore/SIMCategories.h>
#import <SynthesisCore/SIMPatternMatch.h>

@implementation PatternBasedCurrentChannel

- (void) initializeWithCellType:(SIMType *)type
{
    [super initializeWithCellType:type];

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


- (oneway void) updateParameters
{
    [super updateParameters];

    current = [self doubleForKey:@"Current"];
    channels = [self objectForKey:@"Channels"];
    injectCurrentFlag = [self boolForKey:@"InjectCurrentDirectly"];

}

- (void) updateState: (SIMState *) element
            dt: (float) dt
            time:(float)time
{
    [super updateState:element dt:dt time:time];
	
    element->CHANNEL[OUTPUT_INDEX].state.doubleValue = [patternGenerator valueForPosition:&element->position atTime:time];
    
    if(element->CHANNEL[OUTPUT_INDEX].state.doubleValue == 0.0)return;
    
    if(!injectCurrentFlag){
        NSEnumerator *channelKeyEnum = [[element->type allInputChannelKeys] objectEnumerator];
        NSString *key;
        while(key = [channelKeyEnum nextObject]){
            NSEnumerator *channelEnumerator = [channels objectEnumerator];
            NSString *channel;
            while(channel = [channelEnumerator nextObject]){
                if(!SIMPatternMatch([channel UTF8String],[key UTF8String],NULL) && (element->CHANNEL[OUTPUT_INDEX].state.doubleValue != 0.0)){
                    SIMConnection connection;
                    SIMInputChannel *channel = [element->type inputChannelWithName:key];
                    connection.strength = current*[channel totalWeightOfInputs:element]*element->CHANNEL[OUTPUT_INDEX].state.doubleValue;
                    connection.latency = 0.0;
                    connection.dx = 0; connection.dy = 0; connection.dz = 0;
                    if(connection.strength)[channel updateFrom:element to:element withConnection:&connection dt:dt time:time];
                }
            }
        }    
    }
}

- (double) channelCurrent: (SIMState *)element forCellModel:(SIMCell *)cellModel
/*"
    Return the value of the injected current if applicable.  If current is not injected this will always return 0.
"*/
{
    if (injectCurrentFlag) return element->CHANNEL[OUTPUT_INDEX].state.doubleValue;
    else return 0.0;
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

@end
