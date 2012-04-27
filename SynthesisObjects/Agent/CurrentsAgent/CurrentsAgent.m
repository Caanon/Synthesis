/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All rights reserved.
 *   Usage and/or disclosure of this source code is restricted to authorized persons only.
 *
 *   CurrentsAgent.m created by shill on Thu 06-Jan-1999
 */

#import "CurrentsAgent.h"
#import <SynthesisCore/SIMNetworkInfo.h>

@implementation CurrentsAgent

- init
{
    [super init];
    fout = (FILE *)nil;
    return self;
}

- (void) gatherData
{
    NSString *typeKey;
    NSEnumerator *typesEnum = [typesArray objectEnumerator];
    float t = [network time];
    float dt = [network dt];

    if(!fout)NSLog(@"ERROR: Data file not open.");
    if(0==fmod(floor(t/dt+.5)*dt,sampleInterval*dt)) {
        //fwrite(&t,sizeof(float),1,fout);
        while(typeKey = [typesEnum nextObject]){
            float val;
            if([currentType isEqual:@"Intrinsic"])
                val = [network intrinsicChannelCurrent:typeKey forCompartment:0 atPosition:&pos];
            else val = [network inputChannelCurrent:typeKey forCompartment:0 atPosition:&pos];
            //printf("%s %f\n",[typeKey UTF8String],val);
            fwrite(&val,sizeof(float),1,fout);
        }
    }
    // fflush(fout);
}

- (void) updateParameters
{
    [super updateParameters];

    if(filename)[filename autorelease];
    filename = [[self filePathForKey:@"Filename"] retain];

    sampleInterval = [self floatForKey:SIM_SAMPLEINTERVAL];
    if(0.0==sampleInterval) {
        sampleInterval = 1.0;
    }

    pos.z = [network indexForLayerWithKey:[self objectForKey:SIM_LAYER]];
    pos.x = [self intForKey:SIM_POSITION_X]; pos.y = [self intForKey:SIM_POSITION_Y];

    typesArray = [self objectForKey:SIM_TYPES];

    currentType = [self objectForKey:@"CurrentType"];
}

- (void) startAgent
{
    [super startAgent];

	[self createDataDirectory];

    if(fout){fclose(fout);fout = (FILE *)nil;}
    if(!(fout = fopen([filename UTF8String],"ab"))){
        NSLog(@"Could not open file %@.",filename);
    }
}

- (void) stopAgent
{
    [super stopAgent];

    if(fout){fclose(fout);fout = (FILE *)nil;}
}

@end
