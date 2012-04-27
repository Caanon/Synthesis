/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/SIMNetworkTopology.h>
#import <SynthesisCore/SIMNetworkInfo.h>
#import <SynthesisCore/SIMConnections.h>
#import <SynthesisCore/SIMPatternMatch.h>

@implementation SIMNetwork (SIMNetworkTopology)

- (void)addEfferentConnections:(NSDictionary *)effInfo toChannels:(NSArray *)types forCell:(SIMPosition)aCell
/*"
    Adds efferent connections as described in effInfo and type for the cell located at aCell.
"*/
{
	[self addConnections:effInfo toChannels:types forCell:aCell asAfferents:NO];
}

- (void)addAfferentConnections:(NSDictionary *)affInfo toChannels:(NSArray *)types forCell:(SIMPosition)aCell
/*"
    Adds afferent connections as described in affInfo and type for the cell located at aCell.
"*/
{
    [self addConnections:affInfo toChannels:types forCell:aCell asAfferents:YES];
}

- (void) addConnections:(NSDictionary *)connectDict toChannels:(NSArray *)channelTypes forCell:(SIMPosition)aCell asAfferents:(BOOL)affFlag 
/*"
    Adds connections as described in affInfo and type for the cell located at aCell.  The affFlag indicates whether the
    connections should be added as afferents or efferents, thus determining to which elements the generated connections are added.
"*/
{
    int		layer;
    int		count, index, firstLayer, lastLayer;
    NSEnumerator	*typeEnumerator;
    NSArray		*layerArray;
    NSString		*componentString, *typeString, *layerKey, *typeKey;
    NSDictionary	*thisLayer;
    const SIMConnection	*bytes;
    SIMPosition		targetCell;
    SIMConnection 	newConnect;
    NSCountedSet 	*positions = [[NSCountedSet alloc] init];
    BOOL		homogeneous = [connectDict boolForKey:SIMHomogeneousKey];
    NSValueArray	*connections = nil;
    SIMConnections 	*connectionsModel = [connectDict objectForKey:SIMConnectionsModelKey];
    NSDictionary	*info = [connectDict objectForKey:SIMProjectionInfoKey];	
    NSArray 		*types = [info objectForKey:SIMProjectionTypesKey];
    float xScaleFraction = [info floatForKey:SIMProjectionXScaleKey]*.01;
    float yScaleFraction = [info floatForKey:SIMProjectionYScaleKey]*.01;
    float xOffset = [info floatForKey:SIMProjectionXOffsetKey];
    float yOffset = [info floatForKey:SIMProjectionYOffsetKey];
    BOOL allowSelfFlag = [info boolForKey:SIMAllowSelfConnectionsFlag];
    NSString *boundaryConditions = [info objectForKey:SIMProjectionBoundaryConditionsKey];
    NSDictionary *boundaryInfo = [info objectForKey:SIMProjectionBoundaryInfoKey];
    
    if(layers[aCell.z][aCell.y][aCell.x].type == SIM_UndefinedType){
        NSLog(@"Undefined cell type.");
        return;
    }
    
    layerArray = [layerDictionary allKeys];
    thisLayer = [layerDictionary objectForKey:[layerArray objectAtIndex:aCell.z]];

/* We cycle through all the connections and calculate what the
 * position of the cell that our current cell connects to is.  Each
 * connection coordinate is given in terms of an offset from the
 * actual cell so it is easy to just add the offset in each direction
 * to find the position of the connected cell.
 */

    typeEnumerator = [types objectEnumerator];
    while(componentString = [typeEnumerator nextObject]){
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSArray *typeComponents =
            [componentString componentsSeparatedByString:SIM_TypeSeparator];
        if ([typeComponents count]!=2){	// Type descriptions must have two components
            NSLog(@"Error in format of type description: %@",componentString);
            continue; 			// i.e. layer.type
        }
        layerKey = [typeComponents objectAtIndex:0];
        typeKey = [typeComponents objectAtIndex:1];

        if ([layerKey isEqual:SIM_All]){
            firstLayer = 0;
            lastLayer = [layerArray count]-1;
        }
        else {
            firstLayer = [self indexForLayerWithKey:layerKey];
            lastLayer = firstLayer;
        }
//************************************
        if(homogeneous)connections = [connectionsModel connectionsTemplate];
        else connections = [connectionsModel connectionsForPosition:aCell];
                
        if(connections)[connections retain];
        else {NSLog(@"Error generating connections.");return;}

        count = [connections count];
        bytes = [connections bytes];

        for (layer = firstLayer; layer <= lastLayer; layer++){
            float xScale = xScaleFraction *
                layerInfo[layer].numColumns /
                layerInfo[aCell.z].numColumns;
            float yScale = yScaleFraction *
                layerInfo[layer].numRows /
                layerInfo[aCell.z].numRows;
            float deltaX = xOffset+.5*(layerInfo[layer].numColumns -
                xScale*layerInfo[aCell.z].numColumns);
            float deltaY = yOffset + .5*(layerInfo[layer].numRows -
                yScale*layerInfo[aCell.z].numRows);
            for(index = 0;index < count; index++){
                BOOL	connect = NO,typeOk;
                const SIMConnection *connection = &bytes[index];

                targetCell.z = layer;
                targetCell.y = (yScale*aCell.y + deltaY) + connection->dy;
                targetCell.x = (xScale*aCell.x + deltaX) + connection->dx;

                [self checkBoundary:&targetCell connect:&connect conditions:boundaryConditions info:boundaryInfo];

                if (layers[targetCell.z][targetCell.y][targetCell.x].type == SIM_UndefinedType){
                    NSLog(@"Couldn't connect to undefined cell type at %d %d %d.",targetCell.x,targetCell.y,targetCell.z);
                    continue;
                }

                typeString = [layers[targetCell.z][targetCell.y][targetCell.x].type name];

                typeOk = ([typeString isEqual:typeKey]||
                                (types==nil)||
                                [typeKey isEqual:SIM_All]);

            // NSLog(@"%@=%@ TypeOK = %d\n",typeKey,typeString,typeOk);

                if (connect && typeOk) {
                    int i,typesCount = [channelTypes count];
                    int typeIndex,connectCount = 0;

                    if ([descriptionDictionary boolForKey: SIMUniqueConnectionsFlag])
                        connectCount = [self _countConnectionsTo: targetCell
                                inSet: positions addIt: YES];
                    if (!connectCount) {
                    // Calculate the new offsets for a connection
                    // from or to the target cell
                        if(affFlag){                            
                            newConnect.dx = aCell.x - targetCell.x;
                            newConnect.dy = aCell.y - targetCell.y;
                            newConnect.dz = aCell.z - targetCell.z;
                            
                            newConnect.channels = NSZoneMalloc([self zone],(typesCount)*sizeof(short int));
                            newConnect.channelCount = typesCount;
                            for(i=0;i<typesCount;i++){
                                NSString *type = [channelTypes objectAtIndex:i];
                                if((typeIndex = [layers[aCell.z][aCell.y][aCell.x].type indexOfInputChannel:type]) == NSNotFound){
                                    [self postErrorNotificationWithDescription:
                                        [NSString stringWithFormat:@"Connections could not be made to %@.",componentString]];
                                    return;
                                }
                                newConnect.channels[i] = (short int)typeIndex;
                            }
                        }
                        else {
                            newConnect.dx = targetCell.x - aCell.x;
                            newConnect.dy = targetCell.y - aCell.y;
                            newConnect.dz = targetCell.z - aCell.z;
                            
                            newConnect.channels = NSZoneMalloc([self zone],(typesCount)*sizeof(short int));
                            newConnect.channelCount = typesCount;
                            for(i=0;i<typesCount;i++){
                                NSString *type = [channelTypes objectAtIndex:i];
                                //NSLog(@"Adding type: %@",type);
                                if((typeIndex = [layers[targetCell.z][targetCell.y][targetCell.x].type indexOfInputChannel:type]) == NSNotFound){
                                    [self postErrorNotificationWithDescription:
                                        [NSString stringWithFormat:@"Connections could not be made to %@.",componentString]];
                                    return;
                                }
                                newConnect.channels[i] = (short int)typeIndex;
                            }
                        }

                        newConnect.strength = connection->strength;	
#ifdef CONNECTION_LATENCIES
                        newConnect.latency = connection->latency;
#endif
                        // checks to see if we allow neurons to self-connect
                        if (allowSelfFlag || (newConnect.dx || newConnect.dy || newConnect.dz)){
                            //[NSLock lock];
                            if(affFlag)
                            [layers[targetCell.z][targetCell.y][targetCell.x].connections addValue: &newConnect];
                            else
                            [layers[aCell.z][aCell.y][aCell.x].connections addValue: &newConnect];
                            //[NSLock unlock];
                        }
                   }
                }
            }
        }
        [connections release];
        [pool release];
    }
    [positions release];
}


- (NSArray *)efferentsForCell:(SIMPosition)cellValue toTypes:(NSArray *)toTypes
/*"
    Returns an NSValueArray of SIMPositions for the cells of a type listed in toTypes that are efferent to cellValue.
"*/
{
	int			l;
	int			row,col;
	int			count,index;
	SIMConnection		*bytes;
	SIMPosition		newCell;
	NSMutableValueArray	*efferentsArray = [NSMutableValueArray valueArrayWithObjCType:@encode(SIMPosition)];
	col = cellValue.x;
	row = cellValue.y;
	l = cellValue.z;
	
	if(layers[l][row][col].type == SIM_UndefinedType)return nil;

	count = [layers[l][row][col].connections count];
	bytes = [layers[l][row][col].connections mutableBytes];
	for(index=0;index<count;index++){
            SIMConnection *connection=&bytes[index];
            newCell.z = (l+connection->dz);
            newCell.y = (row+connection->dy);
            newCell.x = (col+connection->dx);

            if(layers[newCell.z][newCell.y][newCell.x].type != SIM_UndefinedType || toTypes==nil){	
                [efferentsArray addValue:&newCell];
            }
	}
	return efferentsArray;
}

- (NSArray *)afferentsForCell:(SIMPosition)cellValue fromTypes:(NSArray *)fromTypes
/*"
    Returns an NSValueArray of SIMPositions for the cells of a type listed in toTypes that are afferent to cellValue.
"*/
{
    int		l,row,col;
    int		numRows,numColumns;
    NSDictionary	*thisLayer;
    NSMutableValueArray *afferentsArray = [NSMutableValueArray
            valueArrayWithObjCType:@encode(SIMPosition)];
			
    for(l=0;l<numLayers;l++){
        thisLayer = [layerDictionary objectForKey:
                [self keyForLayerAtIndex:l]];
        numRows = [[thisLayer objectForKey:SIMNumRowsKey] intValue];
        numColumns = [[thisLayer objectForKey:SIMNumColumnsKey] intValue];

        for(row=0;row<numRows;row++){
            for(col=0;col<numColumns;col++){
                int count,index;
                SIMConnection *bytes;
                NSString *typeString = [layers[l][row][col].type name];
                NSString *fullType = [NSString stringWithFormat:@"%@.%@",[self keyForLayerAtIndex:l],typeString];

                if(layers[l][row][col].type == SIM_UndefinedType)continue;

                if(fromTypes && [fromTypes indexOfObject:fullType] == NSNotFound)continue;

/* We cycle through all the connections and calculate what the
* position of the cell that our current cell connects to is.  Each
* connection coordinate is given in terms of an offset from the
* actual cell so it is easy to just add the offset in each direction
* to find the position of the connected cell.
*/

                count = [layers[l][row][col].connections count];
                bytes = [layers[l][row][col].connections mutableBytes];
                for(index=0;index < count;index++){
                    SIMPosition newCell;
                    SIMConnection *connection = &bytes[index];
                    newCell.z = (l+connection->dz);
                    newCell.y = (row+connection->dy);
                    newCell.x = (col+connection->dx);

                    if((cellValue.x == newCell.x && cellValue.y == newCell.y && cellValue.z == newCell.z) ){
                        SIMPosition aPos;
                        aPos.x = col;
                        aPos.y = row;
                        aPos.z = l;
                        [afferentsArray addValue:&aPos];
                    }
                }
            }
        }
    }	
    return afferentsArray;
}

// A types array contains strings designating the type in the form "layer.typename"
- (NSSet *)_getSetOfLayersFromTypesArray:(NSArray *)types
{
	NSMutableSet *layerSet = [NSMutableSet set];
    NSEnumerator *typeEnumerator = [types objectEnumerator];
	NSString *componentString;

    while(componentString = [typeEnumerator nextObject]){
        NSArray *typeComponents =
            [componentString componentsSeparatedByString:SIM_TypeSeparator];
        if ([typeComponents count]!=2){	// Type descriptions must have two components
            continue; // i.e. layer.type
        }
        [layerSet addObject:[typeComponents objectAtIndex:0]]; // first component is layername
	}
	return layerSet;
}

- (NSSet *)_getSetOfTypeNamesFromTypesArray:(NSArray *)types
{
    NSMutableSet *typeSet = [NSMutableSet set];
    NSEnumerator *typeEnumerator = [types objectEnumerator];
    NSString *componentString;

    while(componentString = [typeEnumerator nextObject]){
        NSArray *typeComponents =
            [componentString componentsSeparatedByString:SIM_TypeSeparator];
        if ([typeComponents count]!=2){	// Type descriptions must have two components
            continue;					// i.e. layer.type
        }
        [typeSet addObject:[typeComponents objectAtIndex:1]]; //second component is typename
    }
    return typeSet;
}

- (unsigned int) setStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType toValue:(float)val
/*"
    Sets the strength of all the connections between elements of type fromType to elements of toType to the value val.
"*/
{
    NSArray *fromTypes = [NSArray arrayWithObject:fromType];
    NSArray *toTypes = [NSArray arrayWithObject:toType];
    return [self setStrengthOfConnectionsFromTypes:fromTypes toTypes:toTypes toValue:val];
}

- (unsigned int) thresholdStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType atValue:(float)delta
/*"
    Adds val to the strength of all the connections between elements of type fromType to elements of toType.
"*/
{
   NSArray *fromTypes = [NSArray arrayWithObject:fromType];
   NSArray *toTypes = [NSArray arrayWithObject:toType];
   return [self thresholdStrengthOfConnectionsFromTypes:fromTypes toTypes:toTypes atValue:delta];
}

- (unsigned int) modifyStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType byValue:(float)delta
/*"
    Adds val to the strength of all the connections between elements of type fromType to elements of toType.
"*/
{
   NSArray *fromTypes = [NSArray arrayWithObject:fromType];
   NSArray *toTypes = [NSArray arrayWithObject:toType];
   return [self modifyStrengthOfConnectionsFromTypes:fromTypes toTypes:toTypes byValue:delta];
}

- (unsigned int) scaleStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType byValue:(float)delta
/*"
    Scales (by multiplication) the strength of all the connections between elements of type fromType to elements of toType by the value val.
"*/
{
   NSArray *fromTypes = [NSArray arrayWithObject:fromType];
   NSArray *toTypes = [NSArray arrayWithObject:toType];
   return [self scaleStrengthOfConnectionsFromTypes:fromTypes toTypes:toTypes byValue:delta];
}

- (unsigned int) setStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType fractionOfCells:(float)frac1
	toValue:(float)val fractionOfConnections:(float)frac2
/*"
    Sets the strength of all the connections between elements of type fromType to elements of toType to the value val.
"*/
{
    NSArray *fromTypes = [NSArray arrayWithObject:fromType];
    NSArray *toTypes = [NSArray arrayWithObject:toType];
    return [self setStrengthOfConnectionsFromTypes:fromTypes toTypes:toTypes fractionOfCells:frac1 toValue:val fractionOfConnections:frac2];
}

- (unsigned int) thresholdStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType fractionOfCells:(float)frac1 
	atValue:(float)delta fractionOfConnections:(float)frac2
/*"
    Adds val to the strength of all the connections between elements of type fromType to elements of toType.
"*/
{
   NSArray *fromTypes = [NSArray arrayWithObject:fromType];
   NSArray *toTypes = [NSArray arrayWithObject:toType];
   return [self thresholdStrengthOfConnectionsFromTypes:fromTypes toTypes:toTypes fractionOfCells:frac1 atValue:delta fractionOfConnections:frac2];
}

- (unsigned int) modifyStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType fractionOfCells:(float)frac1 
	byValue:(float)delta fractionOfConnections:(float)frac2
/*"
    Adds val to the strength of all the connections between elements of type fromType to elements of toType.
"*/
{
   NSArray *fromTypes = [NSArray arrayWithObject:fromType];
   NSArray *toTypes = [NSArray arrayWithObject:toType];
   return [self modifyStrengthOfConnectionsFromTypes:fromTypes toTypes:toTypes fractionOfCells:frac1 byValue:delta fractionOfConnections:frac2];
}

- (unsigned int) scaleStrengthOfConnectionsFromType:(NSString *)fromType toType:(NSString *)toType fractionOfCells:(float)frac1 
	byValue:(float)delta fractionOfConnections:(float)frac2
/*"
    Scales (by multiplication) the strength of all the connections between elements of type fromType to elements of toType by the value val.
"*/
{
   NSArray *fromTypes = [NSArray arrayWithObject:fromType];
   NSArray *toTypes = [NSArray arrayWithObject:toType];
   return [self scaleStrengthOfConnectionsFromTypes:fromTypes toTypes:toTypes fractionOfCells:frac1 byValue:delta fractionOfConnections:frac2];
}

- (unsigned int) _useWildcardToChangeConnectionStrengthFromTypes:(NSString *)fromPattern toTypes:(NSString *)toPattern fractionOfCells:(float)fractCells
    operation:(SIMChangeConnectionOperation)op value:(float)val fractionOfConnections:(float)fractConnect
{
	PRNGenerator *randomGenerator = [[PRNGenerator marsagliaGenerator] retain];
	
	[randomGenerator setSeed:[descriptionDictionary intForKey:SIMMasterRandomSeedKey]];

    int total = 0;

/* We cycle through all the connections and calculate what the
 * position of the cell that our current cell connects to is.  Each
 * connection coordinate is given in terms of an offset from the
 * actual cell so it is easy to just add the offset in each direction
 * to find the position of the connected cell.
 */

        int layer,i,j;

        for (layer = 0; layer < numLayers; layer++){
            int numRows = [self numRowsInLayer:layer];
            int numColumns = [self numColumnsInLayer:layer];
            for(i=0;i<numRows;i++){
                for(j=0;j<numColumns;j++){
                    int count,index;
                    SIMConnection *bytes;
                    NSString *fromType = [NSString stringWithFormat:@"%@%@%@",layerInfo[layer].name,SIM_TypeSeparator,[layers[layer][i][j].type name]];

                    if((layers[layer][i][j].type == SIM_UndefinedType) || (SIMPatternMatch(fromPattern,fromType,NULL)))continue;

    /* We cycle through all the connections and calculate what the
     * position of the cell that our current cell connects to is.  Each
     * connection coordinate is given in terms of an offset from the
     * actual cell so it is easy to just add the offset in each direction
     * to find the position of the connected cell.
     */
                    count = [layers[layer][i][j].connections count];
                    bytes = [layers[layer][i][j].connections mutableBytes];
					for(index = 0;index < count; index++){
						NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
						NSString		*toType;
						BOOL			typeOk = NO;
						SIMPosition		newCell;
						SIMConnection	*connection = &bytes[index];
						newCell.z = (layer + connection->dz);
						newCell.y = (i + connection->dy);
						newCell.x = (j + connection->dx);

									
						for(index = 0; index < connection->channelCount; index++){
							toType = [NSString stringWithFormat:@"%@%@%@%@%@",layerInfo[newCell.z].name,SIM_TypeSeparator,[layers[newCell.z][newCell.y][newCell.x].type name],
									SIM_TypeSeparator,[[layers[newCell.z][newCell.y][newCell.x].type inputChannelAtIndex:index] modelName]];

							if(!SIMPatternMatch(toPattern,toType,NULL)){
								if([randomGenerator nextDouble] <= fractCells){
									typeOk = YES;
								}
							}
						}
						

						if (typeOk && ([randomGenerator nextDouble] <= fractConnect)) {
							switch(op){
								case SIMSetToValue:
									connection->strength = val; // Change the connection strength
									total++;
									break;
								case SIMScaleByValue:
									connection->strength *= val;
									total++;
									break;
								case SIMAddValue:
									connection->strength += val;
									total++;
									break;
								default:
									break;
							}
					   }
					   [pool release];
					}
				}
            }
        }
    
    return total;
}

- (unsigned int) _changeConnectionStrengthFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes fractionOfCells:(float)fractCells
    operation:(SIMChangeConnectionOperation)op value:(float)val fractionOfConnections:(float)fractConnect
{
    NSEnumerator *layerEnumerator;
    NSSet *fromLayerSet,*toLayerSet,*fromTypeSet,*toTypeSet;
    NSString *layerKey;
	PRNGenerator *randomGenerator = [[PRNGenerator marsagliaGenerator] retain];
	
	[randomGenerator setSeed:[descriptionDictionary intForKey:SIMMasterRandomSeedKey]];

    int total = 0;

/* We cycle through all the connections and calculate what the
 * position of the cell that our current cell connects to is.  Each
 * connection coordinate is given in terms of an offset from the
 * actual cell so it is easy to just add the offset in each direction
 * to find the position of the connected cell.
 */

    fromLayerSet = [self _getSetOfLayersFromTypesArray:fromTypes];
    fromTypeSet = [self _getSetOfTypeNamesFromTypesArray:fromTypes];

    toLayerSet = [self _getSetOfLayersFromTypesArray:toTypes];
    toTypeSet = [self _getSetOfTypeNamesFromTypesArray:toTypes];

    layerEnumerator = [fromLayerSet objectEnumerator];

    while(layerKey = [layerEnumerator nextObject]){
        int layer,i,j,firstLayer,lastLayer;

        if ([layerKey isEqual:SIM_All]){
            firstLayer = 0;
            lastLayer = [self countLayers]-1;
        }
        else {
            firstLayer = [self indexForLayerWithKey:layerKey];
            lastLayer = firstLayer;
        }

        for (layer = firstLayer; layer <= lastLayer; layer++){
            int numRows = [self numRowsInLayer:layer];
            int numColumns = [self numColumnsInLayer:layer];
            for(i=0;i<numRows;i++){
                for(j=0;j<numColumns;j++){
                    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                    int count,index;
                    SIMConnection *bytes;
                    NSString *fromType = [layers[layer][i][j].type name];

                    if((layers[layer][i][j].type == SIM_UndefinedType)||
                        (![fromTypeSet containsObject:fromType] &&
                        ![fromTypeSet containsObject:SIM_All]))continue;

    /* We cycle through all the connections and calculate what the
     * position of the cell that our current cell connects to is.  Each
     * connection coordinate is given in terms of an offset from the
     * actual cell so it is easy to just add the offset in each direction
     * to find the position of the connected cell.
     */
				if([randomGenerator nextDouble] <= fractCells){
                    count = [layers[layer][i][j].connections count];
                    bytes = [layers[layer][i][j].connections mutableBytes];
						for(index = 0;index < count; index++){
							NSString		*toType;
							BOOL			typeOk;
							SIMPosition		newCell;
							SIMConnection	*connection = &bytes[index];
							newCell.z = (layer + connection->dz);
							newCell.y = (i + connection->dy);
							newCell.x = (j + connection->dx);

							toType = [layers[newCell.z][newCell.y][newCell.x].type name];
							
							//NSLog(toType);

							// If both the layer and typename are in the toTypes array then typeOk=YES
							typeOk = ([toLayerSet containsObject:SIM_All] ||
								[toLayerSet containsObject:[self keyForLayerAtIndex:newCell.z]]) &&
								([toTypeSet containsObject:SIM_All] ||
								[toTypeSet containsObject:toType]);

							if (typeOk && ([randomGenerator nextDouble] <= fractConnect)) {
								switch(op){
									case SIMSetToValue:
										connection->strength = val; // Change the connection strength
										total++;
										break;
									case SIMScaleByValue:
										connection->strength *= val;
										total++;
										break;
									case SIMAddValue:
										connection->strength += val;
										total++;
										break;
									case SIMThresholdValue:
										if(connection->strength < val){
											connection->strength = 0.0;
											total++;
										}
										break;
									default:
										break;
								}
						   }
						}
					
					}
                    [pool release];
                }
            }
        }
    }
    return total;
}


- (unsigned int) thresholdStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes atValue:(float)delta
{
    return [self _changeConnectionStrengthFromTypes:fromTypes toTypes:toTypes fractionOfCells:1.0 operation:SIMThresholdValue value:delta fractionOfConnections:1.0];
}

- (unsigned int) modifyStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes byValue:(float)delta
{
    return [self _changeConnectionStrengthFromTypes:fromTypes toTypes:toTypes fractionOfCells:1.0 operation:SIMAddValue value:delta fractionOfConnections:1.0];
}

- (unsigned int) scaleStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes byValue:(float)scale
{
    return [self _changeConnectionStrengthFromTypes:fromTypes toTypes:toTypes fractionOfCells:1.0 operation:SIMScaleByValue value:scale fractionOfConnections:1.0];
}

- (unsigned int) setStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes toValue:(float)val
{
    return [self _changeConnectionStrengthFromTypes:fromTypes toTypes:toTypes fractionOfCells:1.0 operation:SIMSetToValue value:val fractionOfConnections:1.0];
}

- (unsigned int) thresholdStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes fractionOfCells:(float)frac1 atValue:(float)delta fractionOfConnections:(float)frac2
{
    return [self _changeConnectionStrengthFromTypes:fromTypes toTypes:toTypes fractionOfCells:frac1 operation:SIMThresholdValue value:delta fractionOfConnections:frac2];
}

- (unsigned int) modifyStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes fractionOfCells:(float)frac1 byValue:(float)delta fractionOfConnections:(float)frac2
{
    return [self _changeConnectionStrengthFromTypes:fromTypes toTypes:toTypes fractionOfCells:frac1 operation:SIMAddValue value:delta fractionOfConnections:frac2];
}

- (unsigned int) scaleStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes fractionOfCells:(float)frac1 byValue:(float)scale fractionOfConnections:(float)frac2
{
    return [self _changeConnectionStrengthFromTypes:fromTypes toTypes:toTypes fractionOfCells:frac1 operation:SIMScaleByValue value:scale fractionOfConnections:frac2];
}

- (unsigned int) setStrengthOfConnectionsFromTypes:(NSArray *)fromTypes toTypes:(NSArray *)toTypes fractionOfCells:(float)frac1 toValue:(float)val fractionOfConnections:(float)frac2
{
    return [self _changeConnectionStrengthFromTypes:fromTypes toTypes:toTypes fractionOfCells:frac1 operation:SIMSetToValue value:val fractionOfConnections:frac2];
}

- (void) checkBoundary:(SIMPosition *)aPosition connect:(BOOL *)connect conditions:(NSString *)boundaryConditions
    info:(NSDictionary *)boundaryInfo
/*"
    Verifies that aPosition is valid for the current network using the
    boundaryConditions.  The boolean connect is set to YES if the connection
    should be made (i.e. the position is on the layer) or NO if it should not.
    The only condition that can set connect = NO is SIM_ExtinctiveBoundary.
"*/
{
	int	numColumns=0,numRows=0;
	
	/* Wrap around layer connections */
	if (aPosition->z >= numLayers)
		aPosition->z = 0;
	if (aPosition->z < 0)
		aPosition->z = numLayers-1;
	
	numRows = layerInfo[aPosition->z].numRows;
	numColumns = layerInfo[aPosition->z].numColumns;
        
	*connect = YES;
        
	if ([boundaryConditions isEqual:SIM_CustomBoundary]){
		[self applyCustomBoundaryCondition:aPosition connect:connect info:boundaryInfo];
	}
	else if ([boundaryConditions isEqual:SIM_TiledBoundary]){
		[self applyTiledBoundaryCondition:aPosition connect:connect info:boundaryInfo];
	}
    else if ([boundaryConditions isEqual:SIM_PeriodicBoundary]) {
		[self applyPeriodicBoundaryCondition:aPosition connect:connect];
	}							
	else if ([boundaryConditions isEqual:SIM_NullFluxBoundary]){
		[self applyNullFluxBoundaryCondition:aPosition connect:connect];
	}

	[self applyClippedBoundaryCondition:aPosition connect:connect]; // Clip anything that still is projecting nowhere.

}

- (void) applyCustomBoundaryCondition:(SIMPosition *)aPosition connect:(BOOL *)connect info:(NSDictionary *)boundaryInfo
{
	NSString *upperLayer = [boundaryInfo objectForKey:SIM_TiledUpperEdgeKey];
	NSString *lowerLayer = [boundaryInfo objectForKey:SIM_TiledLowerEdgeKey];
	NSString *rightLayer = [boundaryInfo objectForKey:SIM_TiledRightEdgeKey];
	NSString *leftLayer = [boundaryInfo objectForKey:SIM_TiledLeftEdgeKey];
	int numRows = layerInfo[aPosition->z].numRows;
	int numColumns = layerInfo[aPosition->z].numColumns;

	if (aPosition->y < 0){ 
		[self checkBoundary:aPosition connect:connect conditions:upperLayer info:boundaryInfo];
	}
	if (aPosition->y >= numRows){
		[self checkBoundary:aPosition connect:connect conditions:lowerLayer info:boundaryInfo];
	}
	if (aPosition->x < 0){
		[self checkBoundary:aPosition connect:connect conditions:leftLayer info:boundaryInfo];
	}
	if (aPosition->x >= numColumns){ 
		[self checkBoundary:aPosition connect:connect conditions:rightLayer info:boundaryInfo];
	}

}


- (void) applyTiledBoundaryCondition:(SIMPosition *)aPosition connect:(BOOL *)connect info:(NSDictionary *)boundaryInfo
{
	int numRows = layerInfo[aPosition->z].numRows;
	int numColumns = layerInfo[aPosition->z].numColumns;

	NSString *upperLayer = [boundaryInfo objectForKey:SIM_TiledUpperEdgeKey];
	NSString *lowerLayer = [boundaryInfo objectForKey:SIM_TiledLowerEdgeKey];
	NSString *rightLayer = [boundaryInfo objectForKey:SIM_TiledRightEdgeKey];
	NSString *leftLayer = [boundaryInfo objectForKey:SIM_TiledLeftEdgeKey];

	int upperIndex = [self indexForLayerWithKey:upperLayer];
	int lowerIndex = [self indexForLayerWithKey:lowerLayer];
	int rightIndex = [self indexForLayerWithKey:rightLayer];
	int leftIndex = [self indexForLayerWithKey:leftLayer];
                                
	if (aPosition->y < 0){ 
		aPosition->z = upperIndex;
		aPosition->y = layerInfo[aPosition->z].numRows+aPosition->y;
	}
	if (aPosition->y >= numRows){
		aPosition->z = lowerIndex;
		aPosition->y = (aPosition->y-layerInfo[aPosition->z].numRows);
	}
	if (aPosition->x < 0){
		aPosition->z = leftIndex;
		aPosition->x = layerInfo[aPosition->z].numColumns+aPosition->x;
	}
	if (aPosition->x >= numColumns){ 
		aPosition->z = rightIndex;
		aPosition->x = (aPosition->x - layerInfo[aPosition->z].numColumns);
	}
}

- (void) applyPeriodicBoundaryCondition:(SIMPosition *)aPosition connect:(BOOL *)connect
{
	int numRows = layerInfo[aPosition->z].numRows;
	int numColumns = layerInfo[aPosition->z].numColumns;

	if (aPosition->y<0) 
		aPosition->y = numRows+aPosition->y;
	if (aPosition->y>=numRows) 
		aPosition->y = (aPosition->y-numRows);
	if (aPosition->x<0) 
		aPosition->x = numColumns+aPosition->x;
	if (aPosition->x>=numColumns) 
		aPosition->x = (aPosition->x-numColumns);	
}

- (void) applyClippedBoundaryCondition:(SIMPosition *)aPosition connect:(BOOL *)connect
{
	int numRows = layerInfo[aPosition->z].numRows;
	int numColumns = layerInfo[aPosition->z].numColumns;

	/* Clip any connections that still fall outside the network */
	if (aPosition->y<0)
		{*connect = NO;aPosition->y=0;}
	if (aPosition->y>=numRows)
		{*connect = NO;aPosition->y=numRows-1;}
	if (aPosition->x<0)
		{*connect = NO;aPosition->x=0;}
	if (aPosition->x>=numColumns)
		{*connect=NO;aPosition->x=numColumns-1;}
}

- (void) applyNullFluxBoundaryCondition:(SIMPosition *)aPosition connect:(BOOL *)connect
{
	int numRows = layerInfo[aPosition->z].numRows;
	int numColumns = layerInfo[aPosition->z].numColumns;

	if (aPosition->y<0)
		aPosition->y= -aPosition->y;
	if (aPosition->y>=numRows) 
		aPosition->y = (numRows-1)-(aPosition->y-numRows);
	if (aPosition->x<0)
		aPosition->x = -aPosition->x;
	if (aPosition->x>=numColumns)
		aPosition->x = (numColumns-1) -(aPosition->x-numColumns);			
}

- (int) _countConnectionsTo: (SIMPosition) xyz
        inSet: (NSCountedSet *) setOfPositions
        addIt: (BOOL) flag
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSValue *value = [NSValue value: &xyz
                    withObjCType: @encode(SIMPosition)];
    int count = [setOfPositions countForObject: value];
    // add the position if it's not in the set, if flag is set
    if (flag && !count)
        [setOfPositions addObject: value];
    [pool release];
    return count;
}


- (NSData *)typeDataForLayer:(int)layer
/*"
"*/
{
	int		i,j,l=layer;
	float	*data;
	NSMutableData *dataObj;
        int numRows = layerInfo[l].numRows;
        int numColumns = layerInfo[l].numColumns;
		
	dataObj = [NSMutableData dataWithLength:sizeof(float)*numColumns*numRows];
	data = [dataObj mutableBytes];
	
	for(i=0;i<numRows;i++){
		for(j=0;j<numColumns;j++){
			data[i*numColumns+j] = [layers[l][i][j].type assignedIndex];
			if(data[i*numColumns+j]==NSNotFound)data[i*numColumns+j]=(-1);
		}
	}
	
	return dataObj;
}

- (NSDictionary *)getType:(NSString *)typeString
/*"
	A convenience method for requesting a type using just one string.
	However because this string can indicate more than one type (using the "All" 
	key) it may return more than one type in the dictionary.  See -getTypes:.
"*/
{
    return [self getTypes:[NSArray arrayWithObject:typeString]];
}

- (NSDictionary *)getTypes:(NSArray *)types
/*"
	Returns a dictionary containing all the types given as an array of strings.
	Each string in types should be in the format "layername.typename" where
	layername = "All" indicates to select all layers and typename = "All" indicates
	that all types should be returned for the selected layer(s).
"*/
{
    NSString *layerKey, *typeKey;
    NSEnumerator	*typeEnumerator,*layerKeyEnumerator;
    NSMutableDictionary *dict = [[NSMutableDictionary dictionary] retain];
    NSString *componentString,*thisLayerKey;	

    typeEnumerator = [types objectEnumerator];
    while(componentString = [typeEnumerator nextObject]){
        NSArray *typeComponents =
            [componentString componentsSeparatedByString:SIM_TypeSeparator];
        if ([typeComponents count]!=2){
            // Type descriptions must have two components
            // i.e. layer.type
            NSLog(@"Invalid type descriptor: %@",componentString);
            continue;
        }
        layerKey = [typeComponents objectAtIndex:0];
        typeKey = [typeComponents objectAtIndex:1];

        layerKeyEnumerator = [layerDictionary keyEnumerator];
        while (thisLayerKey = [layerKeyEnumerator nextObject]) {
            if([layerKey isEqual:thisLayerKey] || [layerKey isEqual:SIM_All]){
				NSDictionary *thisLayer,*typeDictionary;
				NSEnumerator *typeKeyEnumerator;
				NSString *thisTypeKey;
                thisLayer = [layerDictionary objectForKey: thisLayerKey];
                typeDictionary = [thisLayer objectForKey: SIMTypesKey];
                typeKeyEnumerator = [typeDictionary keyEnumerator];
                while((thisTypeKey = [typeKeyEnumerator nextObject])){
                    if([typeKey isEqual:thisTypeKey] || [typeKey isEqual:SIM_All]){
                        NSDictionary *thisType = [typeDictionary objectForKey:thisTypeKey];
						NSString *key = [NSString stringWithFormat:@"%@%@%@",
							thisLayerKey,SIM_TypeSeparator,thisTypeKey];
                        if(thisType)[dict setObject:thisType forKey:key];
                    }
                }
            }
        }
    }
    return [dict autorelease];
}

- (void)setConnections:(NSValueArray *)connections forCell:(SIMPosition)aCell
{
    BOOL safetyCheck = ((aCell.z < numLayers) && (aCell.y < layerInfo[aCell.z].numColumns) && (aCell.x < layerInfo[aCell.z].numRows));
    if(layerInfo[aCell.z].node != localNode) return;
    if(safetyCheck){
        if(layers[aCell.z][aCell.y][aCell.x].connections){
            //[[undoManager prepareWithInvocationTarget:self]
            //    setConnections: layers[aCell.z][aCell.y][aCell.x].connections toConnection:aCell];
            //[undoManager setActionName:@"connections change"];
            [layers[aCell.z][aCell.y][aCell.x].connections autorelease];
        }
        layers[aCell.z][aCell.y][aCell.x].connections = [connections retain];
    }
}

- (NSValueArray *)connectionsForCell:(SIMPosition)aCell
{
    BOOL safetyCheck = ((aCell.z < numLayers) && (aCell.y < layerInfo[aCell.z].numColumns) && (aCell.x < layerInfo[aCell.z].numRows));
    if(layerInfo[aCell.z].node != localNode) return nil;
    if(safetyCheck && layers[aCell.z][aCell.y][aCell.x].connections)return (NSValueArray *)layers[aCell.z][aCell.y][aCell.x].connections;
    else return nil;
}

- (NSString *)typeForCell:(SIMPosition)aCell
{
    if(layerInfo[aCell.z].node != localNode) return SIM_UndefinedTypeObject;
    if(layers[aCell.z][aCell.y][aCell.x].type == SIM_UndefinedType)return SIM_UndefinedTypeObject;
    return [layers[aCell.z][aCell.y][aCell.x].type name];
}

- (NSArray *)typesForLayer:(int)layer
{
	return [[self typesDictionaryForLayer:layer] allKeys];
}

- (NSArray *)typesForLayerWithKey:(NSString *)key
{
    if([key isEqual:SIM_All]){
        NSMutableArray *types = [NSMutableArray array];
		NSString *aKey;
        NSArray *layerKeys = [self layerKeys];
		NSEnumerator *enumerator = [layerKeys objectEnumerator];
		while(aKey = [enumerator nextObject]){
            [types addObjectsFromArray:[[self typesDictionaryForLayerWithKey:aKey] allKeys]];
        }
		return types;
    }
    else return [[self typesDictionaryForLayerWithKey:key] allKeys];
}

- (int)indexOfType:(NSString *)typeKey inLayerWithKey:(NSString *)layerKey
{
    return [[self typesForLayerWithKey:layerKey] indexOfObject:typeKey];
}

- (NSArray *)layerKeys
{
	return [layerDictionary allKeys];
}

- (NSData *)connectionMatrixFromLayer:(NSString *)fromLayer andType:(NSString *)fromType toLayer:(NSString *)toLayer andType:(NSString *)toType channel:(NSString *)channel
{
	int channelIndex,fromIndex,toIndex,toTypeIndex,numFromCells,numToCells,numFromRows,numFromColumns,numToRows,numToColumns;
	int row,col;
			
	fromIndex = [self indexForLayerWithKey:fromLayer];
	toIndex = [self indexForLayerWithKey:toLayer];
	
	numFromCells = layerInfo[fromIndex].numRows*layerInfo[fromIndex].numColumns;
	numToCells = layerInfo[toIndex].numRows*layerInfo[toIndex].numColumns;
	
	NSMutableData *connectionMatrix = [[NSMutableData dataWithLength:sizeof(float)*numFromCells*numToCells] retain];
	float *matrix = [connectionMatrix mutableBytes];
	
    int l = fromIndex;
	if(layerInfo[l].node != localNode)return nil; // May not be needed
	
	numFromRows = layerInfo[l].numRows;
	numFromColumns = layerInfo[l].numColumns;
	numToRows = layerInfo[l].numRows;
	numToColumns = layerInfo[l].numColumns;

	toTypeIndex = [self indexForType:toType inLayer:toLayer];
	channelIndex = [self indexForInputChannel:channel inType:toType layer:toLayer];


	for (row = 0; row < numFromRows; row++) {
		for (col = 0; col < numFromColumns; col++){
			SIMConnection *bytes;
			int count, index,matrixIndex;
			if (layers[l][row][col].type == SIM_UndefinedType) continue;
							
			/* We cycle through all the connections and calculate what the
				* position of the cell that our current cell connects to is.  Each
				* connection coordinate is given in terms of an offset from the
				* actual cell so it is easy to just add the offset in each direction
				* to find the position of the connected cell.
				*/
			
			count = [layers[l][row][col].connections count];
			
			bytes = (SIMConnection *)[layers[l][row][col].connections mutableBytes];
			for(index = 0;index < count; index++){
				SIMPosition	position;
				SIMConnection *connection=&bytes[index];
				int k;
				BOOL validChannel = NO;
								
				position.z = (l+connection->dz);
				
				if(position.z != toIndex)continue;
				
				position.y = (row+connection->dy);
				position.x = (col+connection->dx);
											
				if([layers[position.z][position.y][position.x].type assignedIndex] != toTypeIndex)continue; 
														
				for(k = 0; k < connection->channelCount; k++){
					if(connection->channels[k] == channelIndex){
						validChannel = YES;
						break;
					}
				}
																																				
				matrixIndex = (row*numFromColumns+col)*(numFromRows*numFromColumns) + (position.y*numToRows+position.x);
				
				if(validChannel)matrix[matrixIndex]+= connection->strength;
			}
		}
	}
	return [connectionMatrix autorelease];
}

- (NSString *)connectionsTable
{
	NSMutableString *table = [[NSMutableString string] retain];
	int i,j;
	NSString *connectionDescription;
	for(i = 0; i < numLayers; i++){
		for(j = 0; j < layerInfo[i].numTypes; j++){
			NSDictionary *afferentConnections,*efferentConnections;
			NSEnumerator *afferentEnum,*efferentEnum;
			NSString *affKey,*effKey,*from,*to;
			afferentConnections = [layerInfo[i].types[j] afferentConnectionModels];
			afferentEnum = [afferentConnections keyEnumerator];
			while(affKey = [afferentEnum nextObject]){
				NSDictionary *connection = [afferentConnections objectForKey:affKey];
				NSDictionary *projectionInfo = [connection objectForKey:SIMProjectionInfoKey];
				NSEnumerator *targetEnum = [[projectionInfo objectForKey:SIMTypesKey] objectEnumerator];
				while(from = [targetEnum nextObject]){
					SIMConnections *connectModel = [connection objectForKey:SIMConnectionsModelKey];
					if(!connectModel)NSLog(@"No Connections model");
					connectionDescription = [NSString stringWithFormat:@"%@,%@,%@,%@,%f,,%f,%f,%f,%f,%f\n",from,layerInfo[i].name,[connection objectForKey:SIMChannelModelKey],
									NSStringFromClass([connectModel class]),[connectModel floatForKey:@"Height"],[connectModel floatForKey:@"Width"],[connectModel floatForKey:@"Radius"],
									[connectModel floatForKey:@"Strength"],[connectModel floatForKey:@"MeanDelay"],[connectModel floatForKey:@"StdDelay"]];
					[table appendFormat:@"%@",connectionDescription];
				}
			}
			efferentConnections = [layerInfo[i].types[j] efferentConnectionModels];
			efferentEnum = [efferentConnections keyEnumerator];
			while(effKey = [efferentEnum nextObject]){
				NSDictionary *connection = [efferentConnections objectForKey:effKey];
				NSDictionary *projectionInfo = [connection objectForKey:SIMProjectionInfoKey];
				NSEnumerator *targetEnum = [[projectionInfo objectForKey:SIMTypesKey] objectEnumerator];
				while(to = [targetEnum nextObject]){
					SIMConnections *connectModel = [connection objectForKey:SIMConnectionsModelKey];
					if(!connectModel)NSLog(@"No Connections model");
					connectionDescription = [NSString stringWithFormat:@"%@,%@,%@,%@,%f,,%f,%f,%f,%f,%f\n",layerInfo[i].name,to,[connection objectForKey:SIMChannelModelKey],
									NSStringFromClass([connectModel class]),[connectModel floatForKey:@"Height"],[connectModel floatForKey:@"Width"],[connectModel floatForKey:@"Radius"],
									[connectModel floatForKey:@"Strength"],[connectModel floatForKey:@"MeanDelay"],[connectModel floatForKey:@"StdDelay"]];
					[table appendFormat:@"%@",connectionDescription];
				}
			}
		}
	}

	return [table autorelease];
}

@end
