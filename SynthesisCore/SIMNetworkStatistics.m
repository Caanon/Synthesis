/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/SIMNetworkStatistics.h>
#import <SynthesisCore/SIMNetworkInfo.h>
#import <SynthesisCore/SIMFunctions.h>
#import <SynthesisCore/SIMPatternMatch.h>
#import <SynthesisCore/Simulator.h>
#import <stdio.h>

@implementation SIMNetwork (SIMRemoteNetwork)

- (bycopy NSData *)swappedSummedInputChannelCurrentsForLayer:(in int)layer
/*"
    Returns a data object containing an array of NSSwappedFloats 
    containing the summed channel input for the layer.
"*/
{
    int i,j,l=layer,numRows,numColumns;
    NSSwappedFloat *data;
    NSMutableData *dataObj;

    if(layerInfo[l].node != localNode)return nil;

    numRows = layerInfo[layer].numRows;
    numColumns = layerInfo[layer].numColumns;

    dataObj = [[NSMutableData dataWithLength:sizeof(NSSwappedFloat)*numColumns*numRows] retain];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (NSSwappedFloat *)[dataObj mutableBytes];

    for(i=0;i<numRows;i++){
        for(j=0;j<numColumns;j++){
            if(layers[l][i][j].type == SIM_UndefinedType)
                data[i*numColumns+j] = NSConvertHostFloatToSwapped(0.0);
            else {
                SIMCell *cellModel = [layers[l][i][j].type cellCompartmentAtIndex:0];
                float input = [layers[l][i][j].type summedInputChannelCurrents:&layers[l][i][j] forCellModel:cellModel];
                data[i*numColumns+j] = NSConvertHostFloatToSwapped(input);
            }
        }
    }

    return [dataObj autorelease];
}

- (bycopy NSData *)summedInputChannelCurrentsForLayer:(in int)layer
/*"
    Returns a data object containing an array of floats 
    containing the summed channel input for the layer.
"*/
{
    int i,j,l=layer,numRows,numColumns;
    float *data;
    NSMutableData *dataObj;

    if(layerInfo[l].node != localNode)return nil;

    numRows = layerInfo[layer].numRows;
    numColumns = layerInfo[layer].numColumns;

    dataObj = [[NSMutableData dataWithLength:sizeof(float)*numColumns*numRows] retain];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (float *)[dataObj mutableBytes];

    for(i=0;i<numRows;i++){
        for(j=0;j<numColumns;j++){
            if(layers[l][i][j].type == SIM_UndefinedType)
                data[i*numColumns+j] = 0.0;
            else {
                SIMCell *cellModel = [layers[l][i][j].type cellCompartmentAtIndex:0];
                data[i*numColumns+j] = [layers[l][i][j].type summedInputChannelCurrents:&layers[l][i][j] forCellModel:cellModel];
            }
        }
    }

    return [dataObj autorelease];
}

- (bycopy NSData *)swappedSummedIntrinsicChannelCurrentsForLayer:(in int)layer
/*"
    Returns a data object containing an array of NSSwappedFloats 
    containing the summed channel input for the layer.
"*/
{
    int i,j,l=layer,numRows,numColumns;
    NSSwappedFloat *data;
    NSMutableData *dataObj;

    if(layerInfo[l].node != localNode)return nil;

    numRows = layerInfo[layer].numRows;
    numColumns = layerInfo[layer].numColumns;

    dataObj = [[NSMutableData dataWithLength:sizeof(NSSwappedFloat)*numColumns*numRows] retain];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (NSSwappedFloat *)[dataObj mutableBytes];

    for(i=0;i<numRows;i++){
        for(j=0;j<numColumns;j++){
            if(layers[l][i][j].type == SIM_UndefinedType)
                data[i*numColumns+j] = NSConvertHostFloatToSwapped(0.0);
            else {
                SIMCell *cellModel = [layers[l][i][j].type cellCompartmentAtIndex:0];
                float input = [layers[l][i][j].type summedIntrinsicChannelCurrents:&layers[l][i][j] forCellModel:cellModel];
                data[i*numColumns+j] = NSConvertHostFloatToSwapped(input);
            }
        }
    }

    return [dataObj autorelease];
}

- (bycopy NSData *)summedIntrinsicChannelCurrentsForLayer:(in int)layer
/*"
    Returns a data object containing an array of floats 
    containing the summed channel input for the layer.
"*/
{
    int i,j,l=layer,numRows,numColumns;
    float *data;
    NSMutableData *dataObj;

    if(layerInfo[l].node != localNode)return nil;

    numRows = layerInfo[layer].numRows;
    numColumns = layerInfo[layer].numColumns;

    dataObj = [[NSMutableData dataWithLength:sizeof(float)*numColumns*numRows] retain];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (float *)[dataObj mutableBytes];

    for(i=0;i<numRows;i++){
        for(j=0;j<numColumns;j++){
            if(layers[l][i][j].type == SIM_UndefinedType)
                data[i*numColumns+j] = 0.0;
            else {
                SIMCell *cellModel = [layers[l][i][j].type cellCompartmentAtIndex:0];
                data[i*numColumns+j] = [layers[l][i][j].type summedIntrinsicChannelCurrents:&layers[l][i][j] forCellModel:cellModel];
            }
        }
    }

    return [dataObj autorelease];
}


- (double) summedInputChannelCurrentsForCell:(in SIMPosition *)pos
/*"
    Returns the summed channel input for the cell at position pos.  This uses the first cell model to compute the current.
"*/
{
    int i = pos->y;
    int j = pos->x;
    int l = pos->z;
    double value;

    if(layerInfo[l].node != localNode)return 0;

    if(layers[l][i][j].type == SIM_UndefinedType)
        value = 0.0;
    else {
        SIMCell *cellModel = [layers[l][i][j].type cellCompartmentAtIndex:0];
        value = [layers[l][i][j].type summedInputChannelCurrents:&layers[l][i][j] forCellModel:cellModel];
    }

    return value;
}

- (double) summedIntrinsicChannelCurrentsForCell:(in SIMPosition *)pos
/*"
    Returns the summed channel input for the cell at position pos.  This uses the first cell model to compute the current.
"*/
{
    int i = pos->y;
    int j = pos->x;
    int l = pos->z;
    double value;

    if(layerInfo[l].node != localNode)return 0;

    if(layers[l][i][j].type == SIM_UndefinedType)
        value = 0.0;
    else {
        SIMCell *cellModel = [layers[l][i][j].type cellCompartmentAtIndex:0];
        value = [layers[l][i][j].type summedIntrinsicChannelCurrents:&layers[l][i][j] forCellModel:cellModel];
    }

    return value;
}


- (bycopy NSData *)swappedValuesForIntrinsicChannel:(in int)channel atIndex:(in int)variable withType:(bycopy NSString *)type forLayer:(in int)layer
/*"
    Returns a data object containing an array of NSSwappedFloats containing the channel data at the variable index
    in layer for a given type of cell.
"*/
{
    int		i,j,l=layer,numRows,numColumns;
    NSSwappedFloat *data;
    NSMutableData *dataObj;
	
    if(layerInfo[l].node != localNode)return nil;

    numRows = layerInfo[layer].numRows;
    numColumns = layerInfo[layer].numColumns;

    dataObj = [[NSMutableData dataWithLength:sizeof(NSSwappedFloat)*numColumns*numRows] retain];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (NSSwappedFloat *)[dataObj mutableBytes];

	if(!type || ([type isEqual:@""])) return dataObj;

    for(i=0;i<numRows;i++){
        for(j=0;j<numColumns;j++){
            SIMType *theType = layers[l][i][j].type;
            if((theType == SIM_UndefinedType) || ![[theType name] isEqual:type] ||
                (channel < 0) || (channel >= [theType numIntrinsicChannels]) || (variable < 0) || 
                (variable > [[theType intrinsicChannelAtIndex:channel] numVariables]))
                data[i*numColumns+j] = NSConvertHostFloatToSwapped(0.0);
            else data[i*numColumns+j] =
                NSConvertHostFloatToSwapped((float)SIMStateValueAsDouble(layers[l][i][j].channel[channel],variable));
        }
    }

    return [dataObj autorelease];
}

- (bycopy NSData *)swappedValuesForInputChannel:(in int)channel atIndex:(in int)variable withType:(bycopy NSString *)type forLayer:(in int)layer
/*"
    Returns a data object containing an array of NSSwappedFloats containing the channel data at the variable index
    in layer for a given type of cell.
"*/
{
    int		i,j,l=layer,numRows,numColumns;
    NSSwappedFloat *data;
    NSMutableData *dataObj;

    if(layerInfo[l].node != localNode)return nil;

    numRows = layerInfo[layer].numRows;
    numColumns = layerInfo[layer].numColumns;

    dataObj = [[NSMutableData dataWithLength:sizeof(NSSwappedFloat)*numColumns*numRows] retain];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (NSSwappedFloat *)[dataObj mutableBytes];

	if(!type || ([type isEqual:@""])) return dataObj;

    for(i=0;i<numRows;i++){
        for(j=0;j<numColumns;j++){
            SIMType *theType = layers[l][i][j].type;
            if((theType == SIM_UndefinedType) || ![[theType name] isEqual:type] ||
                (channel < 0) || (channel >= [theType numInputChannels]) || (variable < 0) || 
                (variable > [[theType inputChannelAtIndex:channel] numVariables]))
                data[i*numColumns+j] = NSConvertHostFloatToSwapped(0.0);
            else data[i*numColumns+j] =
                NSConvertHostFloatToSwapped((float)SIMStateValueAsDouble(layers[l][i][j].inputChannel[channel],variable));
        }
    }

    return [dataObj autorelease];
}

- (bycopy NSData *)swappedValuesForCellCompartment:(in int)cell atIndex:(in int)variable withType:(bycopy NSString *)type forLayer:(in int)layer
/*"
    Returns a data object containing an array of NSSwappedFloats containing the cell data at the variable index
    in layer for a given type of cell.
"*/
{
    int i,j,l=layer,numRows,numColumns;
    NSSwappedFloat *data;
    NSMutableData *dataObj;

    if(layerInfo[l].node != localNode)return nil;

    numRows = layerInfo[layer].numRows;
    numColumns = layerInfo[layer].numColumns;

    dataObj = [NSMutableData dataWithLength:sizeof(NSSwappedFloat)*numColumns*numRows];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (NSSwappedFloat *)[dataObj mutableBytes];

	if(!type || ([type isEqual:@""])) return dataObj;

    for(i=0;i<numRows;i++){
        for(j=0;j<numColumns;j++){
            SIMType *theType = layers[l][i][j].type;
            if((theType == SIM_UndefinedType) || ![[theType name] isEqual:type] ||
                (cell < 0) || (cell >= [theType numCellCompartments]) || (variable < 0) || 
                (variable > [[theType cellCompartmentAtIndex:cell] numVariables]))
                data[i*numColumns+j] = NSConvertHostFloatToSwapped(0.0);
            else 
                data[i*numColumns+j] = NSConvertHostFloatToSwapped((float)SIMStateValueAsDouble(layers[l][i][j].cell[cell],variable));
        }
    }

    return dataObj;
}

- (bycopy NSData *)summedStateVariablesForModelOfType:(in int)modelType matchingPattern:(bycopy NSString *)patternString
/*"
    Returns a data object containing an array of NSSwappedFloats containing the channel data at the variable index
    in layer for a given type of cell.
	typeString = "Layer.Type.Model.Variable" where each component can contain asterisks to act as wildcards.
"*/
{
    int		layer,type,modelIndex,i,j,numRows,numColumns;
    float *data;
	SIMModel *modelObject = nil;
    NSMutableData *dataObj = nil;
	NSArray *patternArray;
	NSString *modelName = nil,*variableName = nil;
	NSString *layerPattern,*typePattern,*modelPattern,*variablePattern;
	
	patternArray = [patternString componentsSeparatedByString:SIM_TypeSeparator];
	
	if([patternString isEqual:@"*"])patternArray = [NSArray arrayWithObjects:@"*",@"*",@"*",@"*",nil];
	else if([patternArray count] != 4)return nil;

	layerPattern = [patternArray objectAtIndex:0];
	typePattern = [patternArray objectAtIndex:1];
	modelPattern = [patternArray objectAtIndex:2];
	variablePattern = [patternArray objectAtIndex:3];
	
	layer = [self indexForLayerWithKey:layerPattern];
	
	if (layer < 0)return nil;
	
	//for(layer = 0; layer < numLayers; layers++){
		if(layerInfo[layer].node != localNode)return nil;
		//if(!SIMPatternMatch([layerInfo[layer].name UTF8String],[layerPattern UTF8String],NULL))continue;
		numRows = layerInfo[layer].numRows;
		numColumns = layerInfo[layer].numColumns;

		dataObj = [[NSMutableData dataWithLength:sizeof(float)*numColumns*numRows] retain];
		if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
		data = (float *)[dataObj mutableBytes];
		
		for(type = 0; type < layerInfo[layer].numTypes; type++){
			SIMType *typeObject = layerInfo[layer].types[type];
			NSString *typeName = [typeObject name];
			if(SIMPatternMatch([typePattern UTF8String],[typeName UTF8String],NULL))continue;

			NSEnumerator *modelEnum = nil;
			
			switch(modelType){
				case SIM_IntrinsicChannelType:
					modelEnum = [[typeObject allIntrinsicChannelKeys] objectEnumerator];
					break;
				case SIM_InputChannelType:
					modelEnum = [[typeObject allInputChannelKeys] objectEnumerator];
					break;
				case SIM_CellCompartmentType:
					modelEnum = [[typeObject allCellCompartmentKeys] objectEnumerator];
					break;
			}
			
			while(modelName = [modelEnum nextObject]){
				if(SIMPatternMatch([modelPattern UTF8String],[modelName UTF8String],NULL))continue;

				switch(modelType){
					case SIM_IntrinsicChannelType:
						modelObject = [typeObject intrinsicChannelWithName:modelName];
						break;
					case SIM_InputChannelType:
						modelObject = [typeObject inputChannelWithName:modelName];
						break;
					case SIM_CellCompartmentType:
						modelObject = [typeObject cellCompartmentWithName:modelName];
						break;
				}
				
				modelIndex = [modelObject assignedIndex];

				NSEnumerator *variableEnum = [[modelObject allVariableKeys] objectEnumerator];
				unsigned int variableIndex;
				
				while(variableName = [variableEnum nextObject]){
					if(SIMPatternMatch([variablePattern UTF8String],[variableName UTF8String],NULL))continue;
					variableIndex = [modelObject indexOfVariable:variableName];
					for(i=0;i<numRows;i++){
						for(j=0;j<numColumns;j++){
							SIMType *theType = layers[layer][i][j].type;
							if((theType == SIM_UndefinedType) || ![[theType name] isEqual:typeName])continue;
							else 
							switch(modelType){
								case SIM_IntrinsicChannelType:
									data[i*numColumns+j] += (float)layers[layer][i][j].channel[modelIndex][variableIndex].state.doubleValue;
									break;
								case SIM_InputChannelType:
									data[i*numColumns+j] += (float)layers[layer][i][j].inputChannel[modelIndex][variableIndex].state.doubleValue;
									break;
								case SIM_CellCompartmentType:
									data[i*numColumns+j] += (float)layers[layer][i][j].cell[modelIndex][variableIndex].state.doubleValue;
									break;
							}
						}
					}
				}
			}
		}
	//}

    return [dataObj autorelease];
}


- (bycopy NSData *)valuesForIntrinsicChannel:(in int)channel atIndex:(in int)variable withType:(bycopy NSString *)type forLayer:(in int)layer
/*"
    Returns a data object containing an array of NSSwappedFloats containing the channel data at the variable index
    in layer for a given type of cell.
"*/
{
    int		i,j,l=layer,numRows,numColumns;
    float *data;
    NSMutableData *dataObj;

    if(layerInfo[l].node != localNode)return nil;

    numRows = layerInfo[layer].numRows;
    numColumns = layerInfo[layer].numColumns;

    dataObj = [[NSMutableData dataWithLength:sizeof(float)*numColumns*numRows] retain];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (float *)[dataObj mutableBytes];

	if(!type || ([type isEqual:@""])) return dataObj;

    for(i=0;i<numRows;i++){
        for(j=0;j<numColumns;j++){
            SIMType *theType = layers[l][i][j].type;
            if((theType == SIM_UndefinedType) || ![[layers[l][i][j].type name] isEqual:type])
                data[i*numColumns+j]= 0.0;
            else data[i*numColumns+j] =
                (float)SIMStateValueAsDouble(layers[l][i][j].channel[channel],variable);
        }
    }

    return [dataObj autorelease];
}

- (bycopy NSData *)valuesForInputChannel:(in int)channel atIndex:(in int)variable withType:(bycopy NSString *)type forLayer:(in int)layer
/*"
    Returns a data object containing an array of NSSwappedFloats containing the channel data at the variable index
    in layer for a given type of cell.
"*/
{
    int		i,j,l=layer,numRows,numColumns;
    float *data;
    NSMutableData *dataObj;

    if(layerInfo[l].node != localNode)return nil;

    numRows = layerInfo[layer].numRows;
    numColumns = layerInfo[layer].numColumns;

    dataObj = [[NSMutableData dataWithLength:sizeof(float)*numColumns*numRows] retain];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (float *)[dataObj mutableBytes];

	if(!type || ([type isEqual:@""])) return dataObj;

    for(i=0;i<numRows;i++){
        for(j=0;j<numColumns;j++){
            SIMType *theType = layers[l][i][j].type;
            if((theType == SIM_UndefinedType) || ![[layers[l][i][j].type name] isEqual:type])
                data[i*numColumns+j]= 0.0;
            else data[i*numColumns+j] =
                (float)SIMStateValueAsDouble(layers[l][i][j].inputChannel[channel],variable);
        }
    }

    return [dataObj autorelease];
}

- (bycopy NSData *)valuesForCellCompartment:(in int)cell atIndex:(in int)variable withType:(bycopy NSString *)type forLayer:(in int)layer
/*"
    Returns a data object containing an array of NSSwappedFloats containing the cell data at the variable index
    in layer for a given type of cell.
"*/
{
    int i,j,l=layer,numRows,numColumns;
    float *data;
    NSMutableData *dataObj;

    if(layerInfo[l].node != localNode)return nil;

    numRows = layerInfo[layer].numRows;
    numColumns = layerInfo[layer].numColumns;

    dataObj = [NSMutableData dataWithLength:sizeof(float)*numColumns*numRows];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (float *)[dataObj mutableBytes];

	if(!type || ([type isEqual:@""])) return dataObj;

    for(i=0;i<numRows;i++){
        for(j=0;j<numColumns;j++){
            SIMType *theType = layers[l][i][j].type;
            if((theType == SIM_UndefinedType) || ![[theType name] isEqual:type])
                data[i*numColumns+j] = 0.0;
            else 
                data[i*numColumns+j] = (float)SIMStateValueAsDouble(layers[l][i][j].cell[cell],variable);
        }
    }

    return dataObj;
}

- (bycopy NSData *)valuesForIntrinsicChannelVariable:(in NSString *)varName withType:(bycopy NSString *)type forLayer:(in int)layer
/*"
    Returns a data object containing an array of floats containing the channel data at the variable index
    in layer for a given type of cell.
"*/
{
    NSArray *varArray = [varName componentsSeparatedByString:@"."];
    if([varArray count] < 2)return nil;
	int typeIndex = [self indexForType:type inLayer:layerInfo[layer].name];
	SIMType *theType = layerInfo[layer].types[typeIndex];
	int channel = [theType indexOfIntrinsicChannel:[varArray objectAtIndex:0]];
	int variable = [[theType intrinsicChannelAtIndex:channel] indexOfVariable:[varArray objectAtIndex:1]];
        
    if(layerInfo[layer].node != localNode)return nil;

	return [self valuesForIntrinsicChannel:channel atIndex:variable withType:type forLayer:layer];
}

- (bycopy NSData *)valuesForInputChannelVariable:(in NSString *)varName withType:(bycopy NSString *)type forLayer:(in int)layer
/*"
    Returns a data object containing an array of floats containing the channel data at the variable index
    in layer for a given type of cell.
"*/
{
    NSArray *varArray = [varName componentsSeparatedByString:@"."];
    if([varArray count] < 2)return nil;
	int typeIndex = [self indexForType:type inLayer:layerInfo[layer].name];
	SIMType *theType = layerInfo[layer].types[typeIndex];
	int channel = [theType indexOfInputChannel:[varArray objectAtIndex:0]];
	int variable = [[theType inputChannelAtIndex:channel] indexOfVariable:[varArray objectAtIndex:1]];
        
    if(layerInfo[layer].node != localNode)return nil;

	return [self valuesForInputChannel:channel atIndex:variable withType:type forLayer:layer];
}

- (bycopy NSData *)valuesForCellCompartmentVariable:(in NSString *)varName withType:(bycopy NSString *)type forLayer:(in int)layer
/*"
    Returns a data object containing an array of floats containing the cell data at the variable index
    in layer for a given type of cell.
"*/
{
    NSArray *varArray = [varName componentsSeparatedByString:@"."];
    if([varArray count] < 2)return nil;
	int typeIndex = [self indexForType:type inLayer:layerInfo[layer].name];
	SIMType *theType = layerInfo[layer].types[typeIndex];
	int cell = [theType indexOfCellCompartment:[varArray objectAtIndex:0]];
	int variable = [[theType cellCompartmentAtIndex:cell] indexOfVariable:[varArray objectAtIndex:1]];
        
    if(layerInfo[layer].node != localNode)return nil;

	return [self valuesForCellCompartment:cell atIndex:variable withType:type forLayer:layer];
}

@end 

@implementation SIMNetwork (SIMNetworkStatistics)


- (id)valueOfVariable:(int)variable atIndex:(int)model modelType:(SIMModelType)type position:(SIMPosition *)pos
{    
	BOOL dummy = NO;
	
    if(layerInfo[pos->z].node != localNode)return nil;

    [self checkBoundary:pos connect:&dummy conditions:SIM_PeriodicBoundary info:nil];

    switch(type){
		case SIM_IntrinsicChannelType:
			return SIMGetStateValue(layers[pos->z][pos->y][pos->x].channel[model],variable);
		case SIM_InputChannelType:
			return SIMGetStateValue(layers[pos->z][pos->y][pos->x].inputChannel[model],variable);
		case SIM_CellCompartmentType:
			return SIMGetStateValue(layers[pos->z][pos->y][pos->x].cell[model],variable);
		default:
			return nil;
	}
}

- (void)setValue:(NSNumber *)value ofVariable:(int)variable atIndex:(int)model modelType:(SIMModelType)type position:(SIMPosition *)pos
{    
	BOOL dummy = NO;
	
    if(layerInfo[pos->z].node != localNode)return ;

    [self checkBoundary:pos connect:&dummy conditions:SIM_PeriodicBoundary info:nil];

    switch(type){
		case SIM_IntrinsicChannelType:
			SIMSetStateValue(layers[pos->z][pos->y][pos->x].channel[model],variable,value);
		case SIM_InputChannelType:
			SIMSetStateValue(layers[pos->z][pos->y][pos->x].inputChannel[model],variable,value);
		case SIM_CellCompartmentType:
			SIMSetStateValue(layers[pos->z][pos->y][pos->x].cell[model],variable,value);
		default:
			return;
	}
}



- valueForCellCompartment:(int)model atIndex:(int)variable forCell:(SIMPosition *)pos
{
    return [self valueOfVariable:variable atIndex:model modelType:SIM_CellCompartmentType position:pos];
}

- valueForIntrinsicChannel:(int)model atIndex:(int)variable forCell:(SIMPosition *)pos
{
	return [self valueOfVariable:variable atIndex:model modelType:SIM_IntrinsicChannelType position:pos];
}

- valueForInputChannel:(int)model atIndex:(int)variable forCell:(SIMPosition *)pos
{
    return [self valueOfVariable:variable atIndex:model modelType:SIM_InputChannelType position:pos];
}

- valueForCellCompartmentVariable:(NSString *)varName forCell:(SIMPosition *)pos
/*"
    Cell variable is specified as a string consisting of: modelname.variablename
"*/
{
    BOOL dummy;
    SIMType *theType;
    NSArray *varArray = [varName componentsSeparatedByString:@"."];
        
    if(layerInfo[pos->z].node != localNode)return nil;

    if([varArray count] < 2)return nil;

    [self checkBoundary:pos connect:&dummy conditions:SIM_PeriodicBoundary info:nil];

    theType = layers[pos->z][pos->y][pos->x].type;
        
    if(theType == SIM_UndefinedType) return nil;
    else {
        int cell = [theType indexOfCellCompartment:[varArray objectAtIndex:0]];
        int variable = [[theType cellCompartmentAtIndex:cell] indexOfVariable:[varArray objectAtIndex:1]];
        return SIMGetStateValue(layers[pos->z][pos->y][pos->x].cell[cell],variable);
    }
}

- valueForIntrinsicChannelVariable:(NSString *)varName forCell:(SIMPosition *)pos
/*"
    Channel variable is specified as a string consisting of: modelname.variablename
"*/
{
    BOOL dummy;
    SIMType *theType;
    NSArray *varArray = [varName componentsSeparatedByString:@"."];
        
    if(layerInfo[pos->z].node != localNode)return nil;

    if([varArray count] < 2)return nil;

    [self checkBoundary:pos connect:&dummy conditions:SIM_PeriodicBoundary info:nil];

    theType = layers[pos->z][pos->y][pos->x].type;
        
    if(theType == SIM_UndefinedType) return nil;
    else {
        int channel = [theType indexOfIntrinsicChannel:[varArray objectAtIndex:0]];
        int variable = [[theType intrinsicChannelAtIndex:channel] indexOfVariable:[varArray objectAtIndex:1]];
        return SIMGetStateValue(layers[pos->z][pos->y][pos->x].channel[channel],variable);
    }
}

- valueForInputChannelVariable:(NSString *)varName forCell:(SIMPosition *)pos
/*"
    Channel variable is specified as a string consisting of: modelname.variablename
"*/
{
    BOOL dummy;
    SIMType *theType;
    NSArray *varArray = [varName componentsSeparatedByString:@"."];
        
    if(layerInfo[pos->z].node != localNode)return NULL;

    if([varArray count] < 2)return nil;

    [self checkBoundary:pos connect:&dummy conditions:SIM_PeriodicBoundary info:nil];

    theType = layers[pos->z][pos->y][pos->x].type;
        
    if(theType == SIM_UndefinedType) return nil;
    else {
        int channel = [theType indexOfInputChannel:[varArray objectAtIndex:0]];
        int variable = [[theType inputChannelAtIndex:channel] indexOfVariable:[varArray objectAtIndex:1]];
        return SIMGetStateValue(layers[pos->z][pos->y][pos->x].inputChannel[channel],variable);
    }
}

- (void)setValue:(id)value forCellCompartmentVariable:(NSString *)varName forCell:(SIMPosition *)pos
/*"
    Cell variable is specified as a string consisting of: modelname.variablename
"*/
{
    SIMType *theType;
    NSArray *varArray = [varName componentsSeparatedByString:@"."];
        
    if(layerInfo[pos->z].node != localNode)return;

    if([varArray count] < 2)return;

    theType = layers[pos->z][pos->y][pos->x].type;
        
    if(theType == SIM_UndefinedType) return;
    else {
        int cell = [theType indexOfCellCompartment:[varArray objectAtIndex:0]];
        int variable = [[theType cellCompartmentAtIndex:cell] indexOfVariable:[varArray objectAtIndex:1]];
        SIMSetStateValue(layers[pos->z][pos->y][pos->x].cell[cell],variable,value);
    }
}

- (void)setValue:(id)value forIntrinsicChannelVariable:(NSString *)varName forCell:(SIMPosition *)pos
/*"
    Channel variable is specified as a string consisting of: modelname.variablename
"*/
{
    BOOL dummy;
    SIMType *theType;
    NSArray *varArray = [varName componentsSeparatedByString:@"."];
        
    if(layerInfo[pos->z].node != localNode)return;

    if([varArray count] < 2)return;

    [self checkBoundary:pos connect:&dummy conditions:SIM_PeriodicBoundary info:nil];

    theType = layers[pos->z][pos->y][pos->x].type;
        
    if(theType == SIM_UndefinedType) return;
    else {
        int channel = [theType indexOfIntrinsicChannel:[varArray objectAtIndex:0]];
        int variable = [[theType intrinsicChannelAtIndex:channel] indexOfVariable:[varArray objectAtIndex:1]];
        SIMSetStateValue(layers[pos->z][pos->y][pos->x].channel[channel],variable,value);
    }
}

- (void)setValue:(id)value forInputChannelVariable:(NSString *)varName forCell:(SIMPosition *)pos
/*"
    Channel variable is specified as a string consisting of: modelname.variablename
"*/
{
    BOOL dummy;
    SIMType *theType;
    NSArray *varArray = [varName componentsSeparatedByString:@"."];
        
    if(layerInfo[pos->z].node != localNode)return;

    if([varArray count] < 2)return;

    [self checkBoundary:pos connect:&dummy conditions:SIM_PeriodicBoundary info:nil];

    theType = layers[pos->z][pos->y][pos->x].type;
        
    if(theType == SIM_UndefinedType) return;
    else {
        int channel = [theType indexOfInputChannel:[varArray objectAtIndex:0]];
        int variable = [[theType inputChannelAtIndex:channel] indexOfVariable:[varArray objectAtIndex:1]];
        SIMSetStateValue(layers[pos->z][pos->y][pos->x].inputChannel[channel],variable,value);
    }
}


- (double)membranePotentialForCell:(SIMPosition *)pos
/*"
    Returns the summed channel input for the cell at position pos.  This uses the first cell model to compute the current.
"*/
{
    int i = pos->y;
    int j = pos->x;
    int l = pos->z;
    double value;

    if(layerInfo[l].node != localNode)return 0;

    if(layers[l][i][j].type == SIM_UndefinedType)
        value = 0.0;
    else {
        value = [layers[l][i][j].type membranePotential:&layers[l][i][j] atIndex:0];
    }

    return value;
}


- (NSData *)membranePotentialForCells:(NSArray *)positions
/*"
    Returns a data object containing an array of floating point values containing the membrane potential
    for cells at the given positions (an NSValueArray or NSArray of NSValues containing SIMPositions).
"*/
{
    int i,numCells;
    NSEnumerator *cellEnum = [positions objectEnumerator];
    float *data;
    NSMutableData *dataObj;
    NSValue *value;
//    BOOL valid = NO;
    
    numCells = [positions count];

    dataObj = [[NSMutableData dataWithLength:sizeof(float)*numCells] retain];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (float *)[dataObj mutableBytes];

    i = 0;
    while(value = [cellEnum nextObject]){
        SIMPosition curPos;
        SIMType *theType;
        [value getValue:&curPos];

        theType = layers[curPos.z][curPos.y][curPos.x].type;
        if(theType == SIM_UndefinedType)
            data[i++] = 0.0;
        else data[i++] = [theType membranePotential:&layers[curPos.z][curPos.y][curPos.x]];
    }
    return [dataObj autorelease];
}


- (float)meanFiringRateForLayer:(NSString *)layerName
/*"
    Returns the mean firing rate in Hz for the given layer.
"*/
{
    int l = [self indexForLayerWithKey:layerName];
    return [self meanFiringRateForLayerAtIndex:l];
}

- (float)meanFiringRateForLayerAtIndex:(int)l
/*"
    Returns the mean firing rate in Hz for the given layer.
"*/
{
    float count = [self countOfSpikingCellsInLayer:l];
    return (float)1000.0*(count/(layerInfo[l].numRows*layerInfo[l].numColumns))/([self dt]); // Returns rate for this instant in Hz
}

- (float)meanComputationalLoadForLayer:(NSString *)layerName
/*"
    Returns the mean firing rate in Hz for the given layer.
"*/
{
    int l = [self indexForLayerWithKey:layerName];
    return [self meanComputationalLoadForLayerAtIndex:l];
}

- (float)meanComputationalLoadForLayerAtIndex:(int)l
/*"
    Returns the mean firing rate in Hz for the given layer.
"*/
{
    float count = [self countOfInteractingCellsInLayer:l];
    return (float)1000.0*(count/(layerInfo[l].numRows*layerInfo[l].numColumns))/([self dt]); // Returns rate for this instant in Hz
}


- (float) totalComputationalLoad
{
    int l;
    float cost = 0.0;
    for (l = 0; l < numLayers; l++){
        cost += [self computationalLoadForLayer:l];
    }
    return cost;
}

- (float) computationalLoadForLayer:(int)l
{
    return (float)layerInfo[l].numConnections * (float) [self meanComputationalLoadForLayerAtIndex:l];
}


- (float)averageNumberOfInputsForType:(NSString *)type
{
    return [self averageNumberOfInputsForType:type fromType:@"*"];
}

- (float)averageWeightOfInputsForType:(NSString *)type
{
    return [self averageWeightOfInputsForType:type fromType:@"*"];
}

- (float)averageLatencyOfInputsForType:(NSString *)type
{
    return [self averageLatencyOfInputsForType:type fromType:@"*"];
}

- (float)averageNumberOfInputsForType:(NSString *)type fromType:(NSString *)fromType
{
    return [self averageNumberOfInputsForType:type fromTypes:[NSArray arrayWithObject:fromType]];
}

- (float)averageNumberOfInputsForType:(NSString *)type fromTypes:(NSArray *)types
/*"
 This routine cycles through all the cells of a given type in the network and averages
 the total number of inputs for the given types provided.
"*/
{
        int		i,j,l;
        float		count = 0.0;
        float		inputs = 0.0;
        NSString *layerPattern,*typePattern;
        NSArray *typeComponents = [type componentsSeparatedByString:SIM_TypeSeparator];
        
        if([type isEqual:@"*"])typeComponents = [NSArray arrayWithObjects:@"*",@"*",nil];
        else if([typeComponents count] == 1) typeComponents = [NSArray arrayWithObjects:[typeComponents objectAtIndex:0],@"*",nil];
        else if([typeComponents count] != 2)return -1.0;
        
        layerPattern = [typeComponents objectAtIndex:0];
        typePattern = [typeComponents objectAtIndex:1];

        for(l=0;l<numLayers;l++){
            if(!SIMPatternMatch([layerPattern UTF8String],[layerInfo[l].name UTF8String],NULL)){
                for(i=0;i<layerInfo[l].numRows;i++){
                    for(j=0;j<layerInfo[l].numColumns;j++){
                        if(!SIMPatternMatch([typePattern UTF8String],[[layers[l][i][j].type name] UTF8String],NULL)){
                            count++;
                            inputs += [layers[l][i][j].type totalNumberOfInputs:&layers[l][i][j] fromTypes:types];
                        }
                    }
                }    
            }
        }
        return (float)inputs/count;
}

- (float)averageWeightOfInputsForType:(NSString *)type fromType:(NSString *)fromType
{
    return [self averageWeightOfInputsForType:type fromTypes:[NSArray arrayWithObject:fromType]];
}

- (float)averageWeightOfInputsForType:(NSString *)type fromTypes:(NSArray *)types
/* This routine cycles through all the cells in the network and counts
 * all currently firing cells for the given type.
 * If the type is nil then it counts all firing cells.
 */
{
        int		i,j,l;
        float		count = 0.0;
        float		inputs = 0.0;
        NSString *layerPattern,*typePattern;
        NSArray *typeComponents = [type componentsSeparatedByString:SIM_TypeSeparator];
        
        if([type isEqual:@"*"])typeComponents = [NSArray arrayWithObjects:@"*",@"*",nil];
        else if([typeComponents count] == 1) typeComponents = [NSArray arrayWithObjects:[typeComponents objectAtIndex:0],@"*",nil];
        else if([typeComponents count] != 2)return -1.0;
        
        layerPattern = [typeComponents objectAtIndex:0];
        typePattern = [typeComponents objectAtIndex:1];

        for(l=0;l<numLayers;l++){
            if(!SIMPatternMatch([layerPattern UTF8String],[layerInfo[l].name UTF8String],NULL)){
                for(i=0;i<layerInfo[l].numRows;i++){
                    for(j=0;j<layerInfo[l].numColumns;j++){
                        if(!SIMPatternMatch([typePattern UTF8String],[[layers[l][i][j].type name] UTF8String],NULL)){
                            count++;
                            inputs += [layers[l][i][j].type totalWeightOfInputs:&layers[l][i][j] fromTypes:types]/[layers[l][i][j].type totalNumberOfInputs:&layers[l][i][j] fromTypes:types];
                        }
                    }
                }    
            }
        }
        return (float)inputs/count;
}

- (float)averageLatencyOfInputsForType:(NSString *)type fromType:(NSString *)fromType
{
    return [self averageLatencyOfInputsForType:type fromTypes:[NSArray arrayWithObject:fromType]];
}

- (float)averageLatencyOfInputsForType:(NSString *)type fromTypes:(NSArray *)types
/* This routine cycles through all the cells in the network and counts
 * all currently firing cells for the given type.
 * If the type is nil then it counts all firing cells.
 */
{
        int		i,j,l;
        float		count = 0.0;
        float		inputs = 0.0;
        NSString *layerPattern,*typePattern;
        NSArray *typeComponents = [type componentsSeparatedByString:SIM_TypeSeparator];
        
        if([type isEqual:@"*"])typeComponents = [NSArray arrayWithObjects:@"*",@"*",nil];
        else if([typeComponents count] == 1) typeComponents = [NSArray arrayWithObjects:[typeComponents objectAtIndex:0],@"*",nil];
        else if([typeComponents count] != 2)return -1.0;
        
        layerPattern = [typeComponents objectAtIndex:0];
        typePattern = [typeComponents objectAtIndex:1];

        for(l=0;l<numLayers;l++){
            if(!SIMPatternMatch([layerPattern UTF8String],[layerInfo[l].name UTF8String],NULL)){
                for(i=0;i<layerInfo[l].numRows;i++){
                    for(j=0;j<layerInfo[l].numColumns;j++){
                        if(!SIMPatternMatch([typePattern UTF8String],[[layers[l][i][j].type name] UTF8String],NULL)){
                            count++;
                            inputs += [layers[l][i][j].type totalLatencyOfInputs:&layers[l][i][j] fromTypes:types]/[layers[l][i][j].type totalNumberOfInputs:&layers[l][i][j] fromTypes:types];
                        }
                    }
                }    
            }
        }
        return (float)inputs/count;
}

- (float)totalWeightOfInputsForCell:(SIMPosition)aCell
{
    assert(aCell.z <= numLayers);
    assert(aCell.y <= layerInfo[aCell.z].numRows);
    assert(aCell.x <= layerInfo[aCell.z].numColumns);
    return (float)[layers[aCell.z][aCell.y][aCell.x].type totalWeightOfInputs:&layers[aCell.z][aCell.y][aCell.x]];
}

- (float)totalNumberOfInputsForCell:(SIMPosition)aCell
{
    assert(aCell.z <= numLayers);
    assert(aCell.y <= layerInfo[aCell.z].numRows);
    assert(aCell.x <= layerInfo[aCell.z].numColumns);
    return (float)[layers[aCell.z][aCell.y][aCell.x].type totalNumberOfInputs:&layers[aCell.z][aCell.y][aCell.x]];
}

- (float)totalLatencyOfInputsForCell:(SIMPosition)aCell
{
    assert(aCell.z <= numLayers);
    assert(aCell.y <= layerInfo[aCell.z].numRows);
    assert(aCell.x <= layerInfo[aCell.z].numColumns);
    return [layers[aCell.z][aCell.y][aCell.x].type totalLatencyOfInputs:&layers[aCell.z][aCell.y][aCell.x]];
}

- (float)totalNumberOfInputsForType:(NSString *)type
{
    return [self totalNumberOfInputsForType:type fromType:@"*"];
}

- (float)totalWeightOfInputsForType:(NSString *)type
{
    return [self totalWeightOfInputsForType:type fromType:@"*"];
}

- (float)totalLatencyOfInputsForType:(NSString *)type
{
    return [self totalLatencyOfInputsForType:type fromType:@"*"];
}

- (float)totalNumberOfInputsForType:(NSString *)type fromType:(NSString *)fromType
{
    return [self totalNumberOfInputsForType:type fromTypes:[NSArray arrayWithObject:fromType]];
}

- (float)totalNumberOfInputsForType:(NSString *)type fromTypes:(NSArray *)types
/*"
 This routine cycles through all the cells of a given type in the network and averages
 the total number of inputs for the given types provided.
"*/
{
        int		i,j,l;
        float		count = 0.0;
        float		inputs = 0.0;
        NSString *layerPattern,*typePattern;
        NSArray *typeComponents = [type componentsSeparatedByString:SIM_TypeSeparator];
        
        if([type isEqual:@"*"])typeComponents = [NSArray arrayWithObjects:@"*",@"*",nil];
        else if([typeComponents count] == 1) typeComponents = [NSArray arrayWithObjects:[typeComponents objectAtIndex:0],@"*",nil];
        else if([typeComponents count] != 2)return -1.0;
        
        layerPattern = [typeComponents objectAtIndex:0];
        typePattern = [typeComponents objectAtIndex:1];

        for(l=0;l<numLayers;l++){
            if(!SIMPatternMatch([layerPattern UTF8String],[layerInfo[l].name UTF8String],NULL)){
                for(i=0;i<layerInfo[l].numRows;i++){
                    for(j=0;j<layerInfo[l].numColumns;j++){
                        if(!SIMPatternMatch([typePattern UTF8String],[[layers[l][i][j].type name] UTF8String],NULL)){
                            count++;
                            inputs += (float)[layers[l][i][j].type totalNumberOfInputs:&layers[l][i][j] fromTypes:types];
                        }
                    }
                }    
            }
        }
        return inputs;
}

- (float)totalWeightOfInputsForType:(NSString *)type fromType:(NSString *)fromType
{
    return [self totalWeightOfInputsForType:type fromTypes:[NSArray arrayWithObject:fromType]];
}

- (float)totalWeightOfInputsForType:(NSString *)type fromTypes:(NSArray *)types
/* This routine cycles through all the cells in the network and counts
 * all currently firing cells for the given type.
 * If the type is nil then it counts all firing cells.
 */
{
        int		i,j,l;
        float		count = 0.0;
        float		inputs = 0.0;
        NSString *layerPattern,*typePattern;
        NSArray *typeComponents = [type componentsSeparatedByString:SIM_TypeSeparator];
        
        if([type isEqual:@"*"])typeComponents = [NSArray arrayWithObjects:@"*",@"*",nil];
        else if([typeComponents count] == 1) typeComponents = [NSArray arrayWithObjects:[typeComponents objectAtIndex:0],@"*",nil];
        else if([typeComponents count] != 2)return -1.0;
        
        layerPattern = [typeComponents objectAtIndex:0];
        typePattern = [typeComponents objectAtIndex:1];

        for(l=0;l<numLayers;l++){
            if(!SIMPatternMatch([layerPattern UTF8String],[layerInfo[l].name UTF8String],NULL)){
                for(i=0;i<layerInfo[l].numRows;i++){
                    for(j=0;j<layerInfo[l].numColumns;j++){
                        if(!SIMPatternMatch([typePattern UTF8String],[[layers[l][i][j].type name] UTF8String],NULL)){
                            count++;
                            inputs += [layers[l][i][j].type totalWeightOfInputs:&layers[l][i][j] fromTypes:types];
                        }
                    }
                }    
            }
        }
        return inputs;
}

- (float)totalLatencyOfInputsForType:(NSString *)type fromType:(NSString *)fromType
{
    return [self totalLatencyOfInputsForType:type fromTypes:[NSArray arrayWithObject:fromType]];
}

- (float)totalLatencyOfInputsForType:(NSString *)type fromTypes:(NSArray *)types
/* This routine cycles through all the cells in the network and counts
 * all currently firing cells for the given type.
 * If the type is nil then it counts all firing cells.
 */
{
        int		i,j,l;
        float		count = 0.0;
        float		inputs = 0.0;
        NSString *layerPattern,*typePattern;
        NSArray *typeComponents = [type componentsSeparatedByString:SIM_TypeSeparator];
        
        if([type isEqual:@"*"])typeComponents = [NSArray arrayWithObjects:@"*",@"*",nil];
        else if([typeComponents count] == 1) typeComponents = [NSArray arrayWithObjects:[typeComponents objectAtIndex:0],@"*",nil];
        else if([typeComponents count] != 2)return -1.0;
        
        layerPattern = [typeComponents objectAtIndex:0];
        typePattern = [typeComponents objectAtIndex:1];

        for(l=0;l<numLayers;l++){
            if(!SIMPatternMatch([layerPattern UTF8String],[layerInfo[l].name UTF8String],NULL)){
                for(i=0;i<layerInfo[l].numRows;i++){
                    for(j=0;j<layerInfo[l].numColumns;j++){
                        if(!SIMPatternMatch([typePattern UTF8String],[[layers[l][i][j].type name] UTF8String],NULL)){
                            count++;
                            inputs += [layers[l][i][j].type totalLatencyOfInputs:&layers[l][i][j] fromTypes:types];
                        }
                    }
                }    
            }
        }
        return (float)inputs;
}

- (NSString *) spikingCellsFrom:(SIMPosition)cellA toCell:(SIMPosition)cellB
/*"
    DEPRECATED
    This routine cycles through all the cells in the network and builds
    a string which contains an entry for each currently active cell.
    The entry is of the format: x,y,z,time,type
"*/
{
        int		i,j;
        NSMutableString *tempString=[[NSMutableString alloc] init];

        for(i=cellA.y;i<cellB.y;i++){
                for(j=cellA.x;j<cellB.x;j++){
            if([layers[cellA.z][i][j].type isCellSpiking:&layers[cellA.z][i][j]]){
                                [tempString appendFormat:@"%d\t%d\t%f\n",i,j,time];
                        }
                }
        }

        return [tempString autorelease];
}


- (int)countOfSpikingCellsWithType:(NSString *)type
/* This routine cycles through all the cells in the network and counts
 * all currently firing cells for the given type.
 * If the type is nil then it counts all firing cells.
 */
{
        int		i,j,l;
        int		count = 0;

        for(l=0;l<numLayers;l++){
        int numRows = [self numRowsInLayer:l];
        int numColumns = [self numColumnsInLayer:l];
                for(i=0;i<numRows;i++){
                        for(j=0;j<numColumns;j++){
                                /* If the cell is firing and it's type is the type given
                                 * above then add to the count.  If the type given above
                                 * is nil then count all spiking cells.
                                 */
                if([layers[l][i][j].type isCellSpiking:&layers[l][i][j]]
                                        && ([[layers[l][i][j].type name] isEqual:type]) ||
                                        (!type)){
                                        count++;
                                }
                        }
                }
        }
        return count;
}

- (int) countOfSpikingCellsInLayer: (int) l
/* This routine cycles through all the cells in the layer and counts
 * all currently firing cells for the given type.
 * If the type is nil then it counts all firing cells.
 */
{
	int i, j;
        int count = 0;
	int numRows = layerInfo[l].numRows;
	int numColumns = layerInfo[l].numColumns;

        for (i=0; i<numRows; i++) {
            for (j=0; j<numColumns; j++) {
                if ([layers[l][i][j].type isCellSpiking:&layers[l][i][j]])count++;
            }
        }
        return count;
}

- (int) countOfInteractingCellsInLayer: (int) l
/* This routine cycles through all the cells in the layer and counts
 * all currently interacting cells.
 */
{
	int i, j;
        int count = 0;
	int numRows = layerInfo[l].numRows;
	int numColumns = layerInfo[l].numColumns;

        for (i=0; i<numRows; i++) {
            for (j=0; j<numColumns; j++) {
                if ([layers[l][i][j].type shouldCellUpdateConnections:&layers[l][i][j]])count++;
            }
        }
        return count;
}

- (int) countOfSpikingCellsInLayer: (int) l withType:(NSString *)type
/* This routine cycles through all the cells in the layer and counts
 * all currently firing cells for the given type.
 * If the type is nil then it counts all firing cells.
 */
{
        int		i, j;
        int		count = 0;
    int numRows = [self numRowsInLayer:l];
    int numColumns = [self numColumnsInLayer:l];

        for (i=0; i<numRows; i++) {
                for (j=0; j<numColumns; j++) {
                        /* If the cell is firing and its type is the type given
                                * above then add to the count.  If the type given above
                                * is nil then count all spiking cells.
                                */
            if ([layers[l][i][j].type isCellSpiking:&layers[l][i][j]]
                                && [[layers[l][i][j].type name] isEqual:type] ||
                                (!type)){
                                count++;
                        }
                }
        }
        return count;
}

- (int) countOfSpikingCellsInRegionOfLayer: (int) l
        xOffset:(int)xoff yOffset:(int)yoff
        xWidth:(int)numColumns yWidth:(int)numRows
        withType:(NSString *)type
/*"
    This routine cycles through all the cells in the layer and region and counts
    all currently firing cells for the given type.
    If the type is nil then it counts all firing cells.
"*/
{
        int		i, j;
        int		count = 0;

        for (i=0; i<numRows; i++) {
                for (j=0; j<numColumns; j++) {
            /* If the cell is firing and its type is the type given
            * above then add to the count.  If the type given above
            * is nil then count all spiking cells.
            */
            if ([layers[l][i][j].type isCellSpiking:&layers[l][i][j]]
                                && [[layers[l][i][j].type name] isEqual:type] ||
                                (!type)){
                                count++;
                        }
                }
        }
        return count;
}

- (NSString *)countOfSpikingCellsInLayer:(int)z
        withType:(NSString *)type numPartitions:(int)n
/*"
    Divides the layer z into n partitions and counts the number of spiking cells for a given type.
"*/
{
        int	x,y,count;
        int h = layerInfo[z].numRows/n;
        int w = layerInfo[z].numColumns/n;
        NSMutableString *output = [NSMutableString string];

        if(layerInfo[z].node != localNode)return nil;

        for(y = 0; y <= layerInfo[z].numRows;y += h){
                for(x = 0; x <= layerInfo[z].numColumns;x += w){
                        count = [self countOfSpikingCellsInRegionOfLayer: z
                                                xOffset:x yOffset:y
                                                xWidth:w yWidth:h
                                                withType:type];
                        [output appendFormat:@"%d", count];
                }
        }
        [output appendString:@"\n"];
        return output;
}

- (BOOL) isCellSpikingAtPosition: (SIMPosition) pos
/*"
    Returns YES if the cell at position pos is spiking, i.e. is in SIM_SpikingState.
"*/
{
    return ([layers[pos.z][pos.x][pos.y].type isCellSpiking:&layers[pos.z][pos.x][pos.y]]);
}

- (BOOL) isCellFiringAtPosition: (SIMPosition) pos
/*"
    Returns YES if the cell at position pos is firing, i.e. is in SIM_FiringState.
"*/
{
    return ([layers[pos.z][pos.x][pos.y].type isCellFiring:&layers[pos.z][pos.x][pos.y]]);
}

- (BOOL) isCellSpikingAtX: (int) x Y: (int) y Z: (int) z
/*"
    Returns YES if the cell at position (x,y,z) is firing, i.e. is in SIM_SpikingState.
"*/
{
    return ([layers[z][x][y].type isCellSpiking:&layers[z][x][y]]);
}

- (BOOL) isCellFiringAtX: (int) x Y: (int) y Z: (int) z
/*"
    Returns YES if the cell at position (x,y,z) is firing, i.e. is in SIM_FiringState.
"*/
{
    return ([layers[z][x][y].type isCellFiring:&layers[z][x][y]]);
}



- (NSString *) recordFromCells: (NSValueArray *) positions
                                event: (int) event  startCode: (int) start
                                lastEventTime: (int *) lastTime
                                sync: (int) sync code: (int) code
/*"
    DEPRECATED.
    This routine cycles through all the cells in the network and builds
    a string which contains an entry for each currently active cell.
"*/
{
    SIMPosition		aCell;
    int			c, currentEventTime, lastEventTime;
    NSMutableString 	*tempString = [[NSMutableString alloc] init];

    lastEventTime = *lastTime;
    currentEventTime = lastEventTime;

    for (c = 0; c < [positions count]; c++){
        [positions getValue:&aCell atIndex:c];
        if ([layers[aCell.z][aCell.y][aCell.x].type isCellSpiking:
            &layers[aCell.z][aCell.y][aCell.x]]) {
                    currentEventTime = [self time]/[self dt];
                // hack...
                    if ([self dt] >= 1)
                    [tempString appendFormat: @"%X,%X,%d ",
                            event, c + start,
                            (currentEventTime - lastEventTime)];
                    else [tempString appendFormat: @"%X,%X,%d\n",
                            event, c + start,
                            (currentEventTime - lastEventTime)];
                    if ([tempString length]>20)
                            {[tempString appendString: @"\n"];}
                }
                lastEventTime = currentEventTime;
        }
        if (((int) ([self time]/[self dt]) % sync) == 0){
            currentEventTime = [self time] / [self dt];
                [tempString appendFormat: @"%d,1,%d\n",
                        code, (currentEventTime - lastEventTime)];
                lastEventTime = currentEventTime;	
        }	
    *lastTime = lastEventTime;
    return [tempString autorelease];
}

- (NSData *) averageMembranePotentialAroundCells:(NSArray *)positions radius:(int)r;
/*"
    Returns an NSData object containing the average membrane potential for a given radius
    r, around each cell at the given positions.  The data object contains [positions count] float
    values.
"*/
{
    int i = 0;
    NSEnumerator *cellEnum;
    float *data;
    NSMutableData *dataObj;
    NSValue *value;

    cellEnum = [positions objectEnumerator];

    dataObj = [[NSMutableData dataWithLength:sizeof(float)*[positions count]] retain];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (float *)[dataObj mutableBytes];

    while(value = [cellEnum nextObject]){
        SIMPosition curPos;
        SIMType *theType;
        [value getValue:&curPos];

        theType = layers[curPos.z][curPos.y][curPos.x].type;

        if(theType == SIM_UndefinedType)
            data[i++] = 0.0;
        else data[i++] = (float)[self averageMembranePotentialAroundCell:&curPos radius:r];
    }
    return [dataObj autorelease];
}

- (float) averageMembranePotentialAroundCell:(SIMPosition *)pos radius:(int)r
/*"
    This routine computes the mean membrane potential for an area of a given radius
    centered on the cell at a specific position.
 "*/
{
    int		i,j,count = 0;
    float	sum = 0;
    BOOL dummy;

    [self checkBoundary:pos connect:&dummy conditions:SIM_PeriodicBoundary info:nil];  //make sure we're measuring a valid cell;

    for (i = -r; i <= r; i++) {
        for (j = -r; j <= r; j++) {
            if(i*i + j*j < r*r || (r == 0)){
                SIMPosition newPos;
                count++;
                newPos.x = pos->x + i;
                newPos.y = pos->y + j;
                [self checkBoundary:&newPos connect:&dummy conditions:SIM_PeriodicBoundary info:nil];  //make the cells are valid;
                sum += layers[pos->z][newPos.y][newPos.x].cell[0][CELL_POTENTIAL_INDEX].state.doubleValue;  //Only takes the first compartment for now.
            }
        }
    }
    return sum/count;
}

- (NSData *) localFieldPotentialForCells:(NSArray *)positions radius:(int)r
/*"
    Returns an NSData object containing the local field potential for a given radius
    r, around each cell at the given positions.  The data object contains [positions count] float
    values.
"*/
{
    int i = 0;
    NSEnumerator *cellEnum;
    float *data;
    NSMutableData *dataObj;
    NSValue *value;

    cellEnum = [positions objectEnumerator];

    dataObj = [[NSMutableData dataWithLength:sizeof(float)*[positions count]] retain];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (float *)[dataObj mutableBytes];

    while(value = [cellEnum nextObject]){
        SIMPosition curPos;
        SIMType *theType;
        [value getValue:&curPos];
        
        theType = layers[curPos.z][curPos.y][curPos.x].type;
        
        if(theType == SIM_UndefinedType)
            data[i++] = 0.0;
        else data[i++] = (float)[self localFieldPotentialForCell:&curPos radius:r];
    }
    return [dataObj autorelease];
}

- (float) localFieldPotentialForCell:(SIMPosition *)pos radius:(int)r
/*"
    This routine computes the mean channel potential for an area of a given radius
    centered on the cell at a specific position.
 "*/
{
    int		i,j,count = 0;
    float	sum = 0.0;
    BOOL dummy;

    [self checkBoundary:pos connect:&dummy conditions:SIM_PeriodicBoundary info:nil];  //make sure we're measuring a valid cell;

    for (i = -r; i <= r; i++) {
        for (j = -r; j <= r; j++) {
            if(i*i + j*j < r*r || (r == 0)){
                SIMPosition newPos;
                SIMCell *cellModel;
                count++;
                newPos.x = pos->x + i;
                newPos.y = pos->y + j;
                [self checkBoundary:&newPos connect:&dummy conditions:SIM_PeriodicBoundary info:nil];  //make sure the cells are valid;
                cellModel = [layers[pos->z][newPos.y][newPos.x].type cellCompartmentAtIndex:0];
                sum += [layers[pos->z][newPos.y][newPos.x].type summedAbsoluteInputChannelCurrents:&layers[pos->z][newPos.y][newPos.x] forCellModel:cellModel];
            }
        }
    }
    return sum/count;
}

- (NSData *) inputChannelCurrent:(NSString *)key forCompartment:(int)index forCells:(NSArray *)positions
/*"
    Returns an NSData object containing the channel current (on channel key) for the compartment (index) in each cell at the given positions.
    The data object contains [positions count] float values.
"*/
{
    int i = 0;
    NSEnumerator *cellEnum;
    float *data;
    NSMutableData *dataObj;
    NSValue *value;

    cellEnum = [positions objectEnumerator];

    dataObj = [[NSMutableData dataWithLength:sizeof(float)*[positions count]] retain];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (float *)[dataObj mutableBytes];

    while(value = [cellEnum nextObject]){
        SIMPosition curPos;
        SIMType *theType;
        [value getValue:&curPos];

        theType = layers[curPos.z][curPos.y][curPos.x].type;

        if(theType == SIM_UndefinedType)
            data[i++] = -32768.0;
        else data[i++] = (float)[self inputChannelCurrent:key forCompartment:index atPosition:&curPos];
    }
    return [dataObj autorelease];
}

- (float) inputChannelCurrent:(NSString *)key forCompartment:(int)index atPosition:(SIMPosition *)pos
{
    BOOL dummy;

    [self checkBoundary:pos connect:&dummy conditions:SIM_PeriodicBoundary info:nil];  //make sure we're measuring a valid cell;

    return [layers[pos->z][pos->y][pos->x].type inputChannelCurrent:&layers[pos->z][pos->y][pos->x] forKey:key compartment:index];
}

- (NSData *) intrinsicChannelCurrent:(NSString *)key forCompartment:(int)index forCells:(NSArray *)positions
/*"
    Returns an NSData object containing the channel current (on channel key) for the compartment (index) in each cell at the given positions.
    The data object contains [positions count] float values.
"*/
{
    int i = 0;
    NSEnumerator *cellEnum;
    float *data;
    NSMutableData *dataObj;
    NSValue *value;

    cellEnum = [positions objectEnumerator];

    dataObj = [[NSMutableData dataWithLength:sizeof(float)*[positions count]] retain];
    if(!dataObj)NSLog(@"Couldn't instantiate the memory buffer!\n");
    data = (float *)[dataObj mutableBytes];

    while(value = [cellEnum nextObject]){
        SIMPosition curPos;
        SIMType *theType;
        [value getValue:&curPos];

        theType = layers[curPos.z][curPos.y][curPos.x].type;

        if(theType == SIM_UndefinedType)
            data[i++] = -32768.0;
        else data[i++] = (float)[self intrinsicChannelCurrent:key forCompartment:index atPosition:&curPos];
    }
    return [dataObj autorelease];
}

- (float) intrinsicChannelCurrent:(NSString *)key forCompartment:(int)index atPosition:(SIMPosition *)pos
{
    BOOL dummy;

    [self checkBoundary:pos connect:&dummy conditions:SIM_PeriodicBoundary info:nil];  //make sure we're measuring a valid cell;

    return [layers[pos->z][pos->y][pos->x].type intrinsicChannelCurrent:&layers[pos->z][pos->y][pos->x] forKey:key compartment:index];
}


- (float)populationActivityForLayer:(int)l
/*"
    Returns the population activity for a given layer l.  Pa = NumFiringCells/NumCellsInLayer.
"*/
{
    if(layerInfo[l].node != localNode)return 0.0;
    return [self _populationActivityInRegionOfLayer:l xOffset:0 yOffset:0 xWidth:layerInfo[l].numColumns yWidth:layerInfo[l].numRows];
}

- (float) _populationActivityInRegionOfLayer: (int) l
    xOffset:(int)xoff yOffset:(int)yoff
    xWidth:(int)numColumns yWidth:(int)numRows
/* This routine cycles through all the cells in the layer and region and sums
 * all currently firing cells for the given type.  It then normalizes by the number
 * of cells in the region.
 */
{
    int		i, j;
    float	sum = 0;

    for (i=0; i<numRows; i++) {
        for (j=0; j<numColumns; j++) {
            sum += ([layers[l][i][j].type isCellFiring:&layers[l][i][j]] ? 1 : 0);
        }
    }
    return sum/(numRows*numColumns)*dt;
}


- (NSArray *)arrayOfRandomCells:(int)num
/*"
    Returns an NSValueArray of num SIMPositions randomly selected across all layers.
"*/
{
        SIMPosition	aCell;
        NSMutableValueArray *positions;
        id		thisLayer,layerKey,layerEnumerator;
        int		c,l,numRows,numColumns;
        PRNGenerator *myGenerator = [[PRNGenerator marsagliaGenerator] retain];
        //[myGenerator setMinimum: 0.0 maximum: 1.0];

        positions = [[NSMutableValueArray alloc]
                                        initWithValues:nil
                                        count:0
                                        withObjCType:@encode(SIMPosition)];

        layerEnumerator = [layerDictionary keyEnumerator];
        while((layerKey = [layerEnumerator nextObject])){
                l = [self indexForLayerWithKey: layerKey];
                thisLayer = [layerDictionary objectForKey:layerKey];
                numRows = [[thisLayer objectForKey:SIMNumRowsKey] intValue];
                numColumns = [[thisLayer objectForKey:SIMNumColumnsKey] intValue];
        for(c =0;c<num;c++){
                aCell.y = [myGenerator nextDouble]*numRows;
                aCell.x = [myGenerator nextDouble]*numColumns;
                aCell.z = l;
                [positions addValue:&aCell];
        }
        }
        [myGenerator release];
        return [positions autorelease];
}

- (NSValueArray *) arrayOfCellsInLayer: (int) zloc
/*"
    Returns an NSValueArray of num SIMPositions randomly selected across all layers.
"*/
{
        SIMPosition	aCell;
        NSMutableValueArray *positions;
        int	i, j;
        positions = [[NSMutableValueArray alloc]
                                        initWithValues: nil
                                        count: 0
                                        withObjCType: @encode(SIMPosition)];

        aCell.z =  zloc;
        for (i = 0; i < layerInfo[zloc].numColumns; i++) {
        for (j = 0; j < layerInfo[zloc].numRows; j++) {
                aCell.y = j;
                aCell.x = i;
                [positions addValue: &aCell];
            }
        }
        return [positions autorelease];
}

- (NSValueArray *) squareArrayOfCellsAtPosition:(SIMPosition *)pos size:(int)size
/*"
    Returns an NSValueArray of num SIMPositions located within a square region centered around pos with the given size.
"*/
{
        SIMPosition aCell;
        NSMutableValueArray *positions;
        BOOL dummy = NO;

        positions = [[NSMutableValueArray alloc]
                                        initWithValues: nil
                                        count: 0
                                        withObjCType: @encode(SIMPosition)];

        aCell.z = pos->z;
        if(size >= 2){
            int i, j, size_2 = floor(size/2);
            for (i = -size_2; i < size_2; i++) {
                for (j = -size_2; j < size_2; j++) {
                    aCell.y = (pos->y + j);
                    aCell.x = (pos->x + i);
                    [self checkBoundary:&aCell connect:&dummy conditions:SIM_PeriodicBoundary info:nil];
                    [positions addValue:&aCell];
                }
            }
        }
        else {
            aCell.y = pos->y; aCell.x = pos->x;
            [self checkBoundary:&aCell connect:&dummy conditions:SIM_PeriodicBoundary info:nil];
            [positions addValue:&aCell];
        }
        return [positions autorelease];
}


- (NSValueArray *) squareArrayOfCellsAtX: (int) xloc Y: (int) yloc Z: (int) zloc
                        size: (int) size layers: (int) nlayers
/*"
    Returns an NSValueArray of num SIMPositions located within a square region centered around (xloc,yloc,zloc) with the given size
    for nlayers.
"*/
{
        SIMPosition	aCell;
        NSMutableValueArray *positions;
        int		i, j, k, numRows, numColumns;

        positions = [[NSMutableValueArray alloc]
                                        initWithValues: nil
                                        count: 0
                                        withObjCType: @encode(SIMPosition)];

        for (k = 0; k < nlayers; k++) {
                aCell.z =  zloc + k;
                for (i = 0; i < size; i++) {
                        for (j = 0; j < size; j++) {
                                numRows = [self numRowsInLayer: k];
                                numColumns = [self numColumnsInLayer: k];
                                if ((i < numColumns) && (j < numRows)) {
                                        aCell.y = (yloc + j) % numRows;
                                        aCell.x = (xloc + i) % numColumns;
                                        [positions addValue: &aCell];
                                }
                        }
                }
        }
        return [positions autorelease];
}

- (NSValueArray *) arrayOfCellsInLayer:(int)k rows:(int)rows columns:(int)cols
/*"
    Returns an NSValueArray of num SIMPositions located within a region at with the given size
    for nlayers.
"*/
{
    SIMPosition aCell;
    NSMutableValueArray *positions;
    int i, j, numRows, numColumns;

    positions = [[NSMutableValueArray alloc]
                    initWithValues: nil
                    count: rows*cols
                    withObjCType: @encode(SIMPosition)];

    aCell.z = k;
    for (i = 0; i < cols; i++) {
        for (j = 0; j < rows; j++) {
            numRows = [self numRowsInLayer: k];
            numColumns = [self numColumnsInLayer: k];
            if ((i < numColumns) && (j < numRows)) {
                aCell.y = j % numRows;
                aCell.x = i % numColumns;
                [positions addValue: &aCell];
            }
        }
    }
    return [positions autorelease];
}

- (NSValueArray *) arrayOfCells:(int)num inLayer:(int)k
/*"
    Returns an NSValueArray of num SIMPositions located within layer k.
"*/
{
    SIMPosition aCell;
    NSMutableValueArray *positions;
    int i, j, numRows, numColumns, count = 0;

    positions = [[NSMutableValueArray alloc]
                    initWithValues: nil
                    count: num
                    withObjCType: @encode(SIMPosition)];

    aCell.z = k;
    numRows = [self numRowsInLayer: k];
    numColumns = [self numColumnsInLayer: k];
    for (i = 0; i < numColumns; i++) {
        for (j = 0; j < numRows; j++) {
            if (count++ < num) {
                aCell.y = j;
                aCell.x = i;
                [positions addValue: &aCell];
            }
        }
    }
    return [positions autorelease];
}


- (NSCountedSet *)histogramOfConnectionsFromType: (NSString *)fromType toType: (NSString *) toType
/*"
    Returns an NSCountedSet containing the number of connections between fromType and toType.
"*/
{
        int	i,j,l;
        NSCountedSet *histogram = [[NSCountedSet alloc] init];	

        for(l=0;l<numLayers;l++){
        int numRows = [self numRowsInLayer:l];
        int numColumns = [self numColumnsInLayer:l];
                for(i=0;i<numRows;i++){
                        for(j=0;j<numColumns;j++){
                                SIMPosition thisCell;
                                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                                thisCell.z = l;
                                thisCell.y = i;
                                thisCell.x = j;
                                if([[self typeForCell:thisCell] isEqual:fromType]){
                                        [histogram addObject:[NSNumber numberWithInt:
                                                [self countOfConnectionsFromCell: thisCell
                                                        toTypes:[NSArray arrayWithObject:toType]]]];
                                }
                                [pool release];
                        }
                }
        }
        return [histogram autorelease];
}

- (NSCountedSet *) histogramOfConnectionsFromLayer: fromLayerKey toLayer: toLayerKey
/*"
    Returns an NSCountedSet containing the number of connections between layers fromLayerKey and toLayerKey.
"*/
{
        int	i, j, numRows, numColumns;
        id	fromLayer;
        int fromLayerIndex, toLayerIndex;
        NSCountedSet *histogram = [[NSCountedSet alloc] init];	

        fromLayer = [layerDictionary objectForKey: fromLayerKey];
        fromLayerIndex = [self indexForLayerWithKey: fromLayerKey];
        toLayerIndex = [self indexForLayerWithKey:  toLayerKey];
        numRows = [[fromLayer objectForKey: SIMNumRowsKey] intValue];
        numColumns = [[fromLayer objectForKey: SIMNumColumnsKey] intValue];

        // loop through each cell in from-layer
        for (i=0; i<numRows; i++) {
                for (j=0; j<numColumns; j++){
                        SIMPosition thisCell;
                        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                        thisCell.z = fromLayerIndex;
                        thisCell.y = i;
                        thisCell.x = j;
                        [histogram addObject:[NSNumber numberWithInt:
                                        [self countOfConnectionsFromCell: thisCell
                                        toLayer: toLayerIndex]]];
                        [pool release];
                }
        }
        return [histogram autorelease];
}

- (NSCountedSet *) histogramOfConnectionsFromCell: (SIMPosition) aCell toLayer: toLayerKey
/*"
    Returns an NSCountedSet containing the number of connections between a cell at position aCell
    and the layer toLayerKey.
"*/
{
        int col = aCell.x;
        int row = aCell.y;
        int l = aCell.z;
        if (layers[l][row][col].type == SIM_UndefinedType)
                return (NSCountedSet *) 0;
        else {
                int count = [layers[l][row][col].connections count];
                SIMConnection *bytes = [layers[l][row][col].connections mutableBytes];
                int toLayerIndex = [self indexForLayerWithKey: toLayerKey];
                NSCountedSet *histogram = [[NSCountedSet alloc] init];	
                int	index;
                        for (index = 0; index < count; index++){
                        SIMConnection *connection = &bytes[index];
                        if ((l+connection->dz) != toLayerIndex)
                                continue;
                        else {
                                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                                SIMPosition position;
                                NSValue *positionValue;
                                position.z = toLayerIndex;
                                position.y = (row+connection->dy);
                                position.x = (col+connection->dx);
                                positionValue = [NSValue value: (void *) &position
                                                                        withObjCType:@encode(SIMPosition)];
                                [histogram addObject: positionValue];
                                [pool release];
                        }
                }
                return [histogram autorelease];
        }
}

- (int) countOfConnectionsFromCell: (SIMPosition) aCell
        toTypes: (NSArray *) toTypes
/*"
    Returns an NSCountedSet containing the number of connections from the cell at position
    aPos and the types listed in the array toTypes.
"*/
{
        int				l;
        int				row,col;
        int				count,index,connectionCount=0;
        SIMConnection	*bytes;
        NSArray			*typesArray;
        NSDictionary	*thisLayer;
        SIMPosition		newCell;

        col = aCell.x;
        row = aCell.y;
        l = aCell.z;

        thisLayer = [layerDictionary objectForKey: [self keyForLayerAtIndex: l]];
        typesArray = [[thisLayer objectForKey:SIMTypesKey] allKeys];

        if (layers[l][row][col].type == SIM_UndefinedType)
                return 0;

        count = [layers[l][row][col].connections count];
        bytes = [layers[l][row][col].connections mutableBytes];

        for (index=0; index<count; index++){
                SIMConnection *connection=&bytes[index];
                NSString *type;
                newCell.z = (l+connection->dz);
                newCell.y = (row+connection->dy);
                newCell.x = (col+connection->dx);
                type = [layers[newCell.z][newCell.y][newCell.x].type name];
                if (([toTypes indexOfObject: type] != NSNotFound)
                        || toTypes == nil)	
                                connectionCount++;
        }
        return connectionCount;
}

- (int) countOfConnectionsFromCell: (SIMPosition) aCell
                toLayer: (int) layer
/*"
    Returns the count of the connections from a cell located at aCell to layer.
"*/
{
        int l;
        int row, col;
        int count, index, connectionCount = 0;
        SIMConnection	*bytes;

        col = aCell.x;
        row = aCell.y;
        l = aCell.z;
        if (layers[l][row][col].type == SIM_UndefinedType)
                return 0;
        count = [layers[l][row][col].connections count];
        bytes = [layers[l][row][col].connections mutableBytes];

        for (index = 0; index < count; index++){
                SIMConnection *connection = &bytes[index];
                if ((l+connection->dz) != layer)
                        continue;
                connectionCount++;
        }
        return connectionCount;
}

#if 0
- (NSCountedSet *)inputsToCell:(SIMPosition *)pos
/*"
    Returns a counted set containing strings in the format Layer.type.channel
 "*/
{
    int		i,j,l;
    int		count = 0;

    for(l=0;l<numLayers;l++){
        for(i = 0;i< layerInfo[l].numRows;i++){
            for(j = 0; j < layerInfo[l].numColumns; j++){
                int count, index;
                SIMConnection *bytes;
                /* We cycle through all the connections and calculate which connections project to
                *  the position of our current cell. */

                count = [layers[l][i][j].connections count];

                bytes = (SIMConnection *)[layers[l][i][j].connections mutableBytes];
                for(index = 0;index < count; index++){
                    SIMPosition	position;
                    SIMConnection *connection=&bytes[index];
                    position.z = (l+connection->dz);
                    position.y = (i+connection->dy);
                    position.x = (j+connection->dx);
                    
                    if(position.z = pos.z && position.y == pos.y && position.x == pos.x){
                        NSString *source = [NSString stringWithFormat:@"%@.%@.%@",layerKey,typeName,channel];
                    }
                        
                        [[layers[l][i][j].type name] isEqual:type];
                }
            }
        }
    }
    return count;
}
#endif

- (void) printConnectionsByLayer
/*"
    DEPRECATED - should be moved to SIMCommandServer
    prints the connections between each layer.
"*/
{
        if ([descriptionDictionary boolForKey: SIMPrintConnectionsFlag]) {
                id	fromLayerEnumerator, toLayerEnumerator, fromLayerKey, toLayerKey;
                fromLayerEnumerator = [layerDictionary keyEnumerator];
                while ((fromLayerKey = [fromLayerEnumerator nextObject])) {
                        toLayerEnumerator = [layerDictionary keyEnumerator];
                        while ((toLayerKey = [toLayerEnumerator nextObject])) {
                                printf ("%s",
                                        [[self listConnectionsFromLayer: fromLayerKey
                                                toLayer: toLayerKey] UTF8String]);
                        }
                }
        }
}

- (NSString *) listConnectionsFromLayer: fromLayerKey toLayer: toLayerKey
/*"
    DEPRECATED - should be moved to SIMCommandServer
    prints the connections between layer fromLayerKey to layer toLayerKey.
"*/
{
        int	i, j, numRows, numColumns;
        id	fromLayer;
        int fromLayerIndex;
        NSMutableString *tempString=[[NSMutableString alloc] init];

        fromLayer = [layerDictionary objectForKey: fromLayerKey];
        fromLayerIndex = [self indexForLayerWithKey: fromLayerKey];
        numRows = [[fromLayer objectForKey: SIMNumRowsKey] intValue];
        numColumns = [[fromLayer objectForKey: SIMNumColumnsKey] intValue];
        [tempString appendFormat: @"\nConnections from layer %@ to layer %@\n ",
                [fromLayerKey description], [toLayerKey description]];

        // loop through each cell in from-layer
        for (i=0; i<numRows; i++) {
                for (j=0; j<numColumns; j++){
                        SIMPosition thisCell;
                        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                        thisCell.z = fromLayerIndex;
                        thisCell.y = i;
                        thisCell.x = j;
                        [tempString appendFormat:@"%@\n", [self listConnectionsFromCell:
                                thisCell toLayer: toLayerKey]];
                        [pool release];
                }
        }
        return [tempString autorelease];
}

- (NSString *) listConnectionsFromCell: (SIMPosition) aCell
                toLayer: layerKey
/*"
    DEPRECATED - should be moved to SIMCommandServer
    prints the connections between aCell and the layer layerKey.
"*/
{
        int				l;
        int				row, col;
        int				count, index;
        SIMConnection	*bytes;
        NSMutableString *tempString=[[NSMutableString alloc] init];
        int layerIndex = [self indexForLayerWithKey: layerKey];

        col = aCell.x;
        row = aCell.y;
        l = aCell.z;
        if (layers[l][row][col].type == SIM_UndefinedType)
                return [tempString autorelease];
        count = [layers[l][row][col].connections count];
        bytes = [layers[l][row][col].connections mutableBytes];
        if (count)
        [tempString appendFormat: @"\n   Connections from cell (%d, %d, %d):\n",
                col, row, l];
        for (index = 0; index < count; index++){
                SIMConnection *connection = &bytes[index];
                if ((l+connection->dz) == layerIndex) {
                [tempString appendFormat: @" (%d, %d, %d)", (col+connection->dx),
                        (row+connection->dy),(l+connection->dz)];
                }
        }
        return [tempString autorelease];
}

- (void)listAllTypes
/*"
    DEPRECATED - should be moved to SIMCommandServer
    Lists all types of cells and to which types they connect.
"*/
{
    id type,layerKey,layerEnumerator,typesEnumerator;

    //NSMutableString *tempString=[[NSMutableString alloc] init];

    layerEnumerator = [layerDictionary keyEnumerator];

    while(layerKey = [layerEnumerator nextObject]){

        typesEnumerator = [[[layerDictionary objectForKey:layerKey] objectForKey:SIMTypesKey] objectEnumerator];

        while(type = [typesEnumerator nextObject]){
            id affEnum,effEnum,key,connections;
            affEnum = [[type objectForKey:SIMAfferentConnectionsKey] keyEnumerator];
            effEnum = [[type objectForKey:SIMEfferentConnectionsKey] keyEnumerator];
            while(key = [affEnum nextObject]){
                connections = [[type objectForKey:SIMAfferentConnectionsKey] objectForKey:key];
                printf("%s.%s -> %s \n",[layerKey UTF8String],[key UTF8String],[[[[connections objectForKey:SIMProjectionInfoKey] objectForKey:SIMProjectionTypesKey] description] UTF8String]);
            }
            while(key = [effEnum nextObject]){
                connections = [[type objectForKey:SIMEfferentConnectionsKey] objectForKey:key];
                printf("%s.%s -> %s \n",[layerKey UTF8String],[key UTF8String],[[[[connections objectForKey:SIMProjectionInfoKey] objectForKey:SIMProjectionTypesKey] description] UTF8String]);
            }
        }
    }
    return; //[tempString autorelease];
}


@end
