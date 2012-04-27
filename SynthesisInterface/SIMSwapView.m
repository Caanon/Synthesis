/*--------------------------------------------------------------------------
 *
 *
 *	SwapView
 *
 *	Inherits From:		View
 *
 *	Conforms To:		none
 *
 *	Declared In:		SIMSwapView.h
 *
 *------------------------------------------------------------------------*/

#import "SIMSwapView.h"


@implementation SIMSwapView

- initWithFrame: (NSRect) theFrame
{
	[super initWithFrame:theFrame];
	[self setAutoresizesSubviews:YES];
	currentPanel = nil;
	currentView = nil;
	return self;
}

- (NSPanel *)currentPanel
{
	return currentPanel;
}

- (NSView *)currentView
{
	return currentView;
}

- (void)swap: storagePanel;
{
	NSView *aView; 

	if (storagePanel != currentPanel)
	{
            aView = [currentPanel contentView];
            [self swapView:[currentPanel contentView]];
            [(NSPanel *)currentPanel setContentView:aView];
            currentPanel = storagePanel;
	}
}

- (void)swapView: newView;
{
    [newView retain];
    [currentView retain];
    [currentView removeFromSuperview];
    [currentView autorelease];
    currentView = newView;
    [currentView setFrame:[self frame]];
    [currentView setFrameOrigin:NSZeroPoint];
    [currentView setAutoresizingMask:[self autoresizingMask]];
    [self addSubview:currentView];
    currentPanel = [self window];
    [currentPanel display];
}
@end