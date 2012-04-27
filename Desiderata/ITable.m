/*
*
* ITable.m
*
* Routines to create and manipulate an interpolation table.
*
* Author: Erik Lumer - 07/94
* Adapted by Sean Hill - 08/99
* Added linear interpolation - Alix Herrmann 1/00
*/

#include "ITable.h"

ITable *ITAllocTable(float xmin,float xmax,int xnum)
/*" allocates and initializes an iTable with the 'ceiling' output lookup method
    (return the next largest table value).
"*/
{
  ITable *ptr;
  int i;
  
  if ((ptr = (ITable *) malloc(sizeof(ITable))) == NULL) {
    fprintf(stderr,"Error: Out of memory\n");
    return NULL;
  }
  ptr->xmin = xmin;
  ptr->xmax = xmax;
  ptr->xnum = xnum;
  if (xnum <= 0) {
    ptr->data = NULL;
    ptr->dx = 1.0;
  } else {
    if ((ptr->data = (float *) malloc(xnum*sizeof(float))) == NULL) {
      fprintf(stderr,"Error: Out of memory\n");
      free(ptr);
      return NULL;
    }
    for (i=0;i<xnum;i++) 
      ptr->data[i] = 0.0;
    if (xnum == 1)
      ptr->dx = xmax - xmin;
    else
      ptr->dx = (xmax - xmin)/(xnum - 1);
  }
  ptr->xshift = 0.0;
  ptr->yshift = 0.0;
  ptr->xscale = 1.0;
  ptr->yscale = 1.0;
  ptr->method = ITABLE_CEIL;

  return ptr;
}

ITable *ITLoadTable(const char *filepath)
/*" fills an iTable, 'itable',  with data in a file at 'filepath'.
	A new iTable is allocated. Returns a pointer to it.
"*/
{
   float xmin, xmax, val;
   int xnum, count=0;
   ITable *ptr;
   FILE *fileptr;
   
   /* open file and read first line */
   if ((fileptr = fopen(filepath,"r")) == NULL) {
     fprintf(stderr,"Error: Could not open file '%s'\n",filepath);
     return NULL;
   }
   if (fscanf(fileptr,"%f %f %d\n",&xmin,&xmax,&xnum) != 3) {
     fprintf(stderr,"Error: Invalid file format for a table\n");
     fprintf(stderr,"Error: Format must be:\n<xmin> <xmax> <xnum>\n");
     fprintf(stderr,"Y[0]\n...\nY[xnum-1]\n");
     fclose(fileptr);
     return NULL;
   }
   if ((ptr = ITAllocTable(xmin,xmax,xnum)) == NULL) {
     fclose(fileptr);
     return NULL;
   }
   /* read table values */
   while (fscanf(fileptr,"%f\n",&val) != EOF && count < xnum) {
     ptr->data[count] = val;
     count++;
   }
   /* if too few values, complete table with 0's */
   if (count < xnum) {
     fprintf(stderr,"Warning: Incomplete iTable. Padding with 0's\n");
     while (count < xnum) {
       ptr->data[count] = 0.0;
       count++;
     }
   }
   fclose(fileptr);
   return ptr;
}

ITable *ITLoadTableLinear(const char *filepath)
/*" allocates and initializes an iTable with the output lookup method 'Linear'. This method is slower, but more accurate than the 'ceiling' method. "*/
{
    ITable *ptr = ITLoadTable(filepath);
    ptr->method = ITABLE_LINEAR;
    return ptr;
}

BOOL ITLoadTables(table1,table2,filepath)
/*" fills two tables at once "*/
  ITable **table1, **table2;
  char * filepath;
{
   float xmin, xmax;
   int xnum, count=0;
   FILE *fileptr;
   
   /* free existing tables */
   if (*table1 != NULL) free(*table1);
   if (*table2 != NULL) free(*table2);
   /* open file and read first line */
   if ((fileptr = fopen(filepath,"r")) == NULL) {
     fprintf(stderr,"Error: Could not open file '%s'\n",filepath);
     return NO;
   }
   if (fscanf(fileptr,"%f %f %d\n",&xmin,&xmax,&xnum) != 3) {
     fprintf(stderr,"Error: Invalid file format for 2 tables\n");
     fprintf(stderr,"Error: Format must be:\n<xmin> <xmax> <xnum>\n");
     fprintf(stderr,"Yt[0] Yinf[0]\n...\nYt[xnum-1] Yinf[xnum-1]\n");
     return NO;
   }
   /* allocate tables */
   if ((*table1 = ITAllocTable(xmin,xmax,xnum)) == NULL) {
     fclose(fileptr);
     return NO;
   }
   if ((*table2 = ITAllocTable(xmin,xmax,xnum)) == NULL) {
     fclose(fileptr);
     free(*table1);
     return NO;
   }
   /* read table values */
   while (fscanf(fileptr,"%f %f\n",&((*table1)->data[count]),
		&((*table2)->data[count])) != EOF && count < xnum) {
     count++;
   }
   /* if too few values, complete table with 0's */
   if (count < xnum) {
     fprintf(stderr,"Warning: Incomplete iTable. Padding with 0's\n");
     while (count < xnum) {
       (*table1)->data[count] = 0.0;
       (*table2)->data[count] = 0.0;
       count++;
     }
   }
   fclose(fileptr);
   return YES;
}

float ITOutputTable(ITable *itable,float input)
/*" interpolates from data in itable using the lookup method itable->method. "*/
{
  int i;

  if (itable == NULL || itable->data == NULL) return (-1);
  switch (itable->method) {
    case (ITABLE_ROUND):
        i = (int) _round((input - itable->xmin)/itable->dx);
        if (i >= 0 && i < itable->xnum) {
            return itable->data[i];
        } else
        if (i < 0) {
            return itable->xmin;
        } else {
            return itable->xmax;
        }
    case (ITABLE_CEIL):
        i = (int) ceil((input - itable->xmin)/itable->dx);
        if (i >= 0 && i < itable->xnum) {
            return itable->data[i];
        } else
        if (i < 0) {
            return itable->data[0];
        } else {
            return itable->data[itable->xnum-1];
        }
        break;
    case (ITABLE_LINEAR):
        if ((input >= itable->xmin) && (input < itable->xmax)) {
            i = (int) floor((input - itable->xmin)/itable->dx);
            return itable->data[i]
                + ((float) i * itable->dx - itable->data[i])
                * (itable->data[i+1] - itable->data[i]);
        } else if (input < itable->xmin) {
            return itable->data[0];
        } else {
            return itable->data[itable->xnum-1];
        }
        break;
    case (ITABLE_FIXED):
        break;
  }
  return 0.0;
}

void ITXShiftTable(ITable *itable, float shift)
/*" shifting and scaling of table "*/
{
   if (itable == NULL) return;
   /* remove previous shift and add new one */
   itable->xmin = itable->xmin - itable->xshift + shift;
   itable->xmax = itable->xmax - itable->xshift + shift;
   itable->xshift = shift;
}
  
void ITYShiftTable(ITable *itable, float shift) 
{
   int i;

   if (itable == NULL || itable->data == NULL) return;
   /* remove previous shift and add new one */
   for (i=0;i<itable->xnum;i++) {
     itable->data[i] = itable->data[i] - itable->yshift + shift;
   }
   itable->yshift = shift;
}

void ITXScaleTable(ITable *itable,float scale) 
{
   if (itable == NULL) return;
   /* remove shift */
   itable->xmin -= itable->xshift;
   itable->xmax -= itable->xshift;
   /* change scale */
   if (itable->xscale != 0) {
     itable->xmin = itable->xmin/itable->xscale*scale;
     itable->xmax = itable->xmax/itable->xscale*scale;
   }
   itable->xscale = scale;
   /* restore shift */
   itable->xmin += itable->xshift;
   itable->xmax += itable->xshift;
}
  
void ITYScaleTable(ITable *itable, float scale)
{
   int i;

   if (itable == NULL) return;
   /* remove shift */
   for (i=0;i<itable->xnum;i++) {
     itable->data[i] -= itable->yshift;
   }
   /* change scale */
   if (itable->yscale != 0) {
     for (i=0;i<itable->xnum;i++) {
       itable->data[i] = itable->data[i]/itable->yscale*scale;
     }
   }
   itable->yscale = scale;
   /* restore shift */
   for (i=0;i<itable->xnum;i++) {
     itable->data[i] += itable->yshift;
   }
}
  
void ITFreeTable(ITable *itable)
/*" free itable "*/
{
  if (itable != NULL) {
    if (itable->data != NULL) free(itable->data);
    free(itable);
  }
}


double _round(double x)
/*" rounds a float "*/
{
  double r;

  r = ceil(x);
  if((x - r) == 0)
    return r;
  else
    return r+1;
}

double _factorial(double x)
/*" factorial "*/
{
  double fact = 1.0;

  while (x >= 1) {
   fact *= x--;
  }
  return fact;
}

