#import <AppKit/AppKit.h>
#import <Desiderata/NSValueArray.h>
#import <SynthesisInterface/SIMInspector.h>
#import <SynthesisInterface/SIMColorDataView.h>
#import <SynthesisCore/Simulator.h>

@interface SIMConnectionsInspector : SIMInspector
{
    id	connectionsView;
}
- (NSData *)imageData;

@end
