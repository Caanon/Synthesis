/*   SynthesisCore
 *   (c) 2003  Sean Hill
 *   Permission granted to freely use this code for educational and non-profit research purposes only.
 *   Commercial use requires a license from the author.
 */

#import <SynthesisCore/Simulator.h>

void evaluateRungeKutta4(int n, float x, float h, SIMStateValue *y, SIMStateValue *dydx, SIMStateValue *yout, SIMStateValue *dym, SIMStateValue *dyt, SIMStateValue *yt, void (*derivs)(id, SEL, SIMStateValue *, SIMStateValue *, float, SIMState *),id obj, SEL selector, SIMState *context);

