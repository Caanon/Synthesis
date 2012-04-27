//
//  SIMHistogram.m
//  Desiderata
//
//  Created by Sean Hill on Tue Sep 02 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "SIMHistogram.h"


@implementation SIMHistogram

+ histogramWithData:(NSValueArray *)values numberOfBins:(unsigned)count rangeStart:(double)min end:(double)max
{
    SIMHistogram *hist = [[SIMHistogram alloc] initWithNumberOfBins:count rangeStart:min end:max];
    [hist setValues:values];
    return [hist autorelease];
}

+ histogramWithNumberOfBins:(unsigned)count rangeStart:(double)min end:(double)max
{
    SIMHistogram *hist = [[SIMHistogram alloc] initWithNumberOfBins:count rangeStart:min end:max];
    return [hist autorelease];
}


- init 
/*"
 Inits the histogram with 10 bins ranging from 0 to 1 
"*/
{
    return [self initWithNumberOfBins:10 rangeStart:0.0 end:1.0];
}

- initWithNumberOfBins:(int)numBins rangeStart:(double)start end:(double)end
{
    [self setNumberOfBins:numBins];
    [self setRangeStart:start end:end];
    [self setShouldBufferValues:NO];
    return self;
}

- (NSValueArray *)rangeValues
{
    return (NSValueArray *)[[rangeValues copy] autorelease];
}

- (NSValueArray *)binValues
{
    return (NSValueArray *)[[binValues copy] autorelease];
}

- (void)setValues:(NSArray *)values
{
    [self _clearBinValues];

    if(!bufferFlag) {
// Don't buffer the values.  Calc histogram directly
        [self _updateBinsFromValues:values];
        return; 
    }
    [bufferValues autorelease];
    bufferValues = (NSMutableArray *)[values retain];
    [self _updateBinsFromValues:bufferValues];
}

- (void)clearBins
{
    [self _clearBinValues];
}

- (void)addDouble:(double)val
{
    if(!bufferFlag) {
// Don't buffer the values.  Calc histogram directly
        [self _incrementBinForValue:val];
        return; 
    }
    [bufferValues addObject:[NSNumber numberWithDouble:val]];
}

- (void)addNumber:(NSNumber *)val
{
    if(!bufferFlag) {
// Don't buffer the values.  Calc histogram directly
        [self _incrementBinForValue:[val doubleValue]];
        return; 
    }
    [bufferValues addObject:val];
}

- (void)addValues:(NSArray *)values
{
    if(!bufferFlag) {
// Don't buffer the values.  Calc histogram directly
        [self _updateBinsFromValues:values];
        return; 
    }
    [bufferValues addObjectsFromArray:values];
}


- (void)setShouldBufferValues:(BOOL)flag
{
    bufferFlag = flag;
    
    if(!bufferFlag)[bufferValues release];
    else bufferValues = [[NSMutableArray array] retain];
}

- (BOOL)shouldBufferValues
{
    return bufferFlag;
}

- (void)setRangeStart:(double)min end:(double)max
{
    xmin = min; xmax = max;
    [self _updateRangeValues];
}

- (void)setNumberOfBins:(int)numBins
{
    n = numBins;
    [binValues release];
    binValues = [[NSMutableValueArray valueArrayWithCount:n withObjCType:@encode(double)] retain];
    bin = [binValues mutableBytes];

    [rangeValues release];
    rangeValues = [[NSMutableValueArray valueArrayWithCount:n+1 withObjCType:@encode(double)] retain];
    range = [rangeValues mutableBytes];
    [self _updateRangeValues];    
}

- (void)dealloc
{
    if(bufferValues)[bufferValues release];
    [super dealloc];
}

@end

@implementation SIMHistogram (SIMHistogramPrivate)

- (void)_updateHistogramFromBuffer
{
    if(bufferFlag){
        [self _clearBinValues];
        [self _updateBinsFromValues:(NSValueArray *)bufferValues];
    }
}

- (void)_updateBinsFromValues:(NSArray *)valuesArray
{
    int i, index, count;
        
    count = [valuesArray count];
    
    for(i = 0; i < count; i++){
        if(![self _findBinIndex:&index forValue:[[valuesArray objectAtIndex:i] doubleValue]]) bin[index]++;
    }
}

- (void)_incrementBinForValue:(double)val
{
    int index;
    if(![self _findBinIndex:&index forValue:val]) bin[index]++;
}


- (int)_findBinIndex:(int *)i forValue:(double)x
{
  int i_linear, lower, upper, mid;

  if (x < range[0])
    {
      return -1;
    }

  if (x >= range[n])
    {
      return +1;
    }

  {
    double u =  (x - range[0]) / (range[n] - range[0]);
    i_linear = (size_t) (u * n);
  }

  if (x >= range[i_linear] && x < range[i_linear + 1])
    {
      *i = i_linear;
      return 0;
    }

  /* perform binary search */

  upper = n ;
  lower = 0 ;

  while (upper - lower > 1)
    {
      mid = (upper + lower) / 2 ;
      
      if (x >= range[mid])
        {
          lower = mid ;
        }
      else
        {
          upper = mid ;
        }
    }

  *i = lower ;

  /* sanity check the result */

  if (x < range[lower] || x >= range[lower + 1])
    {
      //\\\\\\ that'aasdfasdfadsfasdfasdfadsfdasfasdfasdfasdfNSLog (@"SIMHistogram: Value %g not found in range",x);
    }

  return 0;
}

- (void)_updateRangeValues
{
    int i;
    for(i = 0; i < (n + 1); i++){
        range[i] = xmin + ((double) i / (double) n) * (xmax - xmin);
    } 
}

- (void)_clearBinValues
{
    int i;
    for(i = 0; i < n; i++)bin[i] = 0.0;
}


@end