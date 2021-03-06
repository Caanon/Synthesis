
/* Generated by Interface Builder */

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#ifndef M_PI
        #define M_PI	3.14159265358979323846
#endif

#define	MAX_PIXEL_8BIT	255
#define POS_INFINITY	(1.0/0.0)
#define NEG_INFINITY	(-1.0/0.0)
#define IS_NAN(x)	((x)!=(x))	/* IEEE test for NAN (not a number) */
#define IS_STRANGE(x)	(IS_NAN(x) || x == POS_INFINITY || x == NEG_INFINITY)

@interface SIMDataView:NSView
{
	NSData			*dataObject;
	NSRect			border;
	//unsigned char		**imageData;
	unsigned char 		*imageData[5];
	BOOL			PRINTINVERSE, preserveAspectRatio,autoScale,swapBytesFlag,imageSmoothingFlag;
	float			printWidth, printHeight;
	NSBitmapImageRep	*tiff;
	int				tiffWidth,tiffHeight;
	int				tiffInverse;
	float			dataMin,dataMax,scale;
	NSPoint			elementLoc;
	float			refValue;  // AKH
}

- initSize:(int)xsize :(int)ysize;
- (void) setData:(NSData *)dataptr;
- (void) setData:(NSData *)dataptr byteOrder:(unsigned)byteOrder;
- (NSPoint) selectedPoint;
- setHeight:(int)number;
- setWidth:(int)number;
- setMin:(float)number;
- setMax:(float)number;
- setMin:(float)min andMax:(float)max;
- (float)min;
- (float)max;
- setPreserveAspectRatio:(BOOL)state;
- setAutoScale:(BOOL)state;
- setImageSmoothing:(BOOL)smooth;
- toggleAutoScale:sender;
- togglePreserveAspectRatio:sender;
- (void) setReferenceValue: (float) val;  // AKH
- (void) saveTIFFToFile:(NSString *)filename;
- (NSBitmapImageRep *)bitmapImageRep;

- (void)_setAutoScale;

@end
