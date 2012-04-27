#import "PRNGenerator.h"

#define SOBOL_START_SEQUENCE	1	// Which Sobol sequence
// adapted from Numerical Recipes sobseq ()
// (same except uses double instead of float)
// nextDouble() returns the next value in the 1st sobol sequence,
// distributed between 0 and 1 

static int iminarg1, iminarg2;
#define IMIN(a,b)(iminarg1=(a),iminarg2=(b),(iminarg1)<(iminarg2) ?(iminarg1) : (iminarg2))

@implementation PRNSobolGenerator

- init
{
    unsigned long 	tm [MAXDIM+1] = {0,1,2,3,3,4,4};
    unsigned long 	tip[MAXDIM+1] = {0,0,1,1,2,1,4};
    unsigned long 	tiv[MAXDIM*MAXBIT+1] = {
		0,1,1,1,1,1,1,3,1,3,3,1,1,5,7,7,3,3,5,15,11,5,15,13,9};
    [super init];
    memcpy (mdeg, tm, (MAXDIM+1) * sizeof (unsigned long));
    memcpy (ip, tip, (MAXDIM+1) * sizeof (unsigned long));
    memcpy (iv, tiv, (MAXDIM*MAXBIT+1) * sizeof (unsigned long));
    [self setSequenceNum: 1];
    [self setNumSequences: 1];
    [self startSobol];
    return self;
}

- (double) nextDouble
{
	if(seqNum>=numSeq) {
		seqNum = 1;
		[self sobseqd:numSeq :seq];
	}
	return seq[seqNum++];
}

- (void)setNumSequences:(int)n
{
	if(n<MAXDIM && n>=0)numSeq=n+1;
	else numSeq = 1;
}

- setSeed: (int) seed
{
	[self setSequenceNum: seed %(MAXDIM-1) + 1];  // any better ideas?
	return self;
}

- (void) setSequenceNum: (int) n
{ if(seqNum<=0)seqNum=1;else seqNum = n; }

-  (void) startSobol
{ 
	[self sobseqd: (-1)]; //: sobol - 1];
}

- (double) sobseqd: (int) n
/*
When n is negative, internally initializes a set of MAXBIT direction 
numbers for each of MAXDIM different Sobol sequences and returns 0.  
When n is positive (but <= MAXDIM), returns the next value of the 
n-th sequence, distributed between 0 and 1.
(n must not be changed between initializations.)
*/
{
	double retval = 0;	
    int	j,k,l;
    unsigned long i,im,ipp;
    if (n < 0) {		/* Initialize, don't return a vector.  */
		for (j = 1, k = 0; j <= MAXBIT; j++, k+= MAXDIM) 
			iu[j] = &iv[k];
		/* To allow both 1D and 2D addressing.  */
		for (k=1; k<=MAXDIM; k++) {
			for (j = 1; j <= mdeg[k]; j++) 
				iu[j][k] <<= (MAXBIT-j);
			/* Stored values only require normalization.  */
			for (j = mdeg[k] + 1; j <= MAXBIT; j++){
				ipp = ip[k];
				i = iu[j-mdeg[k]][k];
				i ^= (i>>mdeg[k]);
				for (l=mdeg[k]-1;l>=1;l--){
					if (ipp&1)
						i ^= iu[j-l][k];
					ipp >>=1;
				}
				iu[j][k]=i;
			}
		}
		fac = 1.0 / (1L << MAXBIT);
		in = 0;
    }
    else {
		im = in;
		for (j = 1; j<= MAXBIT; j++) {
			if (!(im&1)) break;
			im >>= 1;
		}
		if (j > MAXBIT) 
			NSLog (@"MAXBIT too small in sobseq\n");
		im = (j - 1) * MAXDIM;
		for (k = 1; k <= IMIN (n, MAXDIM); k++){
			ix[k] ^= iv[im + k];
			retval = ix[k] * fac;
		}
		in++;
    }
	return retval;
}

- (void) sobseqd: (int) n: (double *) x
/*
When n is negative, internally initializes a set of MAXBIT direction 
numbers for each of MAXDIM different Sobol sequences.  When n is positive 
(but <= MAXDIM), returns as a vector x[1..n] the next values from n of 
these sequences, distributed between 0 and 1.
(n must not be changed between initializations.)
*/
{
	
    int	j,k,l;
    unsigned long i,im,ipp;
	
    if (n < 0) {		/* Initialize, don't return a vector.  */
		for (j=1,k=0;j<=MAXBIT;j++,k+=MAXDIM) 
			iu[j]=&iv[k];
		/* To allow both 1D and 2D addressing.  */
		for (k=1; k<=MAXDIM; k++) {
			for (j = 1; j <= mdeg[k]; j++) 
				iu[j][k] <<= (MAXBIT-j);
			/* Stored values only require normalization.  */
			for (j = mdeg[k] + 1; j <= MAXBIT; j++){
				ipp = ip[k];
				i = iu[j-mdeg[k]][k];
				i ^= (i>>mdeg[k]);
				for (l=mdeg[k]-1;l>=1;l--){
					if (ipp&1)
						i ^= iu[j-l][k];
					ipp >>=1;
				}
				iu[j][k]=i;
			}
		}
		fac = 1.0 / (1L << MAXBIT);
		in = 0;
    }
    else {
		im = in;
		for (j = 1; j<=MAXBIT; j++) {
			if (!(im&1)) break;
			im >>= 1;
		}
		if (j > MAXBIT) 
			NSLog (@"MAXBIT too small in sobseq\n");
		im = (j - 1) * MAXDIM;
		for (k = 1; k <= IMIN (n, MAXDIM); k++){
			ix[k] ^= iv[im + k];
			x[k]= ix[k] * fac;
		}
		in++;
    }
}

@end
