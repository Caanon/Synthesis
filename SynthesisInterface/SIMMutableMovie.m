/**
 *	filename: SIMMutableMovie.m
 *	created : Thu Apr  5 19:30:27 2001
 *	LastEditDate Was "Wed May 30 14:51:39 2001"
 *
 */

#if !__LP64__ // 64 bit quicktime doesn't exist

#import "SIMMutableMovie.h"

#import <unistd.h>
#import <fcntl.h>

#import <Carbon/Carbon.h>
#import <QuickTime/QuickTime.h>

#define TIME_SCALE 600

const long 		kVideoTimeScale 		= 600;
const short 		kSyncSample 		= 0;
const long 		kAddOneVideoSample 	= 1;
const TimeValue 	kSampleDuration 		= 60;	/* frame duration = 1/10 sec */
const TimeValue 	kTrackStart 			= 0;
const TimeValue 	kMediaStart 		= 0;
const OSType 	kMyCreatorType		= '????';


static BOOL WriteMovieToPath(Movie movie, NSString *path);
static OSErr MovieDrawingComplete(Movie theMovie, long refCon);

@implementation SIMMutableMovie

+ (SIMMutableMovie *)emptyMovie
{
    Movie movie;
    long int flags;

    flags = 0;
    flags |= newMovieActive;
    movie = NewMovie(flags);
    return [[[[self class] alloc] initWithMovie:movie] autorelease];
}

- initWithMovie:(void *)movie
{
    EnterMovies();
    return [super initWithMovie:movie];
}

- (void)setDelegate:(id)delegate
{
    if (delegate){
        SetMovieDrawingCompleteProc([self QTMovie],movieDrawingCallWhenChanged,MovieDrawingComplete,(long)self);
    }
    _delegate = delegate;
}

- delegate
{
    return _delegate;
}

- (void)dealloc
{
    [_notificationTimes release];
    [_posterImage release];
    [super dealloc];
}



- (NSImage *)posterImage
{
    if (_posterImage == nil){
        PicHandle       picHandle;
        int             imageSize;
        void           *picBytes;
        NSData         *data;
        NSPICTImageRep *imageRep;

        picHandle = GetMoviePosterPict([self QTMovie]);

        if (picHandle){
            imageSize = GetHandleSize((Handle)picHandle);
            picBytes  = (*picHandle);
            data         = [NSData dataWithBytes:picBytes length:imageSize];
            imageRep     = [NSPICTImageRep imageRepWithData:data];
            _posterImage = [[NSImage alloc] initWithSize:[imageRep size]];

                /* Convert the PIC image rep to a tiff image rep */
            [_posterImage lockFocus];
            [imageRep drawAtPoint:NSMakePoint(0,0)];
            [_posterImage unlockFocus];

            KillPicture(picHandle);
        }else{
            NSLog(@"Hey the movie doesn't have a PosterPic");
        }
    }
    return _posterImage;
}

- (BOOL)insertImage:(NSImage *)image
{
}

- (BOOL)insertImage:(NSImage *)image  sourceStartTime:(long int)srcIn
                                   sourceDurationTime:(long int)srcDuration
{
    OSErr                  err;
    Track                  newTrack;
    Media                  newMedia;
    MovieImportComponent   importer;
    NSData                *imageData;
    long int               dataSize;
    Handle                 imageHandle;
    ImageDescriptionHandle imageDescription;
    Handle                 dataHandle;
    Handle                 dataRef;

    imageData = [image TIFFRepresentation];
    dataSize = [imageData length];

    (void)PtrToHand([imageData bytes], &imageHandle, dataSize);

    newTrack = NewMovieTrack([self QTMovie],
                                (long)([image size].width) << 16, /* Convert long to Fixed */
                                (long)([image size].height) << 16, /* Convert long to Fixed */
                                kNoVolume);

    err = GetMoviesError();
    if (err != noErr){
        return NO;
    }

        /* Allocate some memory for the Track's Media otherwise there is no place to store
         * it. the dataRef should be a handle to a handle if its stored in memory
         */
    dataHandle = NewHandle(0);
    (void)PtrToHand(&dataHandle, &dataRef, sizeof(dataHandle));

    newMedia = NewTrackMedia (newTrack,		/* track identifier */
                                    VideoMediaType,		/* type of media */
                                    kVideoTimeScale, 	/* time coordinate system */
                                    dataRef,			/* data reference - use the file that is associated with the movie  */
                                    HandleDataHandlerSubType);			/* data reference type */

    //newMedia = NewTrackMedia(newTrack,VIDEO_TYPE,TIME_SCALE,dataRef,HandleDataHandlerSubType);
    err = GetMoviesError();
    if (err != noErr){
        return NO;
    }

    err = BeginMediaEdits(newMedia);
    err = OpenADefaultComponent(GraphicsImporterComponentType, kQTFileTypeTIFF, &importer);
    if (err != noErr){
        CloseComponent(importer);
        EndMediaEdits(newMedia);
        return NO;
    }

    err = GraphicsImportSetDataHandle(importer, imageHandle);
    if (err != noErr){
        return NO;
    }
    err = GraphicsImportGetImageDescription(importer, &imageDescription);
    if (err != noErr){
        return NO;
    }

    (*imageDescription)->dataSize = 0; /* Looks like its already set like this */
    
        err = AddMediaSample(newMedia,	/* media specifier */ 
            imageHandle,	/* handle to sample data - dataIn */
            0,		/* specifies offset into data reffered to by dataIn handle */
            dataSize, /* number of bytes of sample data to be added */ 
            kSampleDuration,		 /* frame duration = 1/10 sec */
            (SampleDescriptionHandle)imageDescription,	/* sample description handle */ 
            kAddOneVideoSample,	/* number of samples */
            kSyncSample,	/* control flag indicating self-contained samples */
            nil);		/* returns a time value where sample was insterted */


    //err = AddMediaSample(newMedia, imageHandle, 0, dataSize, TIME_SCALE*srcDuration,
    //                     (SampleDescriptionHandle)imageDescription, 1, 0, NULL);

    if (err != noErr){
        return NO;
    }

    DisposeHandle(imageHandle);
    DisposeHandle((Handle)imageDescription);

    err = EndMediaEdits(newMedia);
    
    
        err = InsertMediaIntoTrack (newTrack,		/* track specifier */
                [self movieDuration],	/* track start time */
                kMediaStart, 	/* media start time */
                GetMediaDuration(newMedia), /* media duration */
                fixed1);		/* media rate ((Fixed) 0x00010000L) */

    //err = InsertMediaIntoTrack(newTrack, [self movieDuration], 0, GetMediaDuration(newMedia), fixed1);
    if (err != noErr){
        return NO;
    }
    return YES;
}

- (long int)movieDuration
{
    return GetMovieDuration([self QTMovie]);
}

- (BOOL)insertMovie:(NSMovie *)newMovie sourceStartTime:(long int)srcIn
                                     sourceDurationTime:(long int)srcDuration
                                  destinationInsertTime:(long int)dstIn
{
    OSErr  err;

    err = InsertMovieSegment([newMovie QTMovie] /* src movie */,
                             [self QTMovie] /* dst movie */,
                             srcIn,srcDuration,
                             dstIn);
    if (err == noErr){
        return YES;
    }
    return NO;
}

- (BOOL)appendMovie:(SIMMutableMovie *)movie
{
    return [self insertMovie:movie sourceStartTime:0
                                sourceDurationTime:GetMovieDuration([movie QTMovie])
                             destinationInsertTime:GetMovieDuration([self QTMovie])];
}

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)value
{
        /* the atomically flag is ignored its always done atomically */
    return WriteMovieToPath([self QTMovie], path);
}

- (Track)firstVideoTrack
{
    return GetMovieIndTrackType([self QTMovie],
                                1, /* index */
                                kCharacteristicCanSendVideo, /* TrackType */
                                movieTrackCharacteristic|movieTrackEnabledOnly /* flags */);
}

- (Track)firstSoundTrack
{
    return GetMovieIndTrackType([self QTMovie],
                                1, /* index */
                                AudioMediaCharacteristic, /* TrackType */
                                movieTrackCharacteristic|movieTrackEnabledOnly /* flags */);
}

- (BOOL)replaceTrack:(Track)origTrack withTrack:(Track)replacementTrack
{
    OSErr     err;
    TimeValue originalTrackDuration;
    Track     newTrack;
    Handle    dataHandle;
    Handle    dataRef;

    originalTrackDuration = GetTrackDuration(origTrack);

    if (originalTrackDuration == 0){
        return NO;
    }

        /* Create a place to put the track data
         */
    dataHandle = NewHandle(0);
    (void)PtrToHand(&dataHandle, &dataRef, sizeof(dataHandle));

        /* Add an empty track to the movie, copying the parameters of the
         * original track in the movie
         */
    err = AddEmptyTrackToMovie(origTrack,[self QTMovie],
                               dataRef,HandleDataHandlerSubType,
                               &newTrack);

    if (err != noErr){
        DisposeHandle(dataHandle);
        return NO;
    }

    err = CopyTrackSettings(origTrack,newTrack);
    if (err != noErr){
        DisposeHandle(dataHandle);
        return NO;
    }

        /* Copy by reference the stuff from replacementTrack into
         * the newly inserted newTrack
         */
    err = InsertTrackSegment(replacementTrack,newTrack,0,originalTrackDuration,0);
    if (err != noErr){
        DisposeHandle(dataHandle);
        return NO;
    }

    DisposeHandle(dataHandle);
    DisposeMovieTrack(origTrack);
    return YES;
}

- (NSArray *)splitMovieAtTime:(long int)splitPoint
{
    SIMMutableMovie *movie1;
    SIMMutableMovie *movie2;
    NSMutableArray *movies;

    movie1 = [SIMMutableMovie emptyMovie];
    movie2 = [SIMMutableMovie emptyMovie];

    movies = [NSMutableArray array];
    [movies addObject:movie1];
    [movies addObject:movie2];

    [movie1 insertMovie:self sourceStartTime:0
                          sourceDurationTime:splitPoint
                       destinationInsertTime:0];


    [movie2 insertMovie:self sourceStartTime:splitPoint
                          sourceDurationTime:GetMovieDuration([self QTMovie])
                       destinationInsertTime:0];

    SetMoviePosterTime([movie1 QTMovie],0);
    SetMoviePosterTime([movie2 QTMovie],0);

    return movies;
}

- (void)_notifyDelegate
{
    [[self delegate] movieDrawingComplete:self];
}
@end


static BOOL WriteMovieToPath(Movie movie, NSString *path)
{
    OSErr    err;
    FSRef    fsRef;
    FSSpec   fsSpec;
    NSString *newPath;

    newPath = [NSString stringWithFormat:@"%@~",path];

    err = FSPathMakeRef([newPath fileSystemRepresentation],&fsRef, NULL /* isDirectory */);

        /* If the error is file not found then lets create it for it */
    if (err == fnfErr){
        int fd;

        fd = open([newPath fileSystemRepresentation],O_CREAT|O_RDWR,0600);
        if (fd < 0){
            return NO;
        }
        write(fd," ",1);
        close(fd);

        err = FSPathMakeRef([newPath fileSystemRepresentation],&fsRef, NULL /* isDirectory */);
    }

    if (err == noErr){
        err = FSGetCatalogInfo(&fsRef, kFSCatInfoNone, NULL /*catalogInfo*/, NULL /*outName*/, &fsSpec, NULL /*parentRef*/);

        if (err == noErr){
            short resId;

            FlattenMovie(movie,
                         flattenAddMovieToDataFork|flattenForceMovieResourceBeforeMovieData,
                         &fsSpec,'TVOD',
                         smSystemScript,
                         createMovieFileDeleteCurFile|createMovieFileDontCreateResFile,
                         &resId,nil);
            CloseMovieFile(resId);
        }
        rename([newPath fileSystemRepresentation],[path fileSystemRepresentation]);
        return YES;
    }
        /* Clean up here */
    unlink([newPath fileSystemRepresentation]);
    return NO;
}

static OSErr MovieDrawingComplete(Movie theMovie, long refCon)
{
    SIMMutableMovie *obj;

    obj = (id)refCon;
    [obj _notifyDelegate];
    return noErr;
}

void CopyNSImageToGWorld(NSImage *image, GWorldPtr gWorldPtr)
{
    NSArray 		*repArray;
    PixMapHandle 	pixMapHandle;
    Ptr 		pixBaseAddr;
    int			imgRepresentationIndex;

    // Lock the pixels
    pixMapHandle = GetGWorldPixMap(gWorldPtr);
    LockPixels (pixMapHandle);
    pixBaseAddr = GetPixBaseAddr(pixMapHandle);

    repArray = [image representations];
    for (imgRepresentationIndex = 0; imgRepresentationIndex < [repArray count]; ++imgRepresentationIndex)
    {
        NSObject *imageRepresentation = [repArray objectAtIndex:imgRepresentationIndex];
        
        if ([imageRepresentation isKindOfClass:[NSBitmapImageRep class]])
        {
            Ptr bitMapDataPtr = [(NSBitmapImageRep *)imageRepresentation bitmapData];

            if ((bitMapDataPtr != nil) && (pixBaseAddr != nil))
            {
                int i,j;
                int pixmapRowBytes = GetPixRowBytes(pixMapHandle);
                NSSize imageSize = [(NSBitmapImageRep *)imageRepresentation size];
                for (i=0; i< imageSize.height; i++)
                {
                    unsigned char *src = bitMapDataPtr + i * [(NSBitmapImageRep *)imageRepresentation bytesPerRow];
                    unsigned char *dst = pixBaseAddr + i * pixmapRowBytes;
                    for (j = 0; j < imageSize.width; j++)
                    {
                        *dst++ = 0;		// X - our src is 24-bit only
                        *dst++ = *src++;	// Red component
                        *dst++ = *src++;	// Green component
                        *dst++ = *src++;	// Blue component           
                    }
                }
            }
        }
    }
    UnlockPixels(pixMapHandle);
}

#endif
