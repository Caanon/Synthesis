
#import <AppKit/AppKit.h>
#import "XYPlotData.h"
#import <CoreServices/CoreServices.h>

void XYSetLineStyle(CGContextRef context,NSString *lineStyle);
void XYPlotLine(NSBezierPath *userPath,NSPoint oldPoint,NSPoint newPoint,NSString *plotStyle, float xoffset, float yoffset);

@interface XYPlotView:NSView
{
	XYPlotData		*plotData;
	NSMutableDictionary	*plotDictionary;
	NSMutableDictionary 	*curvesDictionary;
	NSMutableDictionary 	*dataDictionary;
	NSRect 			borderRect;
	NSRect 			plotRect;
	double			xoffset,yoffset;
	double			xscale,yscale;
	float 			defaultLineWidth;
	float			topMargin,bottomMargin,leftMargin,rightMargin;
	NSArray 		*lineColorsArray,*lineStylesArray,
            			*pointSymbolsArray;
	NSColor			*backgroundColor,*borderBoxColor;
	NSString 		*mainTitle;
	NSFont 			*mainTitleFont;
	BOOL			xLogScale,yLogScale;
	BOOL			colorDisplay,colorPrint,
            			printBackground,borderBox;
}

- initWithFrame:(NSRect)frameRect;
@end

@interface XYPlotView (XYPlotViewAPI)

- (void)plotFromFile:sender;
- (void)plotValues:(NSArray *)values;
- (void)plotValues:(NSArray *)x :(NSArray *)y;
- (void)addPlotWithValues:(NSArray *)values;
- (void)setMainTitle:(NSString *)title;
- (void)setXTitle:(NSString *)title;
- (void)setYTitle:(NSString *)title;
- (void)removeAllPlots:sender;
- (void)resetTemplateWithFile:(NSString *)path;
- (void)setPlotStyle:(NSString *)style;
- (void)setAutoScale:(BOOL)scale;

@end

@interface XYPlotView (XYPlotViewPrivate)
- (void)_scaleToView ;
- (void)_setup;
- (void)_setDrawingStateForCurve:(NSString *)curveKey;
- (void)_displayAxisForKey:(NSString *)axisKey;
- (void)_displayTitle;
- (void)_drawCurves;
@end


