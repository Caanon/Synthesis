/*--------------------------------------------------------------------------
 *
 *
 *	SIMSwapView
 *
 *	Inherits From:		View
 *
 *	Conforms To:		none
 *
 *	Declared In:		SIMSwapView.h
 *
 *------------------------------------------------------------------------*/

#import <AppKit/AppKit.h>


@interface SIMSwapView : NSView
{
	id	currentPanel;
	id	currentView;
}

- (NSPanel *)currentPanel;
- (NSView *)currentView;
- (void)swap: storagePanel;
- (void)swapView: newView;

@end