
#import <stdlib.h>
#import <objc/objc.h>
#import <stdio.h>
#import <math.h>

/* interpolation methods */

typedef enum {
    ITABLE_CEIL = 0,
    ITABLE_ROUND,
    ITABLE_LINEAR,
    ITABLE_FIXED
} ITableMethod;

/* data structure for an interpolation table between (x,y) points */
typedef struct _ITable {
    float xmin;		/* minimun x value */
    float xmax;		/* maximum x value */
    int xnum;		/* number of interpolation points */
    float dx;		/* increment of x */
    float *data;	/* table */
    float xshift;	/* x offset */
    float yshift;	/* y offset */
    float xscale;	/* x scaling */
    float yscale;	/* y scaling */
    ITableMethod method; /* interpolation method */
} ITable;

ITable *ITLoadTable(const char *filepath);
ITable *ITLoadTableLinear(const char *filepath);
float ITOutputTable(ITable *itable,float input);
ITable *ITAllocTable(float xmin,float xmax,int xnum);
void ITFreeTable(ITable *itable); 

//TIMADD

BOOL ITLoadTables(ITable **, ITable **, char*);
void ITXShiftTable(ITable *, float);
void ITYShiftTable(ITable *, float);
void ITXScaleTable(ITable *, float);

void ITYScaleTable(ITable *, float);




double _round(double x);
double _factorial(double x);
