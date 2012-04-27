
#include <SynthesisCore/RungeKutta4.h>
#include <SynthesisCore/Simulator.h>
/*"
    This function computes the new value of y(t) via the Runge-Kutta 4th-order method
    using the description of dy/dt provided by the function derivs().  
"*/
void evaluateRungeKutta4(int n, float x, float h, SIMStateValue *y, SIMStateValue *dydx, SIMStateValue *yout, SIMStateValue *dym, SIMStateValue *dyt, SIMStateValue *yt, void (*derivs)(id, SEL, SIMStateValue *, SIMStateValue *, float, SIMState *),id obj, SEL selector, SIMState *context)
{
    int i;
    double xh, hh, h6;

    hh = h * 0.5;
    h6 = h / 6.0;

    xh = x + hh;

    for (i = 0; i < n; i++)
        if(y[i].type < SIMObjectType) yt[i].state.doubleValue = y[i].state.doubleValue + hh * dydx[i].state.doubleValue;
    (*derivs)(obj,selector,dyt,yt,xh,context);
    for (i = 0; i < n; i++)
        if(y[i].type < SIMObjectType) yt[i].state.doubleValue = y[i].state.doubleValue + hh * dyt[i].state.doubleValue;
    (*derivs)(obj,selector,dym,yt,xh,context);
    for (i = 0; i < n; i++){
        if(y[i].type < SIMObjectType) yt[i].state.doubleValue = y[i].state.doubleValue + h * dym[i].state.doubleValue;
        dym[i].state.doubleValue += dyt[i].state.doubleValue;
    }
    (*derivs)(obj,selector,dyt,yt,x+h,context);
    for (i = 0; i < n; i++)
        if(y[i].type < SIMObjectType) yout[i].state.doubleValue = y[i].state.doubleValue + h6 * (dydx[i].state.doubleValue + dyt[i].state.doubleValue + 2.0 * dym[i].state.doubleValue);

}