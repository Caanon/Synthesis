
/*
* For each line that one wants displayed in the plot two entries should exist in the
* attributeDictionary.  In the DATA_DICT there should be an entry containing the data
* (An array of NSNumbers) for each coordinate.  In the CURVES_DICT there should be key 
* pairs referring to these coordinates.  Be sure to see the template file for details.
*/
#import "XYPlotView.h"

@implementation XYPlotView (XYPlotViewPublicAPI)

- (void)plotFromFile:sender
{
    int result;
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];


    [oPanel setAllowsMultipleSelection:YES];
    result = [oPanel runModalForDirectory:NSHomeDirectory() file:nil 
		 types:nil];
    if (result == NSOKButton) {
        NSArray *filesToOpen = [oPanel filenames];
        int i, count = [filesToOpen count];
        for (i=0; i<count; i++) {
              NSString *aFile = [filesToOpen objectAtIndex:i];
              [plotData addContentsOfPlainFile:aFile];
        }
        [self refresh];
    }
}

- (void)removeAllPlots:sender
{
    [plotData removeAllCurves];
    [plotData removeAllData];
    [self refresh];
}

- (void)setPlotStyle:(NSString *)style
{
    [plotDictionary setObject:style forKey:PLOT_STYLE];
}

- (void)setAutoScale:(BOOL)autoscale
{
    //plotDictionary = [plotData attributesDictionary];
    [[plotDictionary objectForKey:PLOT_XAXIS] setBool:autoscale forKey:AUTO_SCALE];
    [[plotDictionary objectForKey:PLOT_YAXIS] setBool:autoscale forKey:AUTO_SCALE];
}

- (void)plotValuesFromString:(NSString *)stringData
{
    
}

- (void)setMainTitle:(NSString *)title
{    
    [plotDictionary setObject: title forKey: TITLE];
}

- (void)setXTitle:(NSString *)title;
{    
    [[plotDictionary objectForKey: X_AXIS] setObject: title forKey: TITLE];
}

- (void)setYTitle:(NSString *)title;
{    
    [[plotDictionary objectForKey: Y_AXIS] setObject: title forKey: TITLE];
}

- (void)plotValues:(NSArray *)values
{
    NSString *uniqueString;

    [plotData removeAllCurves];
    [plotData removeAllData];

    uniqueString = [NSString stringWithFormat:@"Data #%d",[[plotData curvesDictionary] count]+1]; //certainly could be more unique!

    [plotData setData:values forKey:uniqueString];
    [plotData setCurves:[NSArray arrayWithObject:uniqueString] forKey:uniqueString];
    [self refresh];
}

- (void)plotValues:(NSArray *)x :(NSArray *)y
{
    NSString *xKey = @"xData";
    NSString *yKey = @"yData";
    NSString *curveKey = @"Curve";

    [plotData removeAllCurves];
    [plotData removeAllData];

    [plotData setData:x forKey:xKey];
    [plotData setData:y forKey:yKey];
    [plotData setCurves:[NSArray arrayWithObjects:xKey,yKey,nil] forKey:curveKey];
    [self refresh];
}

- (void)addPlotWithValues:(NSArray *)values
{
    NSString *uniqueString;

    uniqueString = [NSString stringWithFormat:@"Data #%d",[[plotData curvesDictionary] count]+1]; //certainly could be more unique!

    [plotData setData:values forKey:uniqueString];
    [plotData setCurves:[NSArray arrayWithObject:uniqueString] forKey:uniqueString];
    [self refresh];
}

- (void)addPlotWithValues:(NSArray *)x :(NSArray *)y;
{
    NSString *xKey = [NSString stringWithFormat:@"xData #%d",[[plotData curvesDictionary] count]+1];;
    NSString *yKey = [NSString stringWithFormat:@"yData #%d",[[plotData curvesDictionary] count]+1];;
    NSString *curveKey = [NSString stringWithFormat:@"curveData #%d",[[plotData curvesDictionary] count]+1];;

    [plotData setData:x forKey:xKey];
    [plotData setData:y forKey:yKey];
    [plotData setCurves:[NSArray arrayWithObjects:xKey,yKey,nil] forKey:curveKey];
	[self refresh];
}

- (void)refresh
{
    [plotData updateAttributesDictionary];
    [self _setup];
    [self _scaleToView];
    [self setNeedsDisplay:YES];
}




@end