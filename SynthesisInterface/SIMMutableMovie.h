/**
 *	filename: SIMMutableMovie.h
 *	created : Thu Apr  5 19:30:23 2001
 *	LastEditDate Was "Wed May 30 14:05:04 2001"
 *
 */

#if !__LP64__ // 64 bit quicktime does not exist

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

@interface SIMMutableMovie : NSMovie
{
@private
    NSImage        *_posterImage;
    id              _delegate;
    NSMutableArray *_notificationTimes;
}

+ (SIMMutableMovie *)emptyMovie;

- (void)setDelegate:(id)delegate;
- delegate;

- (NSImage *)posterImage;

- (BOOL)insertImage:(NSImage *)image  sourceStartTime:(long int)srcIn
                                   sourceDurationTime:(long int)srcDuration;

- (long int)movieDuration;

- (BOOL)insertMovie:(NSMovie *)newMovie sourceStartTime:(long int)srcIn
                                     sourceDurationTime:(long int)srcDuration
                                  destinationInsertTime:(long int)dstIn;

- (BOOL)appendMovie:(SIMMutableMovie *)movie;

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)value;

- (Track)firstVideoTrack;
- (Track)firstSoundTrack;
- (NSArray *)splitMovieAtTime:(long int)splitPoint;
- (BOOL)replaceTrack:(Track)origTrack withTrack:(Track)newTrack;

- (void)_notifyDelegate;
@end

@interface NSObject(SIMMutableMovieDelegate)
- (void)movieDrawingComplete:(SIMMutableMovie*)movie;
@end

#endif
