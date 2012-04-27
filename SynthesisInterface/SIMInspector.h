
#import <SynthesisCore/Simulator.h>
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import "SIMSwapView.h"

@interface SIMInspector:NSObject <NSCopying>
{
    id inspectorPanel;
    id object;
    id server;
    id parentWindow;
}

- init;
- (void)ok:sender;
- (void)inspect:anObject;
- (id)object;
- (void)registerForNotifications;
- (void)unregisterForNotifications;
- (void)registerWithServer:(NSString *)serverName onHost:(NSString *)hostName;
- (void)display;
- (NSView *)inspectorView;
- (NSPanel *)inspectorPanel;
- (NSWindow *)window;
- (void)setParentWindow:(NSWindow *)window;
- (void)windowWillClose:(NSNotification *)notification;

@end
