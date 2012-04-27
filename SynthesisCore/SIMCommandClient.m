/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/SIMCommandClient.h>
#import <readline/readline.h>
#import <readline/history.h>

jmp_buf iContext;

void signalInterruptRestore()
{
   signal(SIGINT,&signalInterruptRestore);
   printf("\nInterrupt\n");
   longjmp(iContext,0);
}

#define SIMPrompt()	[self displayPrompt]

@implementation SIMCommandClient

+ (void) runCommandPrompt
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *script,*host;
    SIMCommandClient *commandInterpreter;
    NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:SERVER_NAME_KEY];
    if(!name){
        name = DEFAULT_SERVERNAME;
        [[NSUserDefaults standardUserDefaults] setObject:name forKey:SERVER_NAME_KEY];
    }

    host = [[NSUserDefaults standardUserDefaults] stringForKey:HOST_KEY];
    if(!host){
        host = nil;//[[NSHost currentHost] name];
    }

    commandInterpreter = [[SIMCommandClient alloc] initWithServer:name host:host];

    if(script = [[NSUserDefaults standardUserDefaults] stringForKey:SCRIPT_KEY]){
        NSString *command = [NSString stringWithFormat:@"loadScript %@",[script stringByStandardizingPath]];
        [commandInterpreter interpretCommand:command];
    }

    //if([[NSUserDefaults standardUserDefaults] boolForKey:INTERACTIVE_KEY])

    /* If this point is passed, interupts are intercepted
    * and control is restored at beginning of interpreter loop.
    */
    if (signal(SIGINT, SIG_IGN) != SIG_IGN)
        signal(SIGINT, &signalInterruptRestore);
    setjmp(iContext);

    [commandInterpreter runCommandPromptWithReadline];

    [[NSRunLoop currentRunLoop] run];
    [pool release];
    [NSThread exit];
}

- initWithServer:(NSString *)serverName host:(NSString *)hostName
/*" Check to see if the server is a node server.  If so then initialize using the server's nodeInfo "*/
{
    if(![self registerWithServer:serverName host:hostName])NSLog(@"Couldn't find a server to connect to.");
    inputHandle = [[NSFileHandle fileHandleWithStandardInput] retain];

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(handleInput:)
        name:NSFileHandleDataAvailableNotification
        object:inputHandle];
    
    return self;
}

- (BOOL)registerWithServer:(NSString *)sName host:(NSString *)hName
{
	NSConnection *connection;
	if([hName isEqual:@""])
		connection  = [NSConnection connectionWithRegisteredName:sName host:nil];
	else {
		NSSocketPort *port = (NSSocketPort *)[[NSSocketPortNameServer sharedInstance] portForName:sName host:hName];
		connection = [NSConnection connectionWithReceivePort:nil sendPort:port];
	}

    if(!connection)return NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(serverConnectionDidDie:)
        name:NSConnectionDidDieNotification
        object:connection];

    if(server == nil)server = [[connection rootProxy] retain];

    if(server){
        /* Setup for commandline logging of status events */
        [server addClient:self forNotificationName:SIMStatusUpdateNotification selector:@selector(logEvents:) object:nil];
        [server addClient:self forNotificationName:SIMErrorUpdateNotification selector:@selector(logErrors:) object:nil];
        return YES;
    }
    else return NO;
}

- (void)displayPrompt
{
    printf([[self prompt] UTF8String]);fflush(stdout);
}

- (NSString *)prompt
{
    NSString *prompt;
    
    if(server){
        prompt = [NSString stringWithFormat:@"[%@:%d] t=%0.2f %@>",[server serverName:nil],[server nodeIdentifier],[[server time:nil] floatValue],[server pwd:nil]];
    }
    else prompt = @"-Disconnected- >";
    return prompt;
}

- (void)runCommandPromptWithReadline
{
    char *command;
    
    using_history();               /* enable command line history */

    while(1) {
        /* loop indefinitely            */
        command = readline([[self prompt] UTF8String]);
        if(!command) {                  /* this is EOF                 */
            break;
        }

        /* we need to add lines to the history */
        if(strlen(command)) {
            // should have option to log in server-side log
            add_history(command);
        }
        
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
        [self interpretCommand:[NSString stringWithCString:command]];
    }
}


- (void)runCommandPrompt
{
    NSArray *modes = [NSArray arrayWithObjects:NSConnectionReplyMode,NSDefaultRunLoopMode,nil];
    [self displayPrompt];
    [inputHandle waitForDataInBackgroundAndNotifyForModes:modes];
}

- (void)handleInput:(NSNotification *)notify
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *command,*newCommand;
    NSScanner *commandScanner;
    NSCharacterSet *lfcrSet = [[NSCharacterSet characterSetWithCharactersInString:@"\r\n"] retain];
    NSMutableData *data;
    char nullByte = '\0';
    NSRange range;
    
    data = [[[notify object] availableData] mutableCopy];

    if([data length] > 0){
        range.location = [data length]-1;
        range.length = 1;
        [data replaceBytesInRange:range withBytes:&nullByte];
        command = [[NSString stringWithCString:[data bytes]] retain];
    }
    else {
        command = @"";
    }
    commandScanner = [[NSScanner scannerWithString:command] retain];
    if([commandScanner scanUpToCharactersFromSet:lfcrSet intoString:&newCommand]){
        if([self interpretCommand:newCommand]){
            [self runCommandPrompt];
        }
    }
    else [self runCommandPrompt];
    
    [lfcrSet release];
    [data release];
    [pool release];
}

- (void)runCommandPrompt_old
{
    char line[SIM_MAX_PATH_LENGTH];


    /* If this point is passed, interupts are intercepted
    * and control is restored at beginning of interpreter loop.
    */
        if (signal(SIGINT, SIG_IGN) != SIG_IGN)
            signal(SIGINT, &signalInterruptRestore);
        setjmp(iContext);

    /* infinite loop broken from inside upon reading
    *  a 'done' command.
    */
    while (YES) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        int strlength;
        NSString *command;
        SIMPrompt();
        /* reads a new command line and parses it */
        fgets(line,SIM_MAX_COMMAND_LENGTH,stdin);

        strlength = strlen(line);
        if (strlength > 0) line[strlength-1] = '\0';
        command = [NSString stringWithCString:line];
        if (![self interpretCommand:command]) {[pool release]; return;}
        [pool release];
    }
}

- (BOOL)interpretCommand:(NSString *)commandString
{
    SEL command;
    NSString *commandName;
    NSArray *argumentArray;
    
    commandString = [[commandString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] retain];
    
   /* is line a comment? */
    if ([commandString hasPrefix:@"//"]) {
        return YES;
    }

    if ([commandString hasPrefix:@"!"]) {
        argumentArray = [[NSArray arrayWithObjects:@"clientShellCommand",[commandString substringFromIndex:1],nil] retain];
    }
    else{
        argumentArray = [[commandString componentsSeparatedByString:@" "] retain];
    }

    commandName = [argumentArray objectAtIndex:0];


   /* tests for null instruction */
    if ([commandName isEqual:@""]) {
        return YES;
    }

    if ([commandName isEqual:@"quit"]) {
        if(server){
            [server removeClient:self];
            [server release];
        }
        exit(0);
    }

    if ([commandName isEqual:@"done"]) {
        return NO;
    }


   /* substitute alias */
    // something like if ([aliasDict containsObject:command])command = [aliasDict objectWithKey:]

    /* first tries the command on the local object*/
    command = [[commandName stringByAppendingString:@":"] selectorValue];
    if ([self respondsToSelector:command]) {
        id answer = [self performSelector:command withObject:[argumentArray autorelease]];
        if(answer)printf("%s\n",[[answer description] UTF8String]);
    } else {
        id answer = nil;
        /* delegates command to server */
        NS_DURING
            answer = [server interpretCommand:commandString];
        NS_HANDLER
            NSLog ([localException name]);
            NSLog ([localException reason]);
            //[self disconnect:nil];
        NS_ENDHANDLER
        if(answer)printf("%s\n",[[answer description] UTF8String]);
    }
    [commandString release];
    return YES;
}

- disconnect:(NSArray *)argumentArray
{
    if(server)[server release];
    server = nil;
    return @"Disconnected";
}

- connect:(NSArray *)argumentArray
{
    NSString *hname,*sname;

    hname = @"";//[[NSHost currentHost] name];
    sname = DEFAULT_SERVERNAME;

    if([argumentArray count] > 2){
        sname = [argumentArray objectAtIndex:1];
        hname = [argumentArray objectAtIndex:2];
    }
    else {
        if([argumentArray count] == 2){
            sname = [argumentArray objectAtIndex:1];
        }
    }
    return [self registerWithServer:sname host:hname]?[NSString stringWithFormat:@"Connected to %@ on %@.",sname,hname]:[NSString stringWithFormat:@"Couldn't connect to %@ on %@.",sname,hname];
}

- terminate:(NSArray *)argumentArray
{
     if(server){
         [server terminate:argumentArray];
         server = nil;
     }
     return nil;
 }

- clientShellCommand:(NSArray *)argumentArray
{
    if([argumentArray count] == 2) {
        system([[argumentArray objectAtIndex:1] UTF8String]);
    }
    return @"";
}

- loadScript:(NSArray *)argumentArray
{
    if([argumentArray count] == 2){
        NSString *myScript = [NSString stringWithContentsOfFile:[[argumentArray objectAtIndex:1] stringByStandardizingPath]];
        if(myScript){
            [self interpretScript:myScript];
            return [NSString stringWithFormat:@"Executed script: %@.",[argumentArray objectAtIndex:1]];
        }
        else return [NSString stringWithFormat:@"Couldn't load script: %@.",[argumentArray objectAtIndex:1]];
    }
    else return @"USAGE: loadScript <filename>";
}

- (BOOL) interpretScript:(NSString *)script
{
    NSScanner *scriptScanner = [NSScanner scannerWithString:script];
    NSString *command;

    if([script isKindOfClass:[NSArray class]])return NO;

    while ([scriptScanner isAtEnd] == NO) {
        NSCharacterSet *lfcrSet = [NSCharacterSet characterSetWithCharactersInString:@"\r\n"];
        [scriptScanner scanUpToCharactersFromSet:lfcrSet intoString:&command];
        [scriptScanner scanCharactersFromSet:lfcrSet intoString:NULL];
        printf("SCRIPT> %s\n",[command UTF8String]);
        [self interpretCommand:command];
    }
    return YES;
}

- (void) serverConnectionDidDie:(NSNotification *)n
{
    NSLog(@"Lost connection to network command controller.");
    [server release];
    server = nil;
    //SIMPrompt();
}


- (void) logEvents:(NSNotification *)n
{
    NSDictionary *info = [n userInfo];
    if(info){
        NSString *status = [info objectForKey:SIMStatusDescriptionKey];
        if(status)fprintf(stdout,"STATUS: %s\n",[status UTF8String]);
    }
}

- (void) logErrors:(NSNotification *)n
{
    NSDictionary *info = [n userInfo];
    if(info){
        NSString *status = [info objectForKey:SIMStatusDescriptionKey];
        if(status)fprintf(stdout,"ERROR: %s\n",[status UTF8String]);
    }
}



@end
