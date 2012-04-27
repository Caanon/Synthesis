/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/Simulator.h>
#import <math.h>

#ifndef M_PI
    #define M_PI	3.14159265358979323846
#endif

#ifndef M_LN2
    #define M_LN2       0.69314718055994530942
#endif

double expx(double y);


void SIMSetStateValue(SIMStateValue *element,int index,id object);
id SIMGetStateValue(SIMStateValue *element,int index);

double SIMStateValueAsDouble(SIMStateValue *element,int index);
void SIMCopyConnection(SIMConnection *from, SIMConnection *to);
