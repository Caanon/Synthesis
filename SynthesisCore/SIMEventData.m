/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */
 
#import <SynthesisCore/SIMEventData.h>
#import <math.h>

@implementation SIMEventData

/*"
    This class is currently under development and has a number of flaws and inconsistencies.
    It should not be widely used.  Please restrict it's use to outside of the SynthesisCore core
    for the time being.
"*/


#define min(x,y) ((x)<(y) ? (x):(y))
#define max(x,y) ((x)>(y) ? (x):(y))
#define	limit(a) ((a)>=0 ? (a):0)

NSComparisonResult eventTimeSort (id value1, id value2, void *context)
{
	SIMEventStruct	event1,event2;
	
	[value1 getValue:&event1];
	[value2 getValue:&event2];

    if(event1.time < event2.time)return NSOrderedAscending;
    if((event1.time == event2.time) && (event1.unit < event2.unit)) return NSOrderedAscending;

    if(event1.time > event2.time)return NSOrderedDescending;
    if((event1.time == event2.time) && (event1.unit > event2.unit)) return NSOrderedDescending;

    return NSOrderedSame;
}


- init
{
	[super init];

	srand(1000);

    if (!eventDict) {
        eventDict = [[NSMutableDictionary dictionary] retain];
    }

	// Fills in the default header entries.
    if (!headerArray) {
        headerArray = [NSMutableArray array];
        [headerArray addObject:@"\"VERSION=0\""];
        [headerArray addObject: [NSString stringWithFormat:@"\"TIME_UNITS=%g\"", 0.001]];
		[headerArray addObject: [NSString stringWithFormat:@"\"TITLE(0) = '%@'\"", @"FILENAME"]];
		[headerArray addObject: [NSString stringWithFormat:@"\"TITLE(1) = '%@'\"", [NSCalendarDate date]]];
	}
	return self;
}


- initWithAbelesFormatFile: (NSString *) filename
{
	char	c,line[MAXLENGTH],buf[MAXLENGTH] = "";
	int		index;
	int		delta = 0;
	NSMutableValueArray		*spikeData=nil;
    NSString *key;
	SIMEventStruct event = SIMNullEventStruct;
	FILE	*fp;

	[self init];
	
	[headerArray removeAllObjects];

	if((fp=fopen([filename UTF8String],"r"))==NULL){
		NSLog(@"Couldn't open file.\n");
		return nil;
	}

	index = 0;
	while((c=fgetc(fp))!=EOF){
		if(c=='"'||c=='\''){
            // Currently treats '"' character as a comment marker
			fgets(line,MAXLENGTH,fp);
			if(strncmp(line,"CHKSM",5)==0)continue;
			[headerArray addObject:[NSString stringWithFormat:@"%c%s",c,line]];
		}
		else {
			if(c==' '||c=='\t'||c=='\n'){
				buf[index] = '\0';
				index=0;
				//if(strcmp(buf,END_OF_DATA)==0)continue;
				if(strcmp(buf,START_OF_DATA)==0)continue;
				if(sscanf(buf,"%x,%x,%d",&event.type,&event.unit,&delta)==3){
					if((event.unit == END_OF_DATA_ID) && (event.type == END_OF_DATA_TYPE)){
						endDataTime = event.time+delta;
						continue;
					}
					if(event.unit == END_OF_FILE)continue;
					if(delta < 0) {
						NSLog (@"Negative time increment -- event skipped.");
						continue;
					}
					event.time += delta;
   					key = [NSString stringWithFormat:@"%X-%X",event.type,event.unit];

					if(!(spikeData = [eventDict objectForKey:key])){
                        spikeData = [NSMutableValueArray valueArrayWithObjCType:@encode(SIMEventStruct)];
                        [eventDict setObject:spikeData forKey:[key capitalizedString]];
                    }
                    [spikeData addValue:&event];
				}
			}
			else buf[index++]=c;
		}
	}
	fclose (fp);

	//NSLog([[eventDict allKeys] description]);
	return self;
}

- initWithEventDict: (NSDictionary *) d headerArray: (NSArray *) e
{
	[self setEventDictionary: d];
	[self setHeaderArray: e];
	return self;
}

- copy
{
	SIMEventData *d = [[SIMEventData alloc] 
		initWithEventDict: [self eventDictionary] 
		headerArray: [self headerArray]];
	return [d autorelease];
}

- (NSMutableDictionary *) eventDictionary
{
	return eventDict;
}

- (NSArray *) headerArray
{
	return headerArray;
}

- (void) setEventDictionary: (NSDictionary *) e
{
	[eventDict autorelease];
	eventDict = [e mutableCopy];
}

- (void) setHeaderArray: (NSArray *) h
{
	[headerArray autorelease];
	headerArray = [h mutableCopy];
}

- (void) addEvent:(SIMEventStruct)event
{
        id	spikeData;
        NSString *key = [NSString stringWithFormat:@"%X-%X",event.type,event.unit];

    if(!(spikeData = [eventDict objectForKey:key])){
        spikeData = [NSMutableValueArray
            valueArrayWithObjCType:@encode(SIMEventStruct)];
        [eventDict setObject:spikeData forKey:key];
    }
    //if(![spikeData containsObject:[NSValue value:&event withObjCType:@encode(SIMEventStruct)]])
        [spikeData addValue:&event];
}

- (void) addEvent:(SIMEventStruct)event forKey:(NSString *)key
{
        id	spikeData;

    if(!(spikeData = [eventDict objectForKey:key])){
        spikeData = [NSMutableValueArray
            valueArrayWithObjCType:@encode(SIMEventStruct)];
        [eventDict setObject:spikeData forKey:key];
    }
    //if(![spikeData containsObject:[NSValue value:&event withObjCType:@encode(SIMEventStruct)]])
        [spikeData addValue:&event];
}

- (void) removeEvent:(SIMEventStruct)event
{
	id	spikeData;
    NSString *key = [NSString stringWithFormat:@"%X-%X",event.type,event.unit];
	
	if(!(spikeData = [eventDict objectForKey:key])){
		return;
	}	
	[(NSMutableArray *)spikeData removeObject:[NSValue value:&event withObjCType:@encode(SIMEventStruct)]];
}

- (void) sortEventsByTime
{
    NSEnumerator *enumAll = [eventDict objectEnumerator];
    NSMutableValueArray *eventArray;
    while(eventArray = [enumAll nextObject]){
        [eventArray sortUsingFunction:eventTimeSort context:NULL];
    }
}

/* Sorts the event arrays and find the greatest value of time */
- (unsigned long) lastTime
{
    unsigned long lasttime = 0;
    NSEnumerator *enumAll = [eventDict keyEnumerator];
    NSString *key;
    while(key = [enumAll nextObject]){
        lasttime = max(lasttime,[self lastTimeForKey:key]);
    }
    return lasttime;
}

- (unsigned long) lastTimeForKey:(NSString *)key
{
    SIMEventStruct event;
    NSMutableValueArray *eventArray = [eventDict objectForKey:key];

    [eventArray sortUsingFunction:eventTimeSort context:NULL];
    [(NSValue *)[eventArray lastObject] getValue:&event];
    return event.time;
}

- (unsigned long) firstTimeForKey:(NSString *)key
{
    SIMEventStruct event;
    NSMutableValueArray *eventArray = [eventDict objectForKey:key];

    [eventArray sortUsingFunction:eventTimeSort context:NULL];
    [(NSValue *)[eventArray objectAtIndex:0] getValue:&event];
    return event.time;
}

- (unsigned int) firstUnit
{
    unsigned int firstUnit = 0;
    NSEnumerator *enumAll = [eventDict objectEnumerator];
    NSMutableValueArray *eventArray;
    while(eventArray = [enumAll nextObject]){
        SIMEventStruct event;
        [(NSValue *)[eventArray objectAtIndex:0] getValue:&event];
        firstUnit = min(firstUnit,event.unit);
    }
    return ((firstUnit == 0) ? 1:firstUnit);
}

- (unsigned int) lastUnit
{
    unsigned int lastUnit = 0;
    NSEnumerator *enumAll = [eventDict objectEnumerator];
    NSMutableValueArray *eventArray;
    while(eventArray = [enumAll nextObject]){
        SIMEventStruct event;
        [(NSValue *)[eventArray objectAtIndex:0] getValue:&event];
        lastUnit = max(lastUnit,event.unit);
    }
    return lastUnit;
}

- (unsigned int) countForEvent:(SIMEventStruct *)event
{
    NSString *key = [NSString stringWithFormat:@"%X-%X",event->type,event->unit];

    return [[eventDict objectForKey:key] count];
}

- (unsigned int) countForKey:(NSString *)key
{
    return [[eventDict objectForKey:key] count];
}

+ (void)remapEvents:(NSMutableValueArray *)events toType:(unsigned int)type andUnit:(unsigned int)unit
/*"
	Remaps the unit id and event type for all events.
	If unit or type are %nil it leaves the current value in the event.
"*/
{
	SIMEventStruct *bytes = [events mutableBytes];
	int count = [events count],i;
	for(i = 0; i < count; i++){
		if(unit)bytes[i].unit = unit;
		if(type)bytes[i].type = type;
	}
}

+ (void)remapEvents:(NSMutableValueArray *)events toTime:(unsigned long)startTime 
/*"
        Remaps the time for all events.
        If unit or type are %nil it leaves the current value in the event.
"*/
{
        SIMEventStruct *bytes = [events mutableBytes];
        int count = [events count],i;
	int delta;
        [events sortUsingFunction:eventTimeSort context:NULL];
	delta = startTime - bytes[0].time;
        for(i = 0; i < count; i++){
                if(startTime)bytes[i].time += delta;
        }
}


- (void) addSegment:(NSValueArray *)events
{
    [self addSegment:events remapEvent:(SIMEventStruct *)nil syncEvent:(SIMEventStruct *)nil];
}

- (void) addSegment:(NSValueArray *)events syncEvent:(SIMEventStruct *)syncEvent
{
    [self addSegment:events remapEvent:(SIMEventStruct *)nil syncEvent:syncEvent];
}

- (void) addSegment:(NSValueArray *)events remapEvent:(SIMEventStruct *)event
	syncEvent:(SIMEventStruct *)syncEvent
/*"
	Appends the events to the current event array if the events don't already exist.
	All events must be of the same type and for the same unit id.  
	An syncEvent indicating the start of this segment will be added if it is provided.
	The time value of the remap event is ignored.
"*/
{
    NSMutableValueArray *syncArray,*eventArray;
    const SIMEventStruct *bytes = [events bytes];
    int count = [events count],i;
	int lastTime;
    NSString *syncKey;
    NSString *eventKey;

    if(syncEvent != (SIMEventStruct *)nil){
        syncKey = [NSString stringWithFormat:@"%X-%X",syncEvent->type,syncEvent->unit];
        syncArray = [eventDict objectForKey: syncKey];
        if(!syncArray) {
            syncArray = [NSMutableValueArray valueArrayWithObjCType:@encode(SIMEventStruct)];
            [eventDict setObject:syncArray forKey:syncKey];
        }

        if(![syncArray containsObject:[NSValue value:syncEvent withObjCType:@encode(SIMEventStruct)]])
            [syncArray addValue:syncEvent];
        lastTime = syncEvent->time;
    }
	else {
		syncEvent = calloc(1,sizeof(SIMEventStruct));  // A memory leak!  This should be freed
		lastTime = 0;
	}

        if([events count] <= 0 )return;

	if(event == (SIMEventStruct *)nil){
        event = calloc(1,sizeof(SIMEventStruct));  // A memory leak!  This should be freed
        [events getValue:event atIndex:0];
	}
    eventKey = [NSString stringWithFormat:@"%X-%X",event->type,event->unit];
    eventArray = [eventDict objectForKey: eventKey];
    if(!eventArray) {
        eventArray = [NSMutableValueArray valueArrayWithObjCType:@encode(SIMEventStruct)];
        [eventDict setObject:eventArray forKey:eventKey];
    }

    for(i = 0; i < count; i++){
        event->time = lastTime + bytes[i].time;
        if(![eventArray containsObject:[NSValue value:event withObjCType:@encode(SIMEventStruct)]])
        [eventArray addValue:event];
    }
    //[eventArray addValues:bytes count:count];
    [eventArray sortUsingFunction:eventTimeSort context:NULL];
}

- (void) addSegments:(NSDictionary *)segments remapEvent:(SIMEventStruct *)event
    syncEvent:(SIMEventStruct *)syncEvent duration:(unsigned int)duration
{
    int i;

    for(i = 0;i < [segments count]; i++){
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [self addSegment:[segments objectForKey:[NSString stringWithFormat:@"%d",i]]
            remapEvent:event syncEvent:syncEvent];
        syncEvent->time += duration;
		[pool release];
    }
}

- (void) addRandomSegments:(NSDictionary *)segments count:(unsigned int)count 
	remapEvent:(SIMEventStruct *)event syncEvent:(SIMEventStruct *)syncEvent duration:(unsigned int)duration
{
    int i;

    for(i = 0;i < count; i++){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		int index = (int)([segments count]-1)*((float)rand()/RAND_MAX);
        [self addSegment:[segments objectForKey:[NSString stringWithFormat:@"%d",index]]
            remapEvent:event syncEvent:syncEvent];
        syncEvent->time += duration;
		[pool release];
    }
}

- (SIMEventData *)mergeEventData:(SIMEventData *)eventData eventType:(unsigned int)type
	fromSyncEvent:(SIMEventStruct *)fromSync toSyncEvent:(SIMEventStruct *)toSync 
	randomize:(BOOL)randFlag count:(unsigned int)count duration:(unsigned int)duration
{
	SIMEventStruct event;
	NSString *key;
	NSDictionary *fromSegments;
	SIMEventData *mergedData = [[SIMEventData alloc] init];
    NSEnumerator *keyEnum = [[self eventKeys] objectEnumerator];

    while(key = [keyEnum nextObject]){
        unsigned int hexType;
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSArray *typeComponents = [key componentsSeparatedByString:@"-"];
        NSLog([typeComponents description]);
        sscanf([[typeComponents objectAtIndex:0] UTF8String],"%x",&hexType);
        if(hexType == type){
            event.type = type;
            sscanf([[typeComponents objectAtIndex:1] UTF8String],"%x",&event.unit);
            printf("%X,%X,%ld\n",event.type,event.unit,event.time);
            fromSegments = [self getSegmentsForEvent:&event syncEvent:fromSync duration:duration];
            toSync->time = 0;
            if([[mergedData eventKeys] containsObject:key]){
                event.unit = [mergedData lastUnit]+1;
                printf("Remapped event unit to: %X\n",[mergedData lastUnit]+1);
            }
            [mergedData addSegments:fromSegments remapEvent:&event syncEvent:toSync duration:duration];	
        }
        [pool release];
    }

    keyEnum = [[eventData eventKeys] objectEnumerator];
	while(key = [keyEnum nextObject]){
		unsigned int hexType;
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSArray *typeComponents = [key componentsSeparatedByString:@"-"];
		NSLog([typeComponents description]);
        sscanf([[typeComponents objectAtIndex:0] UTF8String],"%x",&hexType);
		if(hexType == type){
            event.type = type;
            sscanf([[typeComponents objectAtIndex:1] UTF8String],"%x",&event.unit);
            printf("%X,%X,%ld\n",event.type,event.unit,event.time);
            fromSegments = [eventData getSegmentsForEvent:&event syncEvent:fromSync duration:duration];
            toSync->time = 0;
            if([[mergedData eventKeys] containsObject:key]){
                event.unit = [mergedData lastUnit]+1;
                printf("Remapped event unit to: %X\n",[mergedData lastUnit]+1);
            }
            if(randFlag)
                [mergedData addRandomSegments:fromSegments count:count 
					remapEvent:&event syncEvent:toSync duration:duration];
            else
                [mergedData addSegments:fromSegments remapEvent:&event syncEvent:toSync duration:duration];	
        }
		[pool release];
	}

        [mergedData sortEventsByTime];

	return [mergedData autorelease];
}



- (NSValueArray *) getSegment:(unsigned int)num forEvent:(SIMEventStruct *)event 
	syncEvent:(SIMEventStruct *)sync duration:(unsigned int)duration
{
    int i,count;
    unsigned long startTime;
    const SIMEventStruct *eventBytes;
    const SIMEventStruct *syncBytes;
    NSMutableValueArray *segment =
        [[NSMutableValueArray valueArrayWithObjCType:@encode(SIMEventStruct)] retain];
    NSMutableValueArray *syncArray,*eventArray;
    NSString *syncKey = [NSString stringWithFormat:@"%X-%X",sync->type,sync->unit];
    NSString *eventKey = [NSString stringWithFormat:@"%X-%X",event->type,event->unit];
    syncArray = [eventDict objectForKey: syncKey];
    if(!syncArray) return nil;
    eventArray = [eventDict objectForKey: eventKey];
    if(!eventArray) return nil;
    [eventArray sortUsingFunction:eventTimeSort context:NULL];
    eventBytes = [eventArray bytes];
    //[syncArray sortUsingFunction:eventTimeSort context:NULL];
    syncBytes = [syncArray bytes];

    // Find selected sync event time.
    startTime = syncBytes[num].time;
    // Find events that occur after the sync event but within the duration specified.
    count = [eventArray count];
    for(i = 0; i < count; i++){
        if(eventBytes[i].time > startTime + duration)break;
        if (eventBytes[i].time >= startTime){
            SIMEventStruct anEvent;
            anEvent.time = eventBytes[i].time - startTime;
            anEvent.unit = eventBytes[i].unit;
            anEvent.type = eventBytes[i].type;
            anEvent.value = eventBytes[i].value;
            [segment addValue:&anEvent];
        }
    }
    return [segment autorelease];
}

- (NSDictionary *) getSegmentsForEvent:(SIMEventStruct *)event syncEvent:(SIMEventStruct *)syncEvent duration:(unsigned int)duration
{
    int i;
    NSMutableDictionary *segments = [[NSMutableDictionary dictionary] retain];

    //[self sortEventsByTime];

    for(i = 0;i < [self countForEvent:syncEvent]; i++){
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        id obj = [self getSegment:i forEvent:event syncEvent:syncEvent duration:duration];
        if(obj)[segments setObject:obj forKey:[NSString stringWithFormat:@"%d",i]];
        else [segments setObject:[NSMutableValueArray valueArrayWithObjCType:@encode(SIMEventStruct)]
            forKey:[NSString stringWithFormat:@"%d",i]];
        [pool release];
    }
    return [segments autorelease];
}

- (float)meanFiringRateForEvent:(SIMEventStruct)event syncEvent:(SIMEventStruct)syncEvent 
	duration:(unsigned int)duration
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSDictionary *aSeg,*segments = [self getSegmentsForEvent:&event syncEvent:&syncEvent duration:duration];
    float sum = 0,count = [segments count];
    NSEnumerator *e = [segments objectEnumerator];

    while(aSeg = [e nextObject]){
	sum += [aSeg count]/(float)duration;
    }
    [pool release];
    return sum/count;
}

- (NSData *) rasterizeEvents:(SIMEventStruct *)templateEvent
{
	NSMutableData *raster;
        SIMEventStruct	event = SIMNullEventStruct;
	NSValue	*value;
	NSEnumerator *enumerator;
	unsigned char *dataPtr;
	
    NSString *key = [NSString stringWithFormat:@"%X-%X",templateEvent->type,templateEvent->unit];

    if ([eventDict objectForKey: key]) {
		raster = [[NSMutableData alloc] init];
		enumerator = [[eventDict objectForKey: key] objectEnumerator];
		while (value = [enumerator nextObject]){
			[value getValue:&event];
			if(event.unit == END_OF_FILE)break;
			[raster setLength:event.time+1];
			dataPtr = (unsigned char *)[raster mutableBytes];
  			dataPtr[event.time]=MAXPIXELVALUE;
		}
		[raster setLength: event.time];
		return [raster autorelease];
	}
	else
		return [NSData data];
}

- (NSData *) rasterizeEvents:(SIMEventStruct *)event
    syncEvent:(SIMEventStruct *)sync
	scanLength:(int)length scanRows:(int)rows
/*"
    Returns an NSData object filled with scanLength * scanRows bytes.  Each byte represents
    a single millisecond and contains either a zero or MAXPIXELVALUE depending on whether an
    event (eventType) occured at that time step from eventUnit.
    The time for each row (containing length bytes) is synchronized to events of syncType
    and syncUnit.
"*/
{
	NSMutableData *raster;
    int i,j,count;
    unsigned long startTime;
    unsigned char *dataPtr;
    const SIMEventStruct *eventBytes;
    const SIMEventStruct *syncBytes;
    NSValueArray *syncArray,*eventArray;
    NSString *syncKey = [NSString stringWithFormat:@"%X-%X",sync->type,sync->unit];
    NSString *eventKey = [NSString stringWithFormat:@"%X-%X",event->type,event->unit];

    syncArray = [eventDict objectForKey: syncKey];
    if(!syncArray) return nil;
    eventArray = [eventDict objectForKey: eventKey];
    if(!eventArray) return nil;
    eventBytes = [eventArray bytes];
    syncBytes = [syncArray bytes];

    raster = [[NSMutableData dataWithLength:length*rows] retain];
    dataPtr = (unsigned char *)[raster mutableBytes];

	for(j = 0; (j < [syncArray count]) && (j <= rows); j++){	
        startTime = syncBytes[j].time;
        // Find events that occur after the sync event but within the duration specified.
        count = [eventArray count];
        for(i = 0; i < count; i++){
            if ((eventBytes[i].time > startTime) && (eventBytes[i].time < (startTime + length))
                && (eventBytes[i].time < syncBytes[j+1].time)){
                dataPtr[(j*length)+(int)(eventBytes[i].time - startTime)] = MAXPIXELVALUE;
            }
        }
    }
    return [raster autorelease];
}

- (NSValueArray *) eventsForKey:(NSString *)key
{
    if(![eventDict objectForKey: key])
            return [NSMutableValueArray valueArrayWithObjCType:@encode(SIMEventStruct)];
    else return [eventDict objectForKey:key];
}

- (NSValueArray *) eventTimesForKey: (NSString *) key
{
	NSMutableValueArray *timesArray;
	SIMEventStruct	event;
	NSValue	*value;
	NSEnumerator *enumerator;
	
	if(![eventDict objectForKey: key])
		return [NSMutableValueArray array];
	
	enumerator = [[eventDict objectForKey:key] objectEnumerator];
	timesArray = [NSMutableValueArray valueArrayWithObjCType:@encode(unsigned long)];
	while (value = [enumerator nextObject]) {
		[value getValue: &event];
		[timesArray addValue:&event.time];
	}
	return (NSValueArray *)timesArray;
}

- (NSArray *) headers
{
	return headerArray;
}

- (NSArray *) eventKeys
{
	return [eventDict allKeys];
}

- (NSArray *) eventKeysSortedByCount
{
    return [eventDict keysSortedByValueUsingSelector:@selector(compareCount:)];
}

- (void) writeAbelesFormatToFile: (NSString *) file
{
	char	buf[MAXLENGTH];
	NSMutableValueArray	*eventArray;
	NSEnumerator *enumerator;
	NSString *string;
	SIMEventStruct	*eventBytes;
	id	key;
	unsigned long	lasttime = 0;
	FILE	*fp;
	int i,index,count;
	int checksum = 0;
	int numEvents = 0;
	int lineCount = 0;
	
	eventArray = [NSMutableValueArray 
			valueArrayWithObjCType: @encode (SIMEventStruct)];
	enumerator = [eventDict keyEnumerator];
	while(key = [enumerator nextObject]){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[eventArray addObjectsFromArray:[eventDict objectForKey:key]];
		[pool release];
	}
	[eventArray sortUsingFunction:eventTimeSort context:NULL];
	
	if((fp=fopen([file UTF8String],"w"))==NULL){
		NSLog(@"Couldn't open %@ for writing\n",file);
		exit(1);
	}
	enumerator = [headerArray objectEnumerator];
	while(string = [enumerator nextObject]){
		fputs([string UTF8String],fp);
		fputs("\n",fp);
	}
	sprintf(buf,"%s",START_OF_DATA);
	for(i=0;i<strlen(buf);i++){
		checksum += (int)buf[i];
	}
	fprintf(fp,"%s ",buf);

	eventBytes = (SIMEventStruct *)[eventArray bytes];
	count = [eventArray count];
	for(index = 0; index < count; index++){
		sprintf(buf,"%X,%X,%ld",
          eventBytes[index].type,eventBytes[index].unit,(eventBytes[index].time-lasttime));
		for(i=0;i<strlen(buf);i++){
			checksum += (int)buf[i];
		}
		fprintf(fp,"%s ",buf);
		numEvents++;
		if(numEvents==8){
			numEvents = 0;
			fputs("\n",fp);
			if((++lineCount%10)==0){
				fprintf(fp,"\"CHKSM = %X\"\n",checksum);
				checksum = 0;
			}
		}
        lasttime = eventBytes[index].time;

	}
	sprintf(buf,"%d,%d,%ld", END_OF_DATA_TYPE, END_OF_DATA_ID, [self lastTime] - lasttime);
	for(i=0;i<strlen(buf);i++){
		checksum += (int)buf[i];
	}
	fprintf(fp,"%s\n",buf);
	fprintf(fp,"\"CHKSM = %X\"\n",checksum);
	fprintf(fp,"%s\n",END_OF_FILE_STRING);
	fclose(fp);
}
	
- (void) writeTimesToFile:(NSString *)file
{
    NSMutableValueArray	*eventArray;
    NSArray *eventKeys;
    NSEnumerator *enumerator;
    SIMEventStruct	*eventBytes;
    id	key;
    FILE *fp;
    int index,count;

    if((fp=fopen([file UTF8String],"w"))==NULL){
        NSLog(@"Couldn't open %@ for writing\n",file);
        exit(1);
    }

    eventArray = [NSMutableValueArray
                    valueArrayWithObjCType: @encode (SIMEventStruct)];
    enumerator = [eventDict keyEnumerator];
    eventKeys = [eventDict allKeys];
    while(key = [enumerator nextObject]){
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSValueArray *eventArray = [eventDict objectForKey:key];
        //[eventArray sortUsingFunction:eventTimeSort context:NULL];
        eventBytes = (SIMEventStruct *)[eventArray bytes];
        count = [eventArray count];
        for(index = 0; index < count; index++){
            fprintf(fp,"%s %ld\n",[key UTF8String],eventBytes[index].time);
        }
        [pool release];
    }
    fclose(fp);
}
- (void) writeTimesToFile: (NSString *) file forKey: (NSString *) key 
{
	FILE	*fp;
	NSValue	*value;
	unsigned long	time;
	char	buf[MAXLENGTH];
	NSValueArray *timesArray = [self eventTimesForKey: key];
	NSEnumerator *enumerator = [timesArray objectEnumerator];
	
	if ([timesArray count]) {
		if ((fp = fopen ([file UTF8String], "w")) == NULL) {
			NSLog (@"Couldn't open %@ for writing\n", file);
			return;
		}
		while (value = [enumerator nextObject]) {
			[value getValue: &time];
			sprintf (buf,"%f\n",(float)time * TIME_SCALE);
			fprintf(fp,"%s", buf);
		}
		fclose (fp);
	}
}

@end
