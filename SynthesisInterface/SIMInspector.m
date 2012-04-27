
#import "SIMInspector.h"
#import <SynthesisCore/SIMCategories.h>

@implementation SIMInspector

- init
{
    server = nil;

    if([NSBundle loadNibNamed:[[self class] description] owner:self]){
        [inspectorPanel setDelegate:self];
        parentWindow = inspectorPanel;
        return self;
    }
    else {
        NSLog(@"Unable to load interface from bundle:%@",[NSBundle bundleForClass:[self class]]);
        return [self autorelease];
    }
}

- (void)registerForNotifications
{
    [self registerWithServer:[object serverName] onHost:[object hostName]];
    //subclasses then fill in the appropriate notifications
    // this could be stored in a NSDictionary with keys the notifications and the values the selectors
}

- (void)unregisterForNotifications
{
    if(server)[server removeClient:self];
}

- (void)registerWithServer:(NSString *)sName onHost:(NSString *)hName
{
    if(server == nil){
		NSConnection *connection;
		if([hName isEqual:@""])
			connection  = [NSConnection connectionWithRegisteredName:sName host:nil];
		else {
            NSSocketPortNameServer *sharedInstance = [NSSocketPortNameServer sharedInstance];
            NSSocketPort *port = [[NSSocketPortNameServer sharedInstance] portForName:@"SynthesisServer" host:@"localhost"];
			//NSSocketPort *port = [[NSSocketPortNameServer sharedInstance] portForName:sName host:hName];
			connection = [NSConnection connectionWithReceivePort:nil sendPort:port];
		}

		server = [[connection rootProxy] retain];
	}
}

- (void)inspect:anObject
{
    [self inspect:anObject withParameters:nil];
}

- (void)inspect:anObject withParameters:(NSDictionary *)paramInfo
{
    if(anObject)[object autorelease];
    object = [anObject retain];
    [self registerForNotifications];
    [self display];
}

- (id)object
{
    return object;
}

- (void)display
{
// Subclasses should implement
}

- (void)ok:sender
{
// Subclasses should implement
}

- (NSView *)inspectorView
{
        return [inspectorPanel contentView];
}

- (NSPanel *)inspectorPanel
{
        return inspectorPanel;
}

- (NSWindow *)window
{
    return parentWindow;
}

- (void)setParentWindow:(NSWindow *)window
{
    // don't take posession, we just want to know....
    parentWindow = window;
}

- copyWithZone:(NSZone *)zone
{
    SIMInspector *inspectorCopy = [[[self class] allocWithZone:zone] init];
    [inspectorCopy inspect:[self object]];
    return inspectorCopy;
}

- (void)dealloc
{
    [self unregisterForNotifications];
    [inspectorPanel close];
    if(server)[server release];
    if(object)[object release];
    [super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self unregisterForNotifications];
}

@end

