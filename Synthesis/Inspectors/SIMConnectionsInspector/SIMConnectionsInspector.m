#import "SIMConnectionsInspector.h"

@implementation SIMConnectionsInspector

- (void)display
{
    int size = 2*[[object objectForKey:@"Radius"] intValue] + 1;
	
    [connectionsView initSize:size :size];
    [connectionsView setData:[self imageData]];
    [connectionsView setNeedsDisplay:YES];
}


- (NSData *)imageData
{
        NSMutableData	*data;
        NSArray *connections;
        int	index = 0;
        int	radius = [[object objectForKey:@"Radius"] intValue];
        int	size;
        NSValue *connectionValue;
        NSEnumerator *connectionEnumerator;
        SIMConnection aConnection;
        float *bytes;

        
        connections = [[object connectionsTemplate] retain];
        /*
        connectionEnumerator = [connections objectEnumerator];
        while(connectionValue = [connectionEnumerator nextObject]){
            [connectionValue getValue:&aConnection];
            radius = MAX(radius,MAX(aConnection.dy+1,aConnection.dx+1));
        }
        */
        size = 2*radius+1;
            
        data = [[NSMutableData dataWithLength:size*size*sizeof(float)] retain];
        bytes = (float *)[data mutableBytes];

        connectionEnumerator = [connections objectEnumerator];
        while(connectionValue = [connectionEnumerator nextObject]){
            [connectionValue getValue:&aConnection];
            index = ((radius+aConnection.dy)*size)+radius+
                            aConnection.dx;
            bytes[index] = aConnection.strength;
        }
        [connections release];

        return [data autorelease];
}

- (void)registerForNotifications
{
    [super registerForNotifications];
    [object addClient:self forNotificationName:SIMParameterDidChangeNotification
        selector:@selector(display) object:object];
}

- (void)unregisterForNotifications
{
    [super unregisterForNotifications];
}



@end
