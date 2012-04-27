#import "PRNGenerator.h"
#ifndef M_PI
#define  M_PI            3.14159265358979323846
#endif

float gammln (float xx)
// NR 6.1 - returns the value ln [Gamma (xx)] for xx > 0
{
	// full double precision internal arithmetic here
	double x, y, tmp, ser;
	static double cof[6] = {76.18009172947146, -86.50532032941677,
							24.01409824083091, -1.231739572450155,
							0.1208650973866179e-2, -0.5395239384953e-5};
	int j;
	
	y = x = xx;
	tmp = x + 5.5;
	tmp -= (x + 0.5) * log (tmp);
	ser=1.000000000190015;
	for (j = 0; j <= 5; j++)
		ser += cof[j] / ++y;
	return -tmp + log (2.5066282746310005 * ser / x);
}

@implementation PRNPoissonGenerator

/* poisson distribution */

- (double) poissonDeviate
{
        static float sq,alxm,g,oldm=(-1.0);
        float em,t,y;
        float xm = [self mean];

        if (xm < 12.0) {
                if (xm != oldm) {
                        oldm=xm;
                        g=exp(-xm);
                }
                em = -1;
                t=1.0;
                do {
                        em += 1.0;
                        t *= [super nextDouble];
                } while (t > g);
        } else {
                if (xm != oldm) {
                        oldm=xm;
                        sq=sqrt(2.0*xm);
                        alxm=log(xm);
                        g=xm*alxm-gammln(xm+1.0);
                }
                double val = [super nextDouble];
                do {
                        do {
                                y=tan(M_PI*[super nextDouble]);
                                em=sq*y+xm;
                        } while (em < 0.0);
                        em=floor(em);
                        t=0.9*(1.0+y*y)*exp(em*alxm-gammln(em+1.0)-g);
                } while (val > t);
        }
        return em;
}

- (double) nextDouble
{
    return [self poissonDeviate];
}

/*- (double) poissonDeviate
{
	// NR 7.3 poidev() - returns an integer value (as a double) 
	// that is a random deviate drawn from a poisson distribution  
	// with mean = [self mean]
	// based on class PRNMarsagliaGenerator
	float gammln (float xx);
	static float sq, alxm, g, oldm = (-1.0); // flag whether xm changed
	float em, t, y, xm = [self mean];
	
	if (xm < 12.0) { // use direct method
		if (xm != oldm) {
			oldm = xm;
			g = exp (-xm);
		}
		em = -1;
		t = 1.0;
		do {
			++em; 
			t *= [super nextDouble];
		} while (t > g);
	} else {
		if (xm != oldm) {
			oldm = xm;
			sq = sqrt (2.0 * xm);
			alxm = log (xm);
			g = xm * alxm - gammln (xm + 1.0); // ln of gamma function
		}
	}
	do {
		do {
			y = tan (M_PI * [super nextDouble]);
			em = sq * y + xm;
		} while (em < 0.0);
		em = floor (em);
		t = 0.9 * (1.0 + y * y) * exp (em * alxm - gammln (em + 1.0) - g);
	} while ([super nextDouble] > t);
	return em;
}

*/

@end
