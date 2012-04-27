/*!
    @header SIMSimulation
    @abstract   (description)
    @discussion (description)
*/

#import <Cocoa/Cocoa.h>
#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMCommandServer.h>
#import <SynthesisCore/SIMCommandClient.h>
#import <SynthesisInterface/SIMInspector.h>


@interface SIMSimulation : NSDocument {

    id swapView;
    id timeField;
    id hostField;
    id serverField;
    id nodeHostView;
    id nodeNameView;
    id timeToolView;
    id ipField;
    id countField;
    id statusField;
    id statusBox;
    id startupPanel;
    id connectButton;
    id connectView;
    id commandView;
    id parentWindow;
    id progressWheel;
    id inspectorPopup;
    id inspectorPopupView;

@private
    BOOL connected;
	NSString *serverName;
    SIMCommandServer *server;
    SIMNetwork *network;
    id objectInspector;
    NSMutableDictionary *inspectorDictionary, *toolbarItems;
	NSTask *serverTask;
}

- (void)toggleRun:sender;
- (void)pause:sender;
- (void)ok:sender;

//TIMEDIT
- (void) threadedCommand:(NSNotification *)notification;

- (void)toggleConnect:sender;
- (void)connect;
- (void)disconnect;
- (void)startLog;
- (void)logStatus:(NSNotification *)notify;
- (void)logError:(NSNotification *)notify;
- (void)appendStringToLog:(NSString *)string;


- (void)networkIsAvailable:(NSNotification *)notification;
- (void)networkNotAvailable:(NSNotification *)notification;

//- (void)reset:sender;

- (void)display;
- (void)displayPrompt;

- (void) setStatusText:(NSString *)string;
- (void) setStatusTitle:(NSString *)string;

- (void) registerWithServer:(NSString *)sName onHost:(NSString *)hName;
- (void) connectToServer:(NSString *)sname onHost:(NSString *)hname;

- (void)inspectObject:(id <SIMInspectable>)obj withInspectorKey:(NSString *)inspectorKey;
- (void)inspectObject:(id <SIMInspectable>)obj withInspectorDescription:(NSDictionary *)dict setTitle:(NSString *)title;

- (void)addInspectorOfType:(NSString *)inspectorClass withTitle:(NSString *)title;

- (void) setupToolbar;



@end
