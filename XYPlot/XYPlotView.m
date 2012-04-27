
#import "XYPlotView.h"
#import <SynthesisCore/SIMCategories.h>

static NSRect regionFromCorners(NSPoint p1, NSPoint p2);

@implementation XYPlotView

#define MAX_UPATH	4096
#define	SMALL		.1
#define MINHEIGHT	.1
#define MINWIDTH	.1


- initWithFrame:(NSRect)frameRect
{
	[super initWithFrame:frameRect];

	plotData = [[XYPlotData alloc] init];

	[self _setup];
	[self _scaleToView];
        
	return self;
}

- (void)resetTemplateWithFile:(NSString *)path
{
    id curves = [[plotData curvesDictionary] retain];
    id data = [[plotData dataDictionary] retain];
    [plotData release];
    plotData = [[XYPlotData alloc] initWithFile:path];
    [plotData setDataDictionary:data];
    [plotData setCurvesDictionary:curves];
    [self _setup];
    [self _scaleToView];
    [self setNeedsDisplay:YES];
}

- (void)_scaleToView
{

    borderRect = [self bounds];

    borderRect.origin.x += leftMargin;;
    borderRect.origin.y += bottomMargin;
    borderRect.size.width -= (rightMargin+leftMargin);
    borderRect.size.height -= (topMargin+bottomMargin);
  

 /*
  * First we figure out how much we need to scale so that our current graph
  * will just fit within the view.
  */
    if (NSWidth(plotRect) == 0 || NSHeight(plotRect) == 0){
        xscale = 1;
        yscale = 1;
    }
    else {
    yscale = NSHeight(borderRect) / NSHeight(plotRect);
    xscale = NSWidth(borderRect) / NSWidth(plotRect);
    }

    xoffset = NSMinX(borderRect)-NSMinX(plotRect)*xscale;
    yoffset = NSMinY(borderRect)-NSMinY(plotRect)*yscale;

}

- (void)_setup
{
	plotDictionary = [plotData attributesDictionary];

	curvesDictionary = [plotDictionary objectForKey:CURVES_DICT];

	plotRect = [plotDictionary rectForKey:PLOT_RECT];

	topMargin = [plotDictionary floatForKey:TOP_MARGIN];
	leftMargin = [plotDictionary floatForKey:LEFT_MARGIN];;
	bottomMargin = [plotDictionary floatForKey:BOTTOM_MARGIN];
	rightMargin = [plotDictionary floatForKey:RIGHT_MARGIN];

	defaultLineWidth = [plotDictionary floatForKey:LINE_WIDTH];

	mainTitle = [plotDictionary objectForKey:TITLE];
	mainTitleFont = [plotDictionary fontForKey:TITLE_FONT];

	pointSymbolsArray = [plotDictionary objectForKey:POINT_SYMBOLS];
	lineStylesArray = [plotDictionary objectForKey:LINE_STYLES];
	lineColorsArray = [plotDictionary objectForKey:LINE_COLORS];
	backgroundColor = [plotDictionary colorForKey:BACKGROUND_COLOR];
	colorDisplay = [plotDictionary boolForKey:COLOR_DISPLAY];
	colorPrint = [plotDictionary boolForKey:COLOR_PRINT];
	printBackground = [plotDictionary boolForKey:PRINT_BACKGROUND];
	borderBox = [plotDictionary boolForKey:BORDER_BOX];
	borderBoxColor = [plotDictionary colorForKey:BORDERBOX_COLOR];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint startLoc,mouseLoc;
    CGRect zoomRect;
    NSRect cacheRect;
    NSWindow *currentWindow = [self window];
    NSMutableDictionary *axisDictionary;
    CGContextRef graphCtx = [[NSGraphicsContext currentContext] graphicsPort];

    unsigned int eventMask;

    if (![currentWindow makeFirstResponder:self]) return;

    if ([theEvent modifierFlags] & (NSShiftKeyMask))  {
            // print if shift key pressed while clicking
            [self print: self];
            return;
    }

    if ([theEvent modifierFlags] & NSCommandKeyMask)  {
            // zoom out if command key pressed while clicking
            [self setAutoScale:YES];
            [self _setup];
            [plotData updateAttributesDictionary];
            [self _scaleToView];
            [self setNeedsDisplay:YES];
            return;
    }

    startLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    cacheRect = [self convertRect:[self bounds] toView:nil];
    [currentWindow cacheImageInRect:cacheRect];

    eventMask = NSLeftMouseDraggedMask | NSLeftMouseUpMask ;
    while (theEvent = [currentWindow nextEventMatchingMask:eventMask]){
        mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];

        zoomRect.origin.x = startLoc.x;
        zoomRect.origin.y = startLoc.y;
        zoomRect.size.width = mouseLoc.x-startLoc.x;
        zoomRect.size.height = mouseLoc.y-startLoc.y;

        if(zoomRect.size.height < 0){
            zoomRect.size.height = -zoomRect.size.height;
            zoomRect.origin.y = startLoc.y - zoomRect.size.height;
        }
        if(zoomRect.size.width < 0){
            zoomRect.size.width = -zoomRect.size.width;
            zoomRect.origin.x = startLoc.x - zoomRect.size.width;
        }

        plotRect.origin.x = (zoomRect.origin.x-xoffset)/xscale;
        plotRect.origin.y = (zoomRect.origin.y-yoffset)/yscale;
        plotRect.size.width = zoomRect.size.width/xscale;
        plotRect.size.height = zoomRect.size.height/yscale;

        if(plotRect.size.width<MINWIDTH)plotRect.size.width = MINWIDTH;
        if(plotRect.size.height<MINHEIGHT)plotRect.size.height = MINHEIGHT;

        switch ([theEvent type]) {
            case NSLeftMouseDragged:
            [self lockFocus];
            CGContextSetLineWidth(graphCtx,1.0); //PSsetlinewidth(1.0);
            XYSetLineStyle(graphCtx,DOT);
            CGContextSetGrayStrokeColor(graphCtx,NSDarkGray,1.0);
            CGContextStrokeRect(graphCtx,zoomRect);
            [self unlockFocus];
            [currentWindow flushWindowIfNeeded];
            [currentWindow restoreCachedImage];
            break;

            case NSLeftMouseUp:
            axisDictionary = [[plotData attributesDictionary] objectForKey: PLOT_XAXIS];
            [axisDictionary setFloat: NSMinX(plotRect)
                forKey: MINIMUM];
            [axisDictionary setFloat: NSMaxX(plotRect)
                forKey: MAXIMUM];
            axisDictionary = [[plotData attributesDictionary] objectForKey: PLOT_YAXIS];
            [axisDictionary setFloat: NSMinY(plotRect)
                forKey: MINIMUM];
            [axisDictionary setFloat: NSMaxY(plotRect)
                forKey: MAXIMUM];
            [self setAutoScale:NO];
            [plotData updateAttributesDictionary];
            [self _scaleToView];
            [self setNeedsDisplay:YES];

            return;

            default:
            break;
        }
    }


    return;
}

- (void)drawRect: (NSRect)rect
{
	NSRect	border;
        CGContextRef graphCtx = [[NSGraphicsContext currentContext] graphicsPort];
        //CGContextSetShouldAntialias(graphCtx,0);
        
	[self _setup];

	border = [self bounds];
	
        if([[NSGraphicsContext currentContext] isDrawingToScreen] || printBackground){
            [[NSColor whiteColor] set];
            //[[NSColor redColor] set];
            NSRectFill(border);
        }

    
        CGContextSetGrayStrokeColor(graphCtx,NSBlack,1.0);
        CGContextSetMiterLimit(graphCtx,1);

	if([plotData count]){
            [self _displayAxisForKey:X_AXIS];
            [self _displayAxisForKey:Y_AXIS];

            [[NSGraphicsContext currentContext] saveGraphicsState];
            NSRectClip(borderRect);
            [self _drawCurves];
            [[NSGraphicsContext currentContext] restoreGraphicsState];
            
        }

	[self _displayTitle];

        if(borderBox){
                [borderBoxColor set];
                XYSetLineStyle(graphCtx,SOLID);
                CGContextSetLineWidth(graphCtx,1.0);
                [NSBezierPath strokeRect:borderRect];
        }
}

- (void)_drawCurves
{
	NSString *curveKey;
	NSPoint oldPoint;
	NSEnumerator *curveEnumerator = [curvesDictionary keyEnumerator];

	while(curveKey = [curveEnumerator nextObject]){
                NSBezierPath *userPath = [[NSBezierPath alloc] init];

		NSDictionary *curveDict = [curvesDictionary objectForKey:curveKey];
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSArray *curveArray = [curveDict objectForKey:CURVES_DATA];
		NSArray *xDataArray = [plotData valuesForKey:[curveArray objectAtIndex:0]];
		NSArray *yDataArray = [plotData valuesForKey:[curveArray objectAtIndex:1]];
		NSEnumerator *xEnumerator = [xDataArray objectEnumerator];
		NSEnumerator *yEnumerator = [yDataArray objectEnumerator];
		NSNumber *xValue=[xEnumerator nextObject];
		NSNumber *yValue=[yEnumerator nextObject];
		NSString *plotStyle;

		if(xLogScale) oldPoint.x= xscale*log10([xValue floatValue])+xoffset;
		else oldPoint.x= xscale*[xValue floatValue]+xoffset;
		if(yLogScale) oldPoint.y = yscale*log10([yValue floatValue])+yoffset;
		else oldPoint.y = yscale*[yValue floatValue]+yoffset;

		if(!(plotStyle = [curveDict objectForKey:PLOT_STYLE]))
			plotStyle = [plotDictionary objectForKey:PLOT_STYLE];

//    	PSnewpath();
        //[userPath beginUserPath:NO];

        /*PSmoveto(xscale*[xValue floatValue]+xoffset, yscale*[yValue floatValue]+yoffset);*/
        [userPath moveToPoint:NSMakePoint(xscale*[xValue floatValue]+xoffset,yscale*[yValue floatValue]+yoffset)];
		while((xValue=[xEnumerator nextObject]) &&
			  (yValue=[yEnumerator nextObject])){
				NSAutoreleasePool *subpool = [[NSAutoreleasePool alloc] init];
				NSPoint newPoint;

				if(xLogScale) newPoint.x= xscale*log10([xValue floatValue])+xoffset;
				else newPoint.x= xscale*[xValue floatValue]+xoffset;
				if(yLogScale) newPoint.y = yscale*log10([yValue floatValue])+yoffset;
				else newPoint.y = yscale*[yValue floatValue]+yoffset;

				XYPlotLine(userPath,oldPoint,newPoint,plotStyle,xoffset,yoffset);

/*
            if([userPath numberOfPoints] >= MAX_UPATH){
                [userPath closepath];	// close path
                [userPath endUserPath:dps_stroke];
                [userPath sendUserPath];
            }
*/
                    oldPoint.x = newPoint.x;
                    oldPoint.y = newPoint.y;
                    [subpool release];
		}
                [self _setDrawingStateForCurve:curveKey];

		if([plotStyle isEqual:FILLEDBAR_PLOT])
                    [userPath fill];	// close user path and specify operator
                else [userPath stroke];

                //[userPath sendUserPath];
		[pool release];
	}
}

- (void)_displayTitle
{
	float	width,height;

	if (mainTitle){
        // These two text functions were deprecated in 10.4 and it'd take a whole lot to re-engineer them
        height = 10;
        width = 10;
		//height = [mainTitleFont defaultLineHeightForFont];
		//width = [mainTitleFont widthOfString:mainTitle];
                [mainTitleFont set];
                [[plotDictionary colorForKey:TITLE_COLOR] set];
                [mainTitle drawAtPoint:NSMakePoint(NSMidX(borderRect)-width*.5, NSMaxY(borderRect)+(topMargin*.5)-height/6.0) withAttributes:nil];
		//PSshow([mainTitle cString]);
	}
}


- (void)_setDrawingStateForCurve:(NSString *)curveKey
{
        NSDictionary *curveDict = [curvesDictionary objectForKey:curveKey];
        int index = [[curvesDictionary allKeys] indexOfObject:curveKey];
        NSColor *curveColor;
        NSString *colorString;
        NSString *lineStyle,*lineWidth;
        CGContextRef graphCtx = [[NSGraphicsContext currentContext] graphicsPort];

        if(([[NSGraphicsContext currentContext] isDrawingToScreen] && colorDisplay) || 
           (![[NSGraphicsContext currentContext] isDrawingToScreen] && colorPrint)){
		if(colorString = [curveDict objectForKey:LINE_COLOR])
                	curveColor = [colorString colorValue];
        	else
			curveColor = [[lineColorsArray objectAtIndex:
		       		index%[lineColorsArray count]] colorValue];
     		      [curveColor set];
	}
        if(!(lineStyle = [curveDict objectForKey:LINE_STYLE]))
                lineStyle = [lineStylesArray objectAtIndex:
                        index%[lineStylesArray count]];
        XYSetLineStyle(graphCtx,lineStyle);

        if(lineWidth = [curveDict objectForKey:LINE_WIDTH])
                CGContextSetLineWidth(graphCtx,[lineWidth floatValue]);
        else CGContextSetLineWidth(graphCtx,defaultLineWidth);

}


- (void)_displayAxisForKey:(NSString *)axisKey
{
        CGContextRef graphCtx = [[NSGraphicsContext currentContext] graphicsPort];
	NSMutableDictionary *axisDictionary=
        [plotDictionary objectForKey:axisKey];
	NSString *title = [axisDictionary objectForKey:TITLE]; 
        NSFont *titleFont = [axisDictionary fontForKey:TITLE_FONT];
	//BOOL scaleFonts = [axisDictionary boolForKey:SCALE_FONTS]; 
	BOOL grid = [axisDictionary boolForKey:GRID];
	NSColor *gridColor = [axisDictionary colorForKey:GRID_COLOR];
	NSString *gridStyle = [axisDictionary objectForKey:GRID_STYLE];
	float lineWidth = [axisDictionary floatForKey:LINE_WIDTH];
	//int axisScale = [axisDictionary intForKey: LOG_SCALE];
	NSFont *axisFont = [axisDictionary fontForKey:TICK_FONT];
	NSMutableArray *tickLabels = [axisDictionary objectForKey:TICK_LABELS];
	NSMutableArray *tickValues = [axisDictionary objectForKey:TICK_VALUES];
	float majorTickSize = [axisDictionary floatForKey:MAJORTICK_SIZE];
	//float minorTickSize = [axisDictionary floatForKey:MINORTICK_SIZE];
	float height,width;
	NSString *colorString;
	NSColor *titleColor;

	if(colorString = [axisDictionary objectForKey:TITLE_COLOR])
		titleColor = [colorString colorValue];
	else titleColor = [plotDictionary colorForKey:TITLE_COLOR];
        [titleColor set];
    // Dirty hack to make it compile
    height = 10;
    width = 10;
	//height = [titleFont defaultLineHeightForFont];
	//width = [titleFont widthOfString:title];
	[titleFont set];

        if([axisKey isEqual:Y_AXIS]){
            NSPoint aPoint = NSMakePoint(NSMidY(borderRect)-width*.5,leftMargin - height - NSMinX(borderRect));
            [[NSGraphicsContext currentContext] saveGraphicsState];
            CGContextRotateCTM([[NSGraphicsContext currentContext] graphicsPort],1.570796327);	// 90 deg = 1.57 rads		
            [title drawAtPoint:aPoint withAttributes:nil];
            [[NSGraphicsContext currentContext] restoreGraphicsState];
        }

        if([axisKey isEqual:X_AXIS]){
            NSPoint aPoint = NSMakePoint(NSMidX(borderRect)-width*.5,
                     NSMinY(borderRect)-(bottomMargin*.5)-height);
            [title drawAtPoint:aPoint withAttributes:nil];
        }
                 
	if ([tickValues count]) {
		// draw tick marks
		NSEnumerator *venumerator = [tickValues objectEnumerator];
		NSEnumerator *lenumerator = [tickLabels objectEnumerator];
		NSString *aLabel;
		NSNumber *aValue;
		NSColor *axisColor;

		if (colorString = [axisDictionary objectForKey:AXIS_COLOR])
			axisColor = [colorString colorValue];
		else axisColor = [plotDictionary colorForKey: AXIS_COLOR];
		
        // Dirty hack just to make it compile in 64 bit mode
        height = 10;
        width = 10;
		//height = [axisFont defaultLineHeightForFont];
		//width = [axisFont widthOfString:title];
		[axisFont set];
                CGContextSetLineWidth(graphCtx,lineWidth);

		if(grid){
			[gridColor set];
			XYSetLineStyle(graphCtx,gridStyle);
		}
		else {
			[axisColor set];
			XYSetLineStyle(graphCtx,SOLID);
		}
		// major ticks
		while ((aValue = [venumerator nextObject]) &&
			(aLabel = [lenumerator nextObject])) {
                        NSPoint aPoint;
                        
			if([axisKey isEqual:X_AXIS]){
                            float value = (xscale*[aValue floatValue]+xoffset);
                            if(grid){
                                CGContextMoveToPoint(graphCtx,value,NSMinY(borderRect));
                                [gridColor set];
                                XYSetLineStyle(graphCtx,gridStyle);
                                CGContextAddLineToPoint(graphCtx,value,NSMaxY(borderRect));
                            }
                            else {
                                CGContextMoveToPoint(graphCtx,value,NSMinY(borderRect)-majorTickSize*0.5);
                                //PSrmoveto(0.0,-majorTickSize*.5);
                                CGContextAddLineToPoint(graphCtx,value,NSMinY(borderRect)+majorTickSize*0.5);
                                //PSrlineto(0.0,majorTickSize);
                            }
                            CGContextStrokePath(graphCtx);
                // This method was deprecated in 10.4
                //CGFloat hackwidth = [axisFont widthOfString:aLabel];
                float hackWidth = 10.0f;
                
                            aPoint = NSMakePoint(xoffset+xscale*[aValue floatValue] - 
                                    hackWidth*.5,
                                    NSMinY(borderRect)-height*1.5);
			}
			if([axisKey isEqual:Y_AXIS]){
                            float value = (yscale*[aValue floatValue]+yoffset);
                            if(grid){
                                [gridColor set];
                                XYSetLineStyle(graphCtx,gridStyle);
                                CGContextMoveToPoint(graphCtx,NSMinX(borderRect),value);
                                CGContextAddLineToPoint(graphCtx,NSMaxX(borderRect),value);
                            }
                            else {
                                CGContextMoveToPoint(graphCtx,NSMinX(borderRect)-majorTickSize*.5,value);
                                CGContextAddLineToPoint(graphCtx,NSMinX(borderRect)+majorTickSize*.5,value);
                            }
                            CGContextStrokePath(graphCtx);
                // This method was deprecated in 10.4
                //CGFloat hackwidth = [axisFont widthOfString:aLabel];
                float hackWidth = 10.0f;
                            aPoint = NSMakePoint(borderRect.origin.x -hackWidth - 10.0,
                                    yoffset+yscale*[aValue floatValue]-height/2.0);
                        }
                    //[titleColor set];
                    [aLabel drawAtPoint:aPoint withAttributes:nil];
		}
	}
}

- (void)setFrameSize:(NSSize)size {
    [super setFrameSize:size];
    [self _scaleToView];
}


- (void)dealloc
{
    [plotData release];
    return [super dealloc];
}


- initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];

    NS_DURING
    plotData = [[coder decodeObject] retain];
    NS_HANDLER
    NSLog([localException name]);
    NSLog([localException reason]);
    NS_ENDHANDLER
    [self _setup];
    [self _scaleToView];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];

    NS_DURING
    [coder encodeObject:plotData];
    NS_HANDLER
    NSLog([localException name]);
    NSLog([localException reason]);
    NS_ENDHANDLER
}

@end

void XYSetLineStyle(CGContextRef ctx,NSString *lineStyle)
{
	float pattern0[] = {};	/* solid      */
	float pattern1[] = {3.5, 3.5}; /* short dash */
	float pattern2[] = {7.0, 7.0}; /* long dash  */
	float pattern3[] = {1.0, 3.0}; /* dot        */
	float pattern4[] = {1.0, 7.0, 3.0, 3.0}; /* dot short */
	float pattern5[] = {7.0, 7.0, 4.5, 4.5}; /* long short */
	float pattern6[] = {7.0, 3.0, 3.0, 3.0}; /* chain dash */
	float pattern7[] = {7.0, 4.0, 1.0, 4.0}; /* chain dot  */

        CGContextSetLineDash(ctx, 0.0, pattern0, 0);

        if([lineStyle isEqual:SOLID]) CGContextSetLineDash(ctx, 0.0, pattern0, 0); //PSsetdash(pattern0, 0, 0.0);
        else if([lineStyle isEqual:SHORTDASH]) CGContextSetLineDash(ctx, 0.0, pattern1, 2); //PSsetdash(pattern1, 2, 0.0);
        else if([lineStyle isEqual:LONGDASH]) CGContextSetLineDash(ctx, 0.0, pattern2, 2); //PSsetdash(pattern2, 2, 0.0);
        else if([lineStyle isEqual:DOT]) CGContextSetLineDash(ctx, 0.0, pattern3, 2); //PSsetdash(pattern3, 2, 0.0);
        else if([lineStyle isEqual:DOTSHORT]) CGContextSetLineDash(ctx, 0.0, pattern4, 4); //PSsetdash(pattern4, 4, 0.0);
        else if([lineStyle isEqual:LONGSHORT]) CGContextSetLineDash(ctx, 0.0, pattern5, 4); //PSsetdash(pattern5, 4, 0.0);
        else if([lineStyle isEqual:CHAINDASH]) CGContextSetLineDash(ctx, 0.0, pattern6, 4); //PSsetdash(pattern6, 4, 0.0);
        else if([lineStyle isEqual:CHAINDOT]) CGContextSetLineDash(ctx, 0.0, pattern7, 4); //PSsetdash(pattern7, 4, 0.0);
}

void XYPlotLine(NSBezierPath *userPath,NSPoint oldPoint,NSPoint newPoint,NSString *plotStyle,float xoffset,float yoffset)
{
	if([plotStyle isEqual:STEPPED_PLOT]){
/*
		PSlineto(x,oldy);
		PSlineto(x,y);
*/
        [userPath lineToPoint:NSMakePoint(newPoint.x,oldPoint.y)];
        [userPath lineToPoint:newPoint];
	}
	else
	if([plotStyle isEqual:LINEAR_PLOT]){
//		PSlineto(x,y);
            [userPath lineToPoint:newPoint];
	}	
	else
    if([plotStyle isEqual:BAR_PLOT] || [plotStyle isEqual:FILLEDBAR_PLOT]){
/*		
		PSlineto(x,oldy);
		PSlineto( x,yoffset);
		PSrlineto( oldx-x,0);
		PSmoveto( x,yoffset);
		PSlineto( x,y);
*/
        [userPath lineToPoint:NSMakePoint(newPoint.x,oldPoint.y)];
        [userPath lineToPoint:NSMakePoint(newPoint.x,yoffset)];
        [userPath relativeLineToPoint:NSMakePoint(oldPoint.x - newPoint.x,0)];
        [userPath moveToPoint:NSMakePoint(newPoint.x,yoffset)];
        [userPath lineToPoint:newPoint];
//		[userPath closepath];
	}
}

static NSRect regionFromCorners(NSPoint p1, NSPoint p2)
/*
 * Returns the rectangle which has p1 and p2 as its corners.
 */
{
    NSRect region;

    region.size.width = p1.x - p2.x;
    region.size.height = p1.y - p2.y;
    if (region.size.width < 0.0) {
        region.origin.x = p2.x + region.size.width;
        region.size.width = ABS(region.size.width);
    } else {
        region.origin.x = p2.x;
    }
    if (region.size.height < 0.0) {
        region.origin.y = p2.y + region.size.height;
        region.size.height = ABS(region.size.height);
    } else {
        region.origin.y = p2.y;
    }

    return region;
}
