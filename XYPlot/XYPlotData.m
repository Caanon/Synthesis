#import "XYPlotData.h"
#import <float.h>
#import <assert.h>

#define generateReferenceColumn		YES
#define TEMPLATE_EXTENSION		@"template"
#define XYPlotName			@"XYPlot"


@implementation XYPlotData

- init
{
	NSString	*templatePath;
	
    templatePath = [[NSBundle bundleForClass:[self class]]
    pathForResource: XYPlotName ofType: TEMPLATE_EXTENSION];

    return [self initWithDescription:[NSData dataWithContentsOfFile:templatePath]];
}

- initWithDescription:(NSData *)description
{
    NSString *errorString;
    NSPropertyListFormat type;

    attributesDictionary = [[NSPropertyListSerialization propertyListFromData:description mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&type errorDescription:&errorString] retain];

    if([attributesDictionary objectForKey:DATA_DICT])
        dataDictionary = [NSUnarchiver unarchiveObjectWithData:[attributesDictionary objectForKey:DATA_DICT]];
    else dataDictionary = [NSMutableDictionary dictionary];
    [attributesDictionary setObject:dataDictionary forKey:DATA_DICT];
    [self updateAttributesDictionary];
    return self;
}

- initWithFile:(NSString *)path;
{
	return [self initWithDescription:[NSString stringWithContentsOfFile:path]];
}

- initWithPlainFile:(NSString *)path
{
    [self init];
    [self removeAllCurves];
    [self removeAllData];
    [self addContentsOfPlainFile:path];
    return self;
}

- initWithString:(NSString *)string
{
    [self init];
    [self addValuesFromString:string name:NSUserName()];
    return self;
}

- (void)addContentsOfPlainFile:(NSString *)path
{
    [self addValuesFromString:[NSString stringWithContentsOfFile:path]
                              name:[[path lastPathComponent] stringByDeletingPathExtension]];
    [attributesDictionary setObject: [[path lastPathComponent] stringByDeletingPathExtension] forKey: TITLE];
}

- (void)addValuesFromString:(NSString *)stringData name:(NSString *)name
{
    int c = 1;
    NSString *key;
    NSDictionary *dictionary = [self valuesFromString:stringData name:name];
    NSMutableDictionary *curveDict = [NSMutableDictionary dictionary];
    NSEnumerator *keyEnumerator = [dictionary keyEnumerator];
    while(key = [keyEnumerator nextObject]){
        NSMutableDictionary *curveEntry = [NSMutableDictionary dictionary];
        [curveEntry setObject:[NSMutableArray arrayWithObject:key] forKey:CURVES_DATA];
        [curveDict setObject:curveEntry forKey:[NSString stringWithFormat:@"%@%d",name,c++]];
    }
    [self addCurves:curveDict];
    [self addData:dictionary];
    [self updateAttributesDictionary];
}


- (NSDictionary *)valuesFromString:(NSString *)stringData name:(NSString *)name
{
    NSMutableDictionary *valueDict = [NSMutableDictionary dictionary];
    NSScanner *fileScanner = [NSScanner scannerWithString:stringData];
    NSString *oneLine;
    double value;
    unsigned column = 0;

    [stringData retain];

    while ([fileScanner isAtEnd] == NO) {
        column = 0;
        if([fileScanner scanUpToString:@"\n" intoString:&oneLine]){
                NSScanner *lineScanner = [NSScanner scannerWithString:oneLine];
                NSMutableValueArray *array;
                NSString *key;

                if([oneLine hasPrefix:@"!"]||[oneLine hasPrefix:@"%"]||
                        [oneLine hasPrefix:@"#"]||[oneLine hasPrefix:@"\""]||
                        [oneLine hasPrefix:@"{"]||[oneLine hasPrefix:@"}"])
                                continue;
                NS_DURING
                while([lineScanner isAtEnd] == NO){
                        if([lineScanner scanDouble:&value])column++;
                        else break;
                        key = [NSString stringWithFormat:@"%@%d",name,column];
                        array = [valueDict objectForKey:key];
                        if(!array){
                                array = [NSMutableValueArray
                                        valueArrayWithObjCType:@encode(double)];
                                [valueDict setObject:array forKey:key];
                        }
                        [array addValue:&value];
                }
                NS_HANDLER
                NSLog([localException reason]);
                NSLog([localException name]);
                NS_ENDHANDLER
        }
    }
    [stringData release];
    return valueDict;
}

- initWithMatlabFile:(NSString *)path;
{
	FILE	*fp;
	//int		type;//,M,O,P,T;
	//char	pname[255];
	//int		mrows,ncols,imagf;
	
	
	if((fp=fopen([path cString],"r"))==NULL){ 
		NSLog(@"Couldn't open the filename %@ for writing\n",path); 
		exit(1);
	}
//	if(mlreadh(fp, &type, pname, &mrows, &ncols, &imagf)){
//		NSLog(@"Error reading header for Matlab file %@",path);
//		exit(1);
//	}

	//printf("%d, %d, %d, %d -- %s\n",type,mrows,ncols,imagf,pname);

	//mltype(type,&M,&O,&P,&T);
	//[self initWithRows:mrows andColumns:ncols precision:P];
	//mlreadd (fp, &type,mrows,ncols,imagf, data, (void **)0 );
	return self;
}

- (void)updateAttributesDictionary
{
	NSMutableDictionary *xAxis,*yAxis,*curvesDictionary;
	NSEnumerator *curveEnumerator;
	NSMutableArray *xDataKeys = [NSMutableArray array];
	NSMutableArray *yDataKeys = [NSMutableArray array];
	NSString *curveKey;
	NSRect	plotRect;
		
	dataDictionary = [attributesDictionary objectForKey:DATA_DICT];

	xAxis = [attributesDictionary objectForKey:PLOT_XAXIS];
	yAxis = [attributesDictionary objectForKey:PLOT_YAXIS];

	curvesDictionary = [attributesDictionary objectForKey:CURVES_DICT];
	[attributesDictionary setObject:curvesDictionary forKey:CURVES_DICT];

    //TIMEDIT
    curveEnumerator = [[curvesDictionary allKeys] objectEnumerator];
       // curveEnumerator = [curvesDictionary keyEnumerator];
	while(curveKey = [curveEnumerator nextObject]){
            NSMutableDictionary *curveDict = [curvesDictionary objectForKey:curveKey];
            NSMutableArray *curveArray = [curveDict objectForKey:CURVES_DATA];

            // This adds a column of reference integers corresponding to the number
            // of values in the single column.
            if([curveArray count] == 1){
                NSString *key = [curveArray objectAtIndex:0];
                NSString *refKey = [NSString stringWithFormat:@"%@.reference",key];
                NSArray *refValues;
                refValues = [self referenceValuesForKey:key];
                [dataDictionary setObject:refValues forKey:[NSString stringWithFormat:@"%@.reference",key]];
                [curveArray insertObject:refKey atIndex:0];
                [curveDict setObject:curveArray forKey:CURVES_DATA];
                [curvesDictionary setObject:curveDict forKey:curveKey];
            }
            [xDataKeys addObject:[curveArray objectAtIndex:0]];
            [yDataKeys addObject:[curveArray objectAtIndex:1]];
	}

//    plotRect = [attributesDictionary rectForKey:PLOT_RECT];
	
    plotRect.origin.x = [[self minValueForKeys:xDataKeys] doubleValue];
        plotRect.origin.y = [[self minValueForKeys:yDataKeys] doubleValue];
    plotRect.size.width = 
        [[self maxValueForKeys:xDataKeys] doubleValue]-plotRect.origin.x;
    plotRect.size.height = 
        [[self maxValueForKeys:yDataKeys] doubleValue]-plotRect.origin.y;


        plotRect = NSIntegralRect(plotRect);

    if([xAxis boolForKey:AUTO_SCALE]){
        [xAxis setObject:[NSNumber numberWithDouble:NSMinX(plotRect)]
            forKey:MINIMUM];
        [xAxis setObject:[NSNumber numberWithDouble:NSMaxX(plotRect)]
            forKey:MAXIMUM];
    }
    else {
        plotRect.origin.x = [xAxis floatForKey:MINIMUM];
        plotRect.size.width = [xAxis floatForKey:MAXIMUM]-plotRect.origin.x;
    }

    if([yAxis boolForKey:AUTO_SCALE]){
        [yAxis setObject:[NSNumber numberWithDouble:NSMinY(plotRect)]
            forKey:MINIMUM];
        [yAxis setObject:[NSNumber numberWithDouble:NSMaxY(plotRect)]
            forKey:MAXIMUM];
    }
    else {
        plotRect.origin.y = [yAxis floatForKey:MINIMUM];
        plotRect.size.height = [yAxis floatForKey:MAXIMUM]-plotRect.origin.y;
    }


	if([xDataKeys count]&&[yDataKeys count]){
        [self updateTicksForAxis:PLOT_XAXIS];
        [self updateTicksForAxis:PLOT_YAXIS];
    }
	[attributesDictionary setRect:plotRect forKey:PLOT_RECT];
}

- (void)updateTicksForAxis:(NSString *)axisKey
{
	NSMutableDictionary *axisDictionary = [attributesDictionary objectForKey:axisKey];
	float majorTickInc = [axisDictionary floatForKey:MAJORTICK_INC];
	//float minorTickInc = [axisDictionary floatForKey:MINORTICK_INC];
	float min = [axisDictionary floatForKey:MINIMUM];
	float max = [axisDictionary floatForKey:MAXIMUM];
	NSMutableArray *tickValues = [NSMutableArray array];
	NSMutableArray *tickLabels = [NSMutableArray array];

        if(![[attributesDictionary objectForKey:DATA_DICT] count])return;

	computeNiceLinInc(&min,&max,&majorTickInc);
	min = [axisDictionary floatForKey:MINIMUM];
	max = [axisDictionary floatForKey:MAXIMUM];

	if ([axisDictionary boolForKey:AUTO_TICKS]) {
		// calculate tick values and labels to fill tickValues, tickLabels
		// first, calc number of ticks and value of first one
		int numTicks = 0;
		float firstTickValue = min;
		if (majorTickInc != 0.0) {
			int j;
			double myRange = ABS (max - min);
			int myUpper = (int) (max / majorTickInc) + 1;
			int myLower = (int) (min / majorTickInc) - 1;
			double myInc = MIN (myRange, ABS (majorTickInc));
			double myGuess;
			double myScale = myInc * (myRange + myInc) / 100.0;

			for (j = myUpper; j >= myLower; j--) {
				myGuess = (double) j * majorTickInc;
				if ( (max - myGuess) * (myGuess - min) >= -myScale) {
					numTicks += 1;
					firstTickValue = myGuess;
				}
			}

			for (j = 0; j < numTicks; j++) {
				[tickValues addObject: 
					[NSNumber numberWithDouble: 
					firstTickValue + (double) j * myInc]];
				[tickLabels addObject: 
					[NSString stringWithFormat: @"%g",
					firstTickValue + (double) j * myInc]];
			}
		}
		[axisDictionary setObject:tickValues forKey:TICK_VALUES];
		[axisDictionary setObject:tickLabels forKey:TICK_LABELS];
	}
}

-(unsigned)count
{
    return [dataDictionary count];
}

- (NSArray *)valuesForKey:(NSString *)key
{
	return [dataDictionary objectForKey:key];
}

- (void)setValues:(NSArray *)values forKey:(NSString *)key
{
    [dataDictionary setObject:values forKey:key];
}

- (NSArray *)referenceValuesForKey:(NSString *)key
{
	unsigned int i;
	int count = [[dataDictionary objectForKey:key] count];
	NSMutableValueArray *array = 
		[NSMutableValueArray valueArrayWithObjCType:@encode(unsigned int)];
	for(i=0;i<count;i++){
		[array addValue:&i];
	}
	return array;
}

- (void)setDataDictionary:(NSDictionary *)dict
{
    [attributesDictionary setObject:[[dict mutableCopy] autorelease] forKey:DATA_DICT];
}

- (void)setCurvesDictionary:(NSDictionary *)dict
{
    [attributesDictionary setObject:[[dict mutableCopy] autorelease] forKey:CURVES_DICT];
}

- (void)setAttributesDictionary:(NSDictionary *)dict
{
    attributesDictionary = [dict mutableCopy];
}

// Merges dict with the attributeDictionary
- (void)addAttributes:(NSDictionary *)dict
{
    [attributesDictionary addEntriesFromDictionary:dict];
}

// Merges dict with the curves dictionary within the attributeDictionary
- (void)addCurves:(NSDictionary *)dict
{
    [[self curvesDictionary] addEntriesFromDictionary:dict];
}

- (void)addCurves:(NSArray *)curveArray forKey:curveKey
{
    NSMutableDictionary *dict = [[self curvesDictionary] objectForKey:curveKey];
    if(!dict){
        dict = [NSMutableDictionary dictionary];
        [[self curvesDictionary] setObject:dict forKey:curveKey];
    }
    [[dict objectForKey:CURVES_DATA] addObjectsFromArray:curveArray];
}

- (void)setCurves:(NSArray *)curveArray forKey:curveKey
{
    NSMutableDictionary *dict = [[self curvesDictionary] objectForKey:curveKey];
    if(!dict){
        dict = [NSMutableDictionary dictionary];
        [[self curvesDictionary] setObject:dict forKey:curveKey];
    }
    [dict setObject:[[curveArray mutableCopy] autorelease] forKey:CURVES_DATA];
}

- (void)setData:(NSArray *)dataArray forKey:dataKey
{
    [[self dataDictionary] setObject:[[dataArray mutableCopy] autorelease] forKey:dataKey];
}

- (void)addData:(NSArray *)dataArray forKey:dataKey
{
    [[[self dataDictionary] objectForKey:dataKey] addObjectsFromArray:dataArray];
}


// Merges dict with the data dictionary within the attributeDictionary
- (void)addData:(NSDictionary *)dict
{
    [[attributesDictionary objectForKey:DATA_DICT] addEntriesFromDictionary:dict];
}

- (void)removeAllCurves
{
    [[attributesDictionary objectForKey:CURVES_DICT] removeAllObjects];
}

- (void)removeAllData
{
    [[attributesDictionary objectForKey:DATA_DICT] removeAllObjects];
}

- (NSMutableDictionary *)curvesDictionary
{
    return [attributesDictionary objectForKey:CURVES_DICT];
}

- (NSMutableDictionary *)dataDictionary
{
	return [attributesDictionary objectForKey:DATA_DICT];
}

- (NSMutableDictionary *)attributesDictionary
{
	return attributesDictionary;
}

- (NSNumber *)minValueForKey:(NSString *)key
{
	NSEnumerator *enumerator;
	NSNumber *min = [NSNumber numberWithDouble:DBL_MAX];
	NSNumber *value;

	enumerator = [[self valuesForKey:key] objectEnumerator];
	while(value=[enumerator nextObject]){
		if([min compare:value] == NSOrderedDescending)
			min = [NSNumber numberWithDouble:[value doubleValue]];
	}
	return min;
}

- (NSNumber *)maxValueForKey:(NSString *)key
{
	NSEnumerator *enumerator;
	NSNumber *max = [NSNumber numberWithDouble:DBL_MIN];
	NSNumber *value;

	enumerator = [[self valuesForKey:key] objectEnumerator];
	while(value=[enumerator nextObject]){
		if([max compare:value] == NSOrderedAscending)
			max = [NSNumber numberWithDouble:[value doubleValue]];
	}
	return max;
}

- (NSNumber *)maxValueForKeys:(NSArray *)keys
{
	NSEnumerator *enumerator;
	NSNumber *max = [NSNumber numberWithDouble:DBL_MIN];
	NSString *key;
	NSNumber *value;

	enumerator = [keys objectEnumerator];
	while(key=[enumerator nextObject]){
		value = [self maxValueForKey:key];
		if([max compare:value] == NSOrderedAscending)
			max = [NSNumber numberWithDouble:[value doubleValue]];
	}
	return max;
}

- (NSNumber *)minValueForKeys:(NSArray *)keys
{
	NSEnumerator *enumerator;
	NSNumber *min = [NSNumber numberWithDouble:DBL_MAX];
	NSString *key;
	NSNumber *value;

	enumerator = [keys objectEnumerator];
	while(key=[enumerator nextObject]){
		value = [self minValueForKey:key];
		if([min compare:value] == NSOrderedDescending)
			min = [NSNumber numberWithDouble:[value doubleValue]];
	}
	return min;
}	

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    NS_DURING	
    [aCoder encodeObject:attributesDictionary];
    NS_HANDLER
    NSLog([localException name]);
    NSLog([localException reason]);
    NS_ENDHANDLER
}

- initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    NS_DURING
    attributesDictionary = [[aDecoder decodeObject] retain];
    NS_HANDLER
    NSLog([localException name]);
    NSLog([localException reason]);
    NS_ENDHANDLER

    [self updateAttributesDictionary];
    return self;
}

- (NSString *)description
{
    NSString *description;
    id tempDataDict = [[self dataDictionary] retain];
    NSData *archivedData = [NSArchiver archivedDataWithRootObject:dataDictionary];
    [attributesDictionary setObject:archivedData forKey:DATA_DICT];
    description = [attributesDictionary description];
    [attributesDictionary setObject:tempDataDict forKey:DATA_DICT];
    [tempDataDict release];
    return description;
}

@end

/*
 * Compute nice increment for linear plotting, given min and max.
 */
void computeNiceLinInc(float *pmin, float *pmax, float *pinc)
{
  float fmin = *pmin, fmax = *pmax, finc = (fmax - fmin)/5.0, x;
  int n;

  if(fmin==0.0 && fmax==0.0){return;}//finc = 0.0;

  if (finc <= 0.0) {
    fmin = (fmin>0.0? 0.9*fmin : 1.1*fmin);
    fmax = (fmax>0.0? 1.1*fmax : 0.9*fmax);
    finc = (fmax - fmin)/5.0;
    // for safety:
    if (finc < 0.0) {
		*pmin = 0.0;
		*pmax = 1.0;
		*pinc = 0.2;
		return;
    }
  }
  
  n = ( log10((double)finc) >= 0.0 ? (int)floor(log10((double)finc)) :
       (int)ceil(log10((double)finc)) );
  if (finc > 1.0) n++;
  x = finc * (float)pow((double)10.0, (double)(-n));
  finc = 0.1;
  if (x > 0.1)  finc = 0.2;
  if (x > 0.2)  finc = 0.25;
  if (x > 0.25) finc = 0.5;
  if (x > 0.5)  finc = 1.0;
  finc = finc * (float)pow((double)10.0, (double)n);

  if (fmin < ((int)(fmin/finc))*finc) fmin = ((int)(fmin/finc - 1))*finc;
  else                                fmin = ((int)(fmin/finc))*finc;

  if (fmax > ((int)(fmax/finc))*finc) fmax = ((int)(fmax/finc + 1))*finc;
  else                                fmax = ((int)(fmax/finc))*finc;

  *pmin = fmin;
  *pmax = fmax;
  *pinc = finc;
  return;
}

