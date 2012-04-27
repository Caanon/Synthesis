/* SIMActivityInspector.h created by shill on Sun 06-Jul-1997 */

#import <AppKit/AppKit.h>
#import <Desiderata/NSValueArray.h>
#import <SynthesisInterface/SIMClientCategories.h>
#import <SynthesisInterface/SIMInspector.h>
/*!
    @header SIMActivityInspector
    @abstract   (description)
    @discussion (description)
*/

@interface SIMActivityInspector : SIMInspector
{
	unsigned int layerIndex,timeWindow,xPos,yPos,radius;
	NSString *layerKey,*typeKey,*type;
        id	layerPopUp;
	id	plotView;
        id	xPosField;
        id	yPosField;
        id	posMatrix;
        id	timeWinField;
        id	radiusField;
        id	typePopUp;
        id	settingsPanel;
        id	graphPanel;
        id	tabView;
	NSMutableValueArray *buffer,*times;
}

- (void) clearData:sender;

@end
