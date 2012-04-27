// SIMSimulation.m

#import "SIMSimulation.h"
#import <SynthesisCore/SIMCategories.h>

// All NSToolbarItems have a unique identifer associated with them, used to tell your delegate/controller what 
// toolbar items to initialize and return at various points.  Typically, for a given identifier, you need to 
// generate a copy of your "master" toolbar item, and return it autoreleased.  The function below takes an
// NSMutableDictionary to hold your master NSToolbarItems and a bunch of NSToolbarItem paramenters,
// and it creates a new NSToolbarItem with those parameters, adding it to the dictionary.  Then the dictionary
// can be used from -toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar: to generate a new copy of the 
// requested NSToolbarItem (when the toolbar wants to redraw, for instance) by simply duplicating and returning
// the NSToolbarItem that has the same identifier in the dictionary.  Plus, it's easy to call this function
// repeatedly to generate lots of NSToolbarItems for your toolbar.
// -------
// label, palettelabel, toolTip, action, and menu can all be NULL, depending upon what you want the item to do
static void addToolbarItem(NSMutableDictionary *theDict,NSString *identifier,NSString *label,NSString *paletteLabel,NSString *toolTip,id target,SEL settingSelector, id itemContent,SEL action, NSMenu * menu)
{
    NSMenuItem *mItem;
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    // the settingSelector parameter can either be @selector(setView:) or @selector(setImage:).  Pass in the right
    // one depending upon whether your NSToolbarItem will have a custom view or an image, respectively
    // (in the itemContent parameter).  Then this next line will do the right thing automatically.
    [item performSelector:settingSelector withObject:itemContent];
    [item setAction:action];
    // If this NSToolbarItem is supposed to have a menu "form representation" associated with it (for text-only mode),
    // we set it up here.  Actually, you have to hand an NSMenuItem (not a complete NSMenu) to the toolbar item,
    // so we create a dummy NSMenuItem that has our real menu as a submenu.
    if (menu!=NULL)
    {
	// we actually need an NSMenuItem here, so we construct one
	mItem=[[[NSMenuItem alloc] init] autorelease];
	[mItem setSubmenu: menu];
	[mItem setTitle: [menu title]];
	[item setMenuFormRepresentation:mItem];
    }
    // Now that we've setup all the settings for this new toolbar item, we add it to the dictionary.
    // The dictionary retains the toolbar item for us, which is why we could autorelease it when we created
    // it (above).
    [theDict setObject:item forKey:identifier];
}

@implementation SIMSimulation

// -----------------------------------------------------------------------------
// Override returning the nib file name of the document

- (NSString *)windowNibName {
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"SIMSimulation";
}

// -----------------------------------------------------------------------------
// Override

- (void)windowControllerDidLoadNib:(NSWindowController *) aController{
	NSString *serverPath = [NSBundle pathForResource:@"SynthesisServer" ofType:@"" 
								inDirectory:[[NSBundle mainBundle] builtInPlugInsPath]];
								
    [super windowControllerDidLoadNib:aController];
    // Add any code here that need to be executed once the windowController has loaded the document's window.

	serverTask = [[NSTask alloc] init];
	
	if(serverPath)[serverTask setLaunchPath:serverPath];
	
	[serverTask setArguments:[NSArray arrayWithObjects:@"-ServerName",[self displayName],nil]];
	
	//[serverTask launch];

    [(SIMSwapView *)swapView swapView:[startupPanel contentView]];
    [commandView setDelegate:self];
    [commandView setFieldEditor:YES];
    [self setupToolbar];
    server = nil;
}


- (void) ok:sender
{
    if(sender == serverField){
        [serverField addItemWithObjectValue:[serverField stringValue]];
    }
    if(sender == hostField){
        [hostField addItemWithObjectValue:[hostField stringValue]];
    }
    if(sender == inspectorPopup){
        NSString *inspectorType = [inspectorPopup titleOfSelectedItem];
        NSString *title = [NSString stringWithFormat:@"%@%d",inspectorType,(int)[server clientCount]];
        NSLog(inspectorType);
        if([inspectorType isEqual:@"Network"])[self addInspectorOfType:@"SIMNetworkActivityInspector" withTitle:title];
        else if([inspectorType isEqual:@"Cell"])[self addInspectorOfType:@"SIMCellActivityInspector" withTitle:title];
        else if([inspectorType isEqual:@"Raster"])[self addInspectorOfType:@"SIMActivityMapInspector" withTitle:title];
        else if([inspectorType isEqual:@"Connection"])[self addInspectorOfType:@"SIMConnectionMatrixInspector" withTitle:title];
    }
}

- (void)registerForNotifications
{
    if(connected){
        network = [server network];
		
		[(NSProxy *)network setProtocolForProxy:@protocol(SIMRemoteNetwork)];
		
		//if ([[server hostName] isEqual:@""]){
		[server addClient:self forNotificationName:SIMNetworkDidUpdateNotification
			selector:@selector(display) object:network];
		//}
        [server addClient:self forNotificationName:SIMParameterDidChangeNotification
            selector:@selector(parameterEdited) object:network];
        [server addClient:self forNotificationName:SIMNetworkIsAvailableNotification
                 selector:@selector(networkIsAvailable:) object:nil];
        [server addClient:self forNotificationName:SIMNetworkNotAvailableNotification
                 selector:@selector(networkNotAvailable:) object:network];

    }
}

- (void)unregisterForNotifications
{
    if(server)[server removeClient:self];
}

- (void) parameterEdited
{
    [self updateChangeCount:NSChangeDone];
}


- (void)toggleConnect:sender
{
    if(connected){
        [self disconnect];
        [self setStatusTitle:@"Disconnected"];
        [self setStatusText:@"Client has disconnected from the server.\n"];
        [ipField setStringValue:@"0.0.0.0"];
        [(SIMSwapView *)swapView swapView:[startupPanel contentView]];

    }
    else {
		[self connectToServer:[serverField stringValue] onHost:[hostField stringValue]];
		[self registerForNotifications];
		[self startLog];
        if(!server){
            connected = NO;
            [connectButton setNextState];
            [self setStatusTitle:@"Disconnected"];
            [self setStatusText:@"Client could not connect to the server.\n"];
        }
        return;
    }
}

- (void) startLog
{
    if(server){
        /* Setup for commandline logging of status events */
        [server addClient:self forNotificationName:SIMStatusUpdateNotification selector:@selector(logStatus:) object:nil];
        [server addClient:self forNotificationName:SIMErrorUpdateNotification selector:@selector(logError:) object:nil];
    }
    
    [commandView setString:@""];
    
    [self appendStringToLog:@"--                   SYNTHESIS Simulator                   --\n"];
    [self appendStringToLog:@"--                  by Sean Hill (c) 2006                  --\n"];
    [self appendStringToLog:[NSString stringWithFormat:@"--        Connected at: %@          --\n",[[NSDate date] description]]]; 
    [self displayPrompt];   
}

- (void)displayPrompt
{
    NSString *prompt;

    if(server){
        prompt = [NSString stringWithFormat:@"[%@:%d] t=%0.2f %@>",[server serverName:nil],[server nodeIdentifier],[[server time:nil] floatValue],[server pwd:nil]];
    }
    else prompt = @"-Disconnected- >";
    [self appendStringToLog:prompt];
}

- (void)logStatus:(NSNotification *)notify
{
    NSDictionary *info = [notify userInfo];

    if(info){
        NSString *status = [info objectForKey:SIMStatusDescriptionKey];
        if(status)[self appendStringToLog:[NSString stringWithFormat:@"STATUS: %@\n",status]];
    }

}

- (void)logError:(NSNotification *)notify
{
    NSDictionary *info = [notify userInfo];

    if(info){
        NSString *status = [info objectForKey:SIMStatusDescriptionKey];
        if(status)[self appendStringToLog:[NSString stringWithFormat:@"ERROR: %@\n",status]];
    }

}

- (void) appendStringToLog:(NSString *)string
{
    NSRange location;

    location = [commandView selectedRange];

    [commandView replaceCharactersInRange: NSMakeRange(NSMaxRange(location), 0)
                    withString: string];
    [commandView scrollRangeToVisible: NSMakeRange(NSMaxRange(location),
        NSMaxRange([commandView selectedRange])-NSMaxRange(location))];
    [commandView setEditable: YES];

}

- (void) disconnect
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    connected = NO;

    [self unregisterForNotifications];
    //[server removeAllClients]; don't remove all clients, this removes agents as well!!!

    [inspectorDictionary removeAllObjects];
    [inspectorDictionary release];
    inspectorDictionary = nil;

    [server release];
    server = nil;
    [pool release];
}

- (void) connectToServer:(NSString *)sName onHost:(NSString *)hName
{
    NSString *inspectorKey;
    NSDictionary *inspectors;
    NSEnumerator *inspectEnum;
    
    [self setStatusText:[NSString stringWithFormat:@"Trying to connect to server %@ on %@\n",sName,hName]];
    [self setStatusTitle:@"Connecting\n"];

    if(server != nil)[server release];server = nil;

	NSConnection *connection;
	if([hName isEqual:@""])
		connection  = [NSConnection connectionWithRegisteredName:sName host:nil];
	else {
		NSSocketPort *port = [[NSSocketPortNameServer sharedInstance] portForName:sName host:hName];
		connection = [NSConnection connectionWithReceivePort:nil sendPort:port];
	}
	
	server = [[connection rootProxy] retain];
	
    if(server == nil){
        [self setStatusText:@"Unable to connect to server. Be sure the server is running.\n"];
        return;
    }
    else {
		[self setStatusTitle:@"Connected"];
	    connected = YES;
	}

    [self setStatusText:[NSString stringWithFormat:@"Connected to server %@ on %@\n",sName,hName]];

    [self setUndoManager:[[server network] undoManager]];

    //[[server connectionForProxy] setIndependentConversationQueueing:YES];

    [ipField setStringValue:[[NSHost hostWithName:[server hostName]] address]];

    inspectorDictionary = [[NSMutableDictionary alloc] init];

    inspectors = [[[server network] rootDictionary] objectForKey:INSPECTORS_KEY];
    if(inspectors){
        inspectEnum = [inspectors keyEnumerator];
        while(inspectorKey = [inspectEnum nextObject]){
            NSDictionary *settings = [inspectors objectForKey:inspectorKey];
            [self inspectObject:[server network] withInspectorDescription:settings setTitle:inspectorKey];
        }
    }

    [self inspectObject:[server network] withInspectorKey:@"SIMDictionaryInspector"];
    
}

- (void)inspectObject:(id <SIMInspectable>)obj withInspectorKey:(NSString *)inspectorKey
{
    id path;

    //if(objectInspector)[objectInspector unregisterForNotifications];
    if(![inspectorDictionary objectForKey:inspectorKey]){
        path = [[NSBundle mainBundle] pathForResource:inspectorKey ofType:INSPECTOR_EXTENSION];
        objectInspector = [[[[NSBundle bundleWithPath:path] principalClass] alloc] init];
        NS_DURING
        [inspectorDictionary setObject:[objectInspector autorelease] forKey:inspectorKey];
        NS_HANDLER
        [self setStatusText:[NSString stringWithFormat:@"Object inspector %@ does not exist.  Please check that it is installed.\n",inspectorKey]];
        NS_ENDHANDLER
    }
    else objectInspector = [inspectorDictionary objectForKey:inspectorKey];
    [objectInspector setParentWindow:parentWindow];
    [objectInspector inspect:obj];
    [(SIMSwapView *)swapView swapView:[objectInspector inspectorView]];
}

- (void)addInspectorOfType:(NSString *)inspectorClass withTitle:(NSString *)title
{    
    NSArray *tempObjs = [NSArray arrayWithObjects:@"\"512 250 350 200 0 0 1024 748\"",inspectorClass,[NSMutableDictionary dictionary],nil];
    NSArray *keys = [NSArray arrayWithObjects:@"FRAME",@"INSPECTOR_CLASS",@"PARAMETERS",nil];
    NSMutableDictionary *inspectorDict = [NSMutableDictionary dictionaryWithObjects:tempObjs forKeys:keys];    
    NSString *path = [NSString stringWithFormat:@"/INSPECTORS/%@",title];
    [[server network] setObject:inspectorDict atPath:path];
    [self inspectObject:[server network] withInspectorDescription:inspectorDict setTitle:title];
}


- (void)inspectObject:(id <SIMInspectable>)obj withInspectorDescription:(NSDictionary *)dict setTitle:(NSString *)title
{
    id path;
    NSString *inspectorKey = [dict objectForKey:INSPECTOR_CLASS_KEY];

    path = [[NSBundle mainBundle] pathForResource:inspectorKey ofType:INSPECTOR_EXTENSION];
    objectInspector = [[[[NSBundle bundleWithPath:path] principalClass] alloc] init];
    NS_DURING
    [inspectorDictionary setObject:[objectInspector autorelease] forKey:[NSString stringWithFormat:@"%@.%@",inspectorKey,title]];
    NS_HANDLER
    [self setStatusText:[NSString stringWithFormat:@"Object inspector %@ does not exist.  Please check that it is installed.\n",inspectorKey]];
    NS_ENDHANDLER

    [objectInspector inspect:obj];
    [[objectInspector inspectorPanel] setFrameFromString:[dict objectForKey:INSPECTOR_FRAME_KEY]];
    [[objectInspector inspectorPanel] setTitle:title];
    [[objectInspector inspectorPanel] setDelegate:self];
    [[objectInspector inspectorPanel] makeKeyAndOrderFront:self];
}


- (void)toggleRun:sender
{
    if(connected && ![server isRunning]){
        [server run:nil];
        [self setStatusTitle:@"Running"];
        //[progressWheel startAnimation:sender];
    }
    else {
        [server stop:nil];
        [self setStatusTitle:@"Stopped"];
        //[progressWheel stopAnimation:sender];
    }
}

- (void)pause:sender
{
    if(connected && [server isRunning]){
        [server stop:nil];
        [self setStatusTitle:@"Paused"];
    }
    else {
        [server continue:nil];
        [self setStatusTitle:@"Running"];
    }
}

- (void)display
{
    [timeField setStringValue:[NSString stringWithFormat:@"%0.2f ms",[network time]]];
	//NSLog([NSString stringWithFormat:@"%0.2f ms",[network time]]);
    //[progressWheel animate:nil];
    //[countField setIntValue:(int)[server clientCount]];
}

- (void)networkIsAvailable:(NSNotification *)notification
{
    [self connectToServer:[serverField stringValue] onHost:[hostField stringValue]];
    if(server)connected = YES;
    [self registerForNotifications];
}

- (void)networkNotAvailable:(NSNotification *)notification
{
    if(network){
        [[inspectorDictionary allValues] makeObjectsPerformSelector:@selector(unregisterForNotifications)];
        [inspectorDictionary removeAllObjects];
        [inspectorDictionary release];
        inspectorDictionary = nil;
        [network release];
    }
}

- (void)disconnectAllClients:(id)sender
{
    //if(object)[[object serverWithRegisteredName:[serverField stringValue]] removeAllClients];
    if(server)[server removeAllClients];

}

- (void) setStatusText:(NSString *)string
{
    [statusField setStringValue:string];
    [self appendStringToLog:string];
}

- (void) setStatusTitle:(NSString *)string
{
    [statusBox setTitle:[NSString stringWithFormat:@"Status: %@",string]];
}


// -----------------------------------------------------------------------------
// Override

- (NSData *)dataRepresentationOfType:(NSString *)aType {
    NSString *dataString;

    NSAssert([aType isEqualToString:@"SynthesisSimulation"], @"Unknown type");
    NSAssert(server, @"Not connected to a server");
    dataString = [[server network] description];
    return [NSData dataWithBytes:[dataString cString] length:[dataString length]];
}

// -----------------------------------------------------------------------------
// Override

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType {
    NSAssert(server, @"Not connected to a server");
    [server loadNetworkWithDescription:[[NSString stringWithCString:[data bytes]] propertyList]];
    return YES;
}

- (void)windowDidMove:(NSNotification *)aNotification
{
    NSWindow *inspectorWindow = [aNotification object];
    NSMutableDictionary *inspectors;
    inspectors = [[[server network] rootDictionary] objectForKey:INSPECTORS_KEY];
    if(inspectors){
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params addEntriesFromDictionary:[inspectors objectForKey:[inspectorWindow title]]];
        [params setObject:[inspectorWindow stringWithSavedFrame] forKey:INSPECTOR_FRAME_KEY];
        [inspectors setObject:params forKey:[inspectorWindow title]];
        [[server network] setObject:inspectors forKey:INSPECTORS_KEY];
    }
}

- (void)windowDidResize:(NSNotification *)aNotification
{
    NSWindow *inspectorWindow = [aNotification object];
    NSMutableDictionary *inspectors;
    inspectors = [[[server network] rootDictionary] objectForKey:INSPECTORS_KEY];
    if(inspectors){
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params addEntriesFromDictionary:[inspectors objectForKey:[inspectorWindow title]]];
        [params setObject:[inspectorWindow stringWithSavedFrame] forKey:INSPECTOR_FRAME_KEY];
        [inspectors setObject:params forKey:[inspectorWindow title]];
        [[server network] setObject:inspectors forKey:INSPECTORS_KEY];
    }
}

static const NSString *TEXT_MOVEMENT      = @"NSTextMovement";

- (void)textDidEndEditing:(NSNotification *)notification {
    if ([[[notification userInfo] objectForKey: TEXT_MOVEMENT] intValue] == NSReturnTextMovement) {
        [NSThread detachNewThreadSelector:@selector(threadedCommand:) toTarget:self withObject:notification];
    }
}

- (void)threadedCommand:(NSNotification *)notification
	{
	if ([[[notification userInfo] objectForKey: TEXT_MOVEMENT] intValue] == NSReturnTextMovement)
		{
		NSString     *textString;
		NSRange       selectedRange;
		NSRange       commandRange;
		NSString     *commandString;
		unsigned int  endLocation;
		NSRange       startRange;
                id answer = nil;

		textString    = [commandView string];
		selectedRange = [commandView selectedRange];

		[textString getLineStart: NULL
		            end:          NULL
		            contentsEnd:  &endLocation
		            forRange:     selectedRange];
		startRange = [textString rangeOfString: @">"
		                         options:       NSBackwardsSearch
		                         range:         NSMakeRange(0, endLocation)];
		if (startRange.length == 0)
			commandRange = NSMakeRange(0, endLocation);
		else
			commandRange = NSMakeRange(NSMaxRange(startRange), endLocation-NSMaxRange(startRange));

		commandString = [textString substringWithRange: commandRange];
		startRange     = [commandString rangeOfCharacterFromSet: [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet]];

		if (([commandString length] > 0) &&
		    (startRange.length > 0))
			{
                        if(server)answer = [server interpretCommand:commandString];
			[commandView replaceCharactersInRange: NSMakeRange(NSMaxRange(commandRange), 0)
			             withString:               @"\n"];
			[commandView setSelectedRange: NSMakeRange(NSMaxRange(commandRange)+1, 0)];
			[commandView setSelectedRange: NSMakeRange(selectedRange.location, 0)];
			}
                        if(answer)[self appendStringToLog:[NSString stringWithFormat:@"\n%@\n",[answer description]]];
                        else [self appendStringToLog:@"\n"];
                        [self displayPrompt];
                        [[commandView window] makeFirstResponder: commandView];
		}

	return;
}

- (void)clear:sender
{
    [commandView selectAll:sender];
    [commandView cut:sender];
    [self displayPrompt];
}


- (void) dealloc
{
    [self disconnect];
	//[serverTask terminate];
	//[serverTask release];
    [toolbarItems release];
    [super dealloc];
}


// When we launch, we have to get our NSToolbar set up.  This involves creating a new one, adding the NSToolbarItems,
// and installing the toolbar in our window.
-(void)setupToolbar
{
    NSToolbar *toolbar=[[[NSToolbar alloc] initWithIdentifier:@"myToolbar"] autorelease];
    
    // Here we create the dictionary to hold all of our "master" NSToolbarItems.
    toolbarItems=[[NSMutableDictionary dictionary] retain];
    // Now lets create three NSToolbarItems; 2 using custom views, and a standard one using an image.
    // We call our special processing function to do the initialization and add them to the dictionary.
    addToolbarItem(toolbarItems,@"NodeHost",@"Node Host",@"Node Host",@"Select the node host",self,@selector(setView:),nodeHostView,NULL,NULL);
    addToolbarItem(toolbarItems,@"NodeName",@"Node Name",@"Node Name",@"Select the node to connect to",self,@selector(setView:),nodeNameView,NULL,NULL);
    addToolbarItem(toolbarItems,@"Time",@"Time",@"Time",@"The current simulation time",self,@selector(setView:),timeToolView,NULL,NULL);
    addToolbarItem(toolbarItems,@"Connect",@"Connect",@"Connect",@"Connect to the simulation server",self,@selector(setView:),connectView,NULL,NULL);
    addToolbarItem(toolbarItems,@"Run",@"Run",@"Run",@"Start the simulation",self,@selector(setImage:),[NSImage imageNamed:@"start.tiff"],@selector(toggleRun:),NULL);
    addToolbarItem(toolbarItems,@"CreateInspector",@"Create Inspector",@"Create Inspector",@"Add a new graphical view of activity",self,@selector(setView:),inspectorPopupView,NULL,NULL);
    //addToolbarItem(toolbarItems,@"FontSize",@"Font Size",@"Font Size",@"Grow or shrink the size of your font",self,@selector(setView:),fontSizeView,NULL,fontSizeMenu);
    // often using an image will be your standard case.  You'll notice that a selector is passed
    // for the action (blueText:), which will be called when the image-containing toolbar item is clicked.
   // addToolbarItem(toolbarItems,@"BlueLetter",@"Blue Text",@"Blue Text",@"This toggles blue text on/off",self,@selector(setImage:),[NSImage imageNamed:@"blueLetter.tif"],@selector(blueText:),NULL);
     
    // the toolbar wants to know who is going to handle processing of NSToolbarItems for it.  This controller will.
    [toolbar setDelegate:self];
    // If you pass NO here, you turn off the customization palette.  The palette is normally handled automatically
    // for you by NSWindow's -runToolbarCustomizationPalette: method; you'll notice that the "Customize Toolbar"
    // menu item is hooked up to that method in Interface Builder.  Interface Builder currently doesn't automatically 
    // show this action (or the -toggleToolbarShown: action) for First Responder/NSWindow (this is a bug), so you 
    // have to manually add those methods to the First Responder in Interface Builder (by hitting return on the First Responder and 
    // adding the new actions in the usual way) if you want to wire up menus to them.
    [toolbar setAllowsUserCustomization:YES];

    // tell the toolbar that it should save any configuration changes to user defaults.  ie. mode changes, or reordering will persist. 
    // specifically they will be written in the app domain using the toolbar identifier as the key. 
    [toolbar setAutosavesConfiguration: YES]; 
    
    // tell the toolbar to show icons only by default
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    // install the toolbar.
    [parentWindow setToolbar:toolbar];
}

// We don't do anything useful here (and we don't really have to implement this method) but you could
// if you wanted to. If, however, you want to have validation checks on your standard NSToolbarItems
// (with images) and have inactive ones grayed out, then this is the method for you.
// It isn't called for custom NSToolbarItems (with custom views); you'd have to override -validate:
// (see NSToolbarItem.h for a discussion) to get it to do so if you wanted it to.
// If you don't implement this method, the NSToolbarItems are enabled by default.
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    // You could check [theItem itemIdentifier] here and take appropriate action if you wanted to
    return YES;
}

// This is an optional delegate method, called when a new item is about to be added to the toolbar.
// This is a good spot to set up initial state information for toolbar items, particularly ones
// that you don't directly control yourself (like with NSToolbarPrintItemIdentifier here).
// The notification's object is the toolbar, and the @"item" key in the userInfo is the toolbar item
// being added.
- (void) toolbarWillAddItem: (NSNotification *) notif
{
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
    // Is this the printing toolbar item?  If so, then we want to redirect it's action to ourselves
    // so we can handle the printing properly; hence, we give it a new target.
    if ([[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier])
    {
        [addedItem setToolTip: @"Print your document"];
        [addedItem setTarget: self];
    }
}  


// This method is required of NSToolbar delegates.  It takes an identifier, and returns the matching NSToolbarItem.
// It also takes a parameter telling whether this toolbar item is going into an actual toolbar, or whether it's
// going to be displayed in a customization palette.
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    // We create and autorelease a new NSToolbarItem, and then go through the process of setting up its
    // attributes from the master toolbar item matching that identifier in our dictionary of items.
    NSToolbarItem *newItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    NSToolbarItem *item=[toolbarItems objectForKey:itemIdentifier];
    
    [newItem setLabel:[item label]];
    [newItem setPaletteLabel:[item paletteLabel]];
    if ([item view]!=NULL)
    {
	[newItem setView:[item view]];
    }
    else
    {
	[newItem setImage:[item image]];
    }
    [newItem setToolTip:[item toolTip]];
    [newItem setTarget:[item target]];
    [newItem setAction:[item action]];
    [newItem setMenuFormRepresentation:[item menuFormRepresentation]];
    // If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
    // view won't show up at all!  This doesn't affect toolbar items with images, however.
    if ([newItem view]!=NULL)
    {
	[newItem setMinSize:[[item view] bounds].size];
	[newItem setMaxSize:[[item view] bounds].size];
    }

    return newItem;
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for the default
// set of toolbar items.  It can also be called by the customization palette to display the default toolbar.    
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"NodeHost",@"NodeName",@"CreateInspector",NSToolbarSeparatorItemIdentifier,@"Connect",@"Run",@"Time",NSToolbarPrintItemIdentifier,nil];
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for all allowed
// toolbar items in this toolbar.  Any not listed here will not be available in the customization palette.
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"NodeHost",@"NodeName",@"CreateInspector",NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier,NSToolbarFlexibleSpaceItemIdentifier,@"Time",@"Connect",@"Run",NSToolbarPrintItemIdentifier,nil];
}


@end

