/* SIMActivityInspector.m created by shill on Sun 06-Jul-1997 */

#import "SIMActivityInspector.h"
#import <SynthesisCore/SIMNetworkStatistics.h>
#import <XYPlot/XYPlotView.h>

#define GRAPH_VIEW	@"Graph"
#define RASTER_VIEW	@"Raster"
#define SETTINGS_VIEW	@"Settings"

#define AVG_MEMBRANE_POTENTIAL	@"Average Membrane Potential"
#define MEMBRANE_POTENTIAL	@"Membrane Potential"
#define LOCAL_FIELD_POTENTIAL	@"Local Field Potential"
#define MEAN_FIRING_RATE	@"Mean Firing Rate"

#define min(x,y) ((x)<(y) ? (x):(y))
#define max(x,y) ((x)>(y) ? (x):(y))

@implementation SIMActivityInspector

- init
{
    [super init];
    [tabView addView:[graphPanel contentView] withLabel:GRAPH_VIEW];
    [tabView addView:[settingsPanel contentView] withLabel:SETTINGS_VIEW];
    return self;
}


- (void)display
{
    NSRange plotRange;
    float dt = [object dt];
    int l = [buffer count] - timeWindow/dt;
    plotRange.location = max(0,l);
    plotRange.length = min(timeWindow/dt,[buffer count]);

    //printf("%d %d\n",plotRange.location,plotRange.length);

    if([type isEqual:AVG_MEMBRANE_POTENTIAL]){
        [plotView setMainTitle:AVG_MEMBRANE_POTENTIAL];
        [plotView setXTitle:@"Time step"];
        [plotView setYTitle:@"mV"];
    }
    if([type isEqual:LOCAL_FIELD_POTENTIAL]){
        [plotView setMainTitle:LOCAL_FIELD_POTENTIAL];
        [plotView setXTitle:@"Time step"];
        [plotView setYTitle:@"mV"];
    }
    if([type isEqual:MEAN_FIRING_RATE]){
        [plotView setMainTitle:MEAN_FIRING_RATE];
        [plotView setXTitle:@"Time"];
        [plotView setYTitle:@"spikes/sec"];
    }

    
    [plotView plotValues:[times valueArrayFromRange:plotRange] :[buffer valueArrayFromRange:plotRange]];
}

- (void)gatherData
{
    SIMPosition aCell;
    float activity,time,dt;

    aCell.x = xPos;
    aCell.y = yPos;
    aCell.z = layerIndex;

    if([type isEqual:AVG_MEMBRANE_POTENTIAL]){
        activity = [object averageMembranePotentialAroundCell:&aCell radius:radius];
    }
    if([type isEqual:LOCAL_FIELD_POTENTIAL]){
        activity = [object localFieldPotentialForCell:&aCell radius:radius];
    }
    if([type isEqual:MEAN_FIRING_RATE]){
        activity = [object populationActivityForLayer:layerIndex]*1000;
    }
    time = [object time];
    [buffer addValue:&activity];
    [times addValue:&time];

    [self display];

    //printf("%g %g %d\n",time,dt,[buffer count]);
}

- (void)ok:sender
{
    if(sender == layerPopUp){
        layerIndex = (int)[object indexForLayerWithKey:[layerPopUp titleOfSelectedItem]];
//        numRows = (int)[object numRowsInLayer:layerIndex];
//        numColumns = (int)[object numColumnsInLayer:layerIndex];
        //[typePopUp removeAllItems];
        //[typePopUp addItemsWithTitles:[object typesForLayer:layerIndex]];
        //typeKey = [[typePopUp titleOfSelectedItem] retain];
        [self clearData:self];
        [self inspect: object];
    }
    else if(sender == typePopUp){
        if(type)[type autorelease];
        type = [[sender titleOfSelectedItem] retain];
        [plotView setMainTitle:type];
    }

    [self clearData:self];
    timeWindow = [timeWinField intValue];
    radius = [radiusField intValue];
    xPos = [xPosField intValue];
    yPos = [yPosField intValue];
    [self display];
}

- (void)clearData:sender
{
    [buffer removeAllObjects];
    [times removeAllObjects];
}

- (void)inspect:anObject
{
//    layerIndex = 0;
//    variableIndex = 0;
	//typeKey = [[anObject typesForLayer:layerIndex] objectAtIndex:0];


    if(!buffer)buffer = [[NSMutableValueArray valueArrayWithObjCType:@encode(float)] retain];
    if(!times)times = [[NSMutableValueArray valueArrayWithObjCType:@encode(float)] retain];

    [self clearData:self];

    [layerPopUp removeAllItems];
    [layerPopUp addItemsWithTitles:[anObject layerKeys]];
    [layerPopUp selectItemAtIndex:layerIndex];
    //[typePopUp removeAllItems];
    //[typePopUp addItemsWithTitles:[anObject typesForLayer:layerIndex]];
    //[typePopUp selectItemAtIndex:variableIndex];
    //typeKey = [[typePopUp titleOfSelectedItem] retain];

    radius = [radiusField intValue];
    xPos = [xPosField intValue];
    yPos = [yPosField intValue];
    timeWindow = [timeWinField intValue];


    [plotView setMainTitle:LOCAL_FIELD_POTENTIAL];
    [plotView setXTitle:@"Time step"];
    [plotView setYTitle:@"mV"];

    [plotView removeAllPlots:self];

    [plotView setAutoScale:YES];

    [super inspect:anObject];
}

- (void)registerForNotifications
{
    [super registerForNotifications];
    [server addClient:self forNotificationName:SIMNetworkUpdateIntervalNotification
        selector:@selector(gatherData) object:[server network]];
}

@end
