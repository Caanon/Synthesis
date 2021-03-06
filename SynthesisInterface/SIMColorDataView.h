
/* Generated by Interface Builder */

#import "SIMDataView.h"
#import <Foundation/Foundation.h>

#define	SIM_COLOR_PALETTE_HSB		0
#define	SIM_COLOR_PALETTE_RGB		1
#define	SIM_COLOR_PALETTE_BASELINE	2
#define	SIM_COLOR_PALETTE_SYNTH		3
#define	SIM_COLOR_PALETTE_LIST		4

@interface SIMColorDataView:SIMDataView
{
	unsigned char		**colorTable;
	NSBitmapImageRep 	*colorScale;
	float 			colorbarWidth,colorbarInset,colorbarOffset;
	BOOL 			hasColorBar;
	NSRect			colorbarBorder;
	NSFont			*colorbarFont;
	double			rContrast,rFreq,rPhase;
	double			gContrast,gFreq,gPhase;
	double			bContrast,bFreq,bPhase;
	float			baselineValue;
	unsigned int		colorPaletteMode;
	NSColor			*startColor,*endColor,*baselineColor;
}

- initSize:(int)xsize :(int)ysize;

- (void)setColorPaletteFromColorListWithName:(NSString *)listName;
- (void)setColorPaletteFromColorList:(NSColorList *)cList;

- (void)handleColorListChangedNotification:(NSNotification *)n;
- (void)_recalcRects;
- (void)_setColorScale;
- (void)setHSBPalette;
- (void)setSYNTHPalette;
- (void)setBaselineValue:(float)baselineValue withColor:(NSColor *)baselineColor minColor:(NSColor *)minColor
    maxColor:(NSColor *)maxColor;
- (void)setRGBStartColor:(NSColor *)startColor endColor:(NSColor *)endColor;
- (void)setHSBStartColor:(NSColor *)startColor endColor:(NSColor *)endColor;
- (void)shiftPaletteDown;
- (void)shiftPaletteUp;
- setColorPaletteMode:sender;
- toggleColorBar:sender;
- cyclePaletteUp:sender;
- cyclePaletteDown:sender;
- setStartColor:sender;
- setEndColor:sender;
- setBaselineColor:sender;
- takeBaselineValueFromSender:sender;
- setRedPhase:sender;
- setGreenPhase:sender;
- setBluePhase:sender;
- setRedFrequency:sender;
- setGreenFrequency:sender;
- setBlueFrequency:sender;
- setRedContrast:sender;
- setGreenContrast:sender;
- setBlueContrast:sender;
- setHSBStartColor:sender;
- setHSBEndColor:sender;
- setRGBStartColor:sender;
- setRGBEndColor:sender;

@end
