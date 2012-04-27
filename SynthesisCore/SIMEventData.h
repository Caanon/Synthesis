/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <Foundation/Foundation.h>
#import <Desiderata/NSValueArray.h>
#import <stdio.h>
#import <string.h>
#import <stdlib.h>

#define MAXLENGTH		10000
#define MAXPIXELVALUE	 	255
#define SPIKE_EVENT		0x01
#define PLUS_EVENT		0x02
#define MINUS_EVENT	 	0x03
#define STIMULUS_EVENT	   	0x51
#define END_OF_FILE		0xFFFF
#define START_OF_DATA		"0,1,0"
#define END_OF_DATA		"0,2,2"
#define END_OF_DATA_ID		0x02
#define END_OF_DATA_TYPE	0x00
#define END_OF_FILE_STRING	"0,FFFF,0"
#define HEADER_DICT		@"Headers"
#define TIME_SCALE		0.001

typedef struct {
    unsigned int	type;
    unsigned int	unit;
    unsigned long	time;
    float		value;
} SIMEventStruct;

#define SIMNullEventStruct {0,0,0,0.0}

@class NSMutableDictionary;
@class NSDictionary;
@class NSMutableData;
@class NSString;
@class NSMutableArray;
@class NSArray;


@interface SIMEventData: NSObject
{
	NSMutableDictionary	*eventDict;
	NSMutableArray	*headerArray;
	unsigned long endDataTime;
}

+ (void)remapEvents:(NSMutableValueArray *)events toType:(unsigned int)type andUnit:(unsigned int)unit;
+ (void)remapEvents:(NSMutableValueArray *)events toTime:(unsigned long)startTime;
- initWithAbelesFormatFile: (NSString *) filename;
- initWithEventDict: (NSDictionary *) d headerArray: (NSArray *) e;
- copy;
- (NSMutableDictionary *) eventDictionary;
- (NSArray *) headerArray;
- (void) setEventDictionary: (NSDictionary *) e;
- (void) setHeaderArray: (NSArray *) h;
- (unsigned long) lastTime;
- (unsigned long) firstTimeForKey:(NSString *)key;
- (unsigned long) lastTimeForKey:(NSString *)key;
- (unsigned int) firstUnit;
- (unsigned int) lastUnit;
- (unsigned int) countForEvent:(SIMEventStruct *)event;
- (unsigned int) countForKey:(NSString *)key;
- (void) addEvent:(SIMEventStruct)event;
- (void) addEvent:(SIMEventStruct)event forKey:(NSString *)key;
- (void) removeEvent:(SIMEventStruct)event;
- (void) addSegment:(NSValueArray *)events;
- (void) addSegment:(NSValueArray *)events syncEvent:(SIMEventStruct *)syncEvent;
- (void) addSegment:(NSValueArray *)events remapEvent:(SIMEventStruct *)event 
	syncEvent:(SIMEventStruct *)syncEvent;
- (void) addSegments:(NSDictionary *)segments remapEvent:(SIMEventStruct *)event
    syncEvent:(SIMEventStruct *)syncEvent duration:(unsigned int)duration;
- (NSValueArray *) getSegment:(unsigned int)seg forEvent:(SIMEventStruct *)event 
	syncEvent:(SIMEventStruct *)sync
    duration:(unsigned int)duration;
- (NSDictionary *) getSegmentsForEvent:(SIMEventStruct *)event syncEvent:(SIMEventStruct *)sync
    duration:(unsigned int)duration;
- (float)meanFiringRateForEvent:(SIMEventStruct)event syncEvent:(SIMEventStruct)syncEvent
        duration:(unsigned int)duration;
- (SIMEventData *) mergeEventData:(SIMEventData *)eventData eventType:(unsigned int)type
    fromSyncEvent:(SIMEventStruct *)fromSync toSyncEvent:(SIMEventStruct *)toSync
    randomize:(BOOL)randFlag count:(unsigned int)count duration:(unsigned int)duration;
- (NSData *) rasterizeEvents:(SIMEventStruct *)event;
- (NSData *) rasterizeEvents:(SIMEventStruct *)event syncEvent:(SIMEventStruct *)sync 
	scanLength:(int)length scanRows:(int)rows;
- (NSValueArray *) eventTimesForKey: (NSString *) key;
- (NSValueArray *) eventsForKey:(NSString *)key;
- (NSArray *) eventKeys;
- (NSArray *) eventKeysSortedByCount;
- (NSArray *) headers;
- (void) writeAbelesFormatToFile: (NSString *) file;
- (void) writeTimesToFile:(NSString *)file;
- (void) writeTimesToFile: (NSString *) file forKey: (NSString *) key;
@end
