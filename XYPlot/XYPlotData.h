#import <Foundation/Foundation.h>
#import <stdio.h>
#import <Desiderata/NSValueArray.h>
#import "XYCategories.h"

#define UNTITLED_NAME				@"Untitled"
#define	PLOT_RECT				@"PlotRect"
#define	TOP_MARGIN				@"TopMargin"
#define	BOTTOM_MARGIN				@"BottomMargin"
#define	TOP_MARGIN				@"TopMargin"
#define	LEFT_MARGIN				@"LeftMargin"
#define	RIGHT_MARGIN				@"RightMargin"
#define	POINT_SYMBOLS				@"PointSymbols"
#define	LINE_STYLES				@"LineStyles"
#define	LINE_COLORS				@"LineColors"
#define	LINE_STYLE				@"LineStyle"
#define	LINE_WIDTH				@"LineWidth"
#define LINE_COLOR				@"LineColor"
#define	BACKGROUND_COLOR 			@"BackgroundColor"
#define	COLOR_DISPLAY				@"ColorDisplay"
#define	COLOR_PRINT				@"ColorPrint"
#define	PRINT_BACKGROUND 			@"PrintBackground"
#define	BORDER_BOX				@"BorderBox"
#define	BORDERBOX_COLOR				@"BorderBoxColor"
#define	PLOT_STYLE				@"PlotStyle"
#define	PLOT_XAXIS				@"XAxis"
#define	PLOT_YAXIS				@"YAxis"
#define	TITLE					@"Title"
#define	TITLE_FONT				@"TitleFont"
#define	TITLE_COLOR				@"TitleColor"
#define	CURVES_DICT				@"Curves"
#define	CURVES_DATA				@"Data"
#define DATA_DICT				@"_Data"

// Axis defines
#define	X_AXIS				@"XAxis"
#define	Y_AXIS				@"YAxis"
#define	AXIS_COLOR			@"AxisColor"
#define	AXIS_FORMAT			@"AxisFormat"
#define	LABEL_FONT			@"LabelFont"
#define LABEL_FORMAT			@"LabelFormat"
#define	AUTOSCALE_FONTS			@"AutoScaleFonts"
#define	AUTO_TICKS			@"AutoTicks"
#define	TICK_FONT			@"TickFont"
#define TICK_FORMAT			@"TickFormat"
#define	TICK_LABELS			@"TickLabels"
#define	TICK_VALUES			@"TickValues"
#define	AUTO_SCALE			@"AutoScale"
#define	MINIMUM				@"Minimum"
#define	MAXIMUM				@"Maximum"
#define	MAJORTICK_INC			@"MajorTickIncrement"
#define	MINORTICK_INC			@"MinorTickIncrement"
#define	MAJORTICK_SIZE			@"MajorTickSize"
#define	MINORTICK_SIZE			@"MinorTickSize"
#define	GRID				@"Grid"
#define	GRID_COLOR			@"GridColor"
#define	GRID_STYLE			@"GridStyle"
#define	LOG_SCALE			@"LogScale"
#define	AXIS_SCALE			@"AxisScale"	// linear, log, or custom

// LineStyles defines
#define SOLID				@"Solid"
#define SHORTDASH			@"ShortDash"
#define	LONGDASH			@"LongDash"
#define	DOT				@"Dot"
#define	DOTSHORT			@"DotShort"
#define	LONGSHORT			@"LongShort"
#define	CHAINDASH			@"ChainDash"
#define	CHAINDOT			@"ChainDot"

// PlotStyle defines
#define	STEPPED_PLOT		@"Stepped"
#define	LINEAR_PLOT			@"Linear"
#define	BAR_PLOT			@"Bar"
#define	FILLEDBAR_PLOT		@"FilledBar"


#define XYDouble			ML_DOUBLE
#define XYFloat				ML_FLOAT
#define XYInt				ML_INT
#define XYShort				ML_SHORT
#define	XYUnsignedShort			ML_USHORT
#define XYUnsignedChar			ML_UCHAR
#define XYNumbers			ML_NUM
#define XYText				ML_TEXT

void computeNiceLinInc(float *pmin, float *pmax, float *pinc);


@interface XYPlotData : NSObject
{
	NSMutableDictionary *dataDictionary;
	NSMutableDictionary *attributesDictionary;
}
- init;
- initWithDescription:(NSData *)description;
- initWithFile:(NSString *)path;
- initWithPlainFile:(NSString *)path
;
- initWithString:(NSString *)stringData;
- initWithMatlabFile:(NSString *)path;
- (NSNumber *)maxValueForKey:(NSString *)key;
- (NSNumber *)minValueForKey:(NSString *)key;
- (NSNumber *)maxValueForKeys:(NSArray *)keys;
- (NSNumber *)minValueForKeys:(NSArray *)keys;
- (NSArray *)valuesForKey:(NSString *)key;
- (void)addContentsOfPlainFile:(NSString *)path;
- (void)addValuesFromString:(NSString *)stringData name:(NSString *)name
;
- (NSDictionary *)valuesFromString:(NSString *)stringData name:(NSString *)name;
- (void)setValues:(NSArray *)values forKey:(NSString *)key;

// Reference values are n integer values from 0..n-1, where n is the 
// number of values in the data array referred to by key
- (NSArray *)referenceValuesForKey:(NSString *)key;
- (void)updateTicksForAxis:(NSString *)axisKey;
- (void)updateAttributesDictionary;
- (NSMutableDictionary *)attributesDictionary;
- (NSMutableDictionary *)curvesDictionary;
- (NSMutableDictionary *)dataDictionary
;
// See template file XYPlot.template for example dictionaries
- (void)addAttributes:(NSDictionary *)dict;
- (void)removeAllCurves;
- (void)removeAllData;
- (void)addCurves:(NSDictionary *)dict;
- (void)addCurves:(NSArray *)curves forKey:key;
- (void)addData:(NSArray *)data forKey:key;
- (void)setCurves:(NSArray *)curves forKey:key;
- (void)setData:(NSArray *)data forKey:key;
- (void)addData:(NSDictionary *)dict;
- (void)setDataDictionary:(NSDictionary *)dict;
- (void)setCurvesDictionary:(NSDictionary *)dict;
- (void)setAttributesDictionary:(NSDictionary *)dict;
- (unsigned)count;
@end
