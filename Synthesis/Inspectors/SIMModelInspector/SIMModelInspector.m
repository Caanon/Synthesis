/* SIMModelInspector.m created by shill on Thu 22-Jul-1999 */

#import "SIMModelInspector.h"

@implementation SIMModelInspector

- (void)display
{
    NSArray *modelTypes = nil;
    NSMutableArray *modelCells = [NSMutableArray array];
    NSEnumerator *modelEnum;
    NSString *modelName;

    if([parameter isEqual:SIMConnectionsModelKey]) modelTypes = [object connectionsModels];
    if([parameter isEqual:SIMChannelModelKey]) modelTypes = [object inputChannelModels];
    //if([parameter isEqual:SIMCellModelKey]) modelTypes = [object cellModels];

    if(!modelTypes)return;

    modelEnum = [modelTypes objectEnumerator];

    while(modelName = [modelEnum nextObject]){
          [modelCells addObject: [[NSTextFieldCell alloc] initTextCell:modelName]];
    }

    [choiceMatrix removeColumn:0];
    [choiceMatrix insertColumn:0 withCells:modelCells];
    [choiceMatrix sizeToFit];
}

- (void)ok:sender
{
    id newObj = [NSArray array]; //dummy object for now;

    [object setObject:newObj forKey:parameter];
    if([object respondsToSelector:@selector(updateParameterValues)]) [object updateParameterValues];
}


@end
