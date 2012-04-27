//
//  SIMHistogram.h
//  Desiderata
//
//  Created by Sean Hill on Tue Sep 02 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSValueArray.h"


@interface SIMHistogram : NSObject {
    int n;
    BOOL bufferFlag;
    double xmin, xmax;
    double *range;
    double *bin;
    NSMutableValueArray *rangeValues;
    NSMutableValueArray *binValues;
    NSMutableArray *bufferValues;
}

+ histogramWithNumberOfBins:(unsigned)count rangeStart:(double)min end:(double)max;
+ histogramWithData:(NSValueArray *)values numberOfBins:(unsigned)count rangeStart:(double)rMin end:(double)rMax;

- init; /* Inits the histogram with 10 bins ranging from 0 to 1 */
- initWithNumberOfBins:(int)numBins rangeStart:(double)start end:(double)end;
- (NSValueArray *)rangeValues;
- (NSValueArray *)binValues;
- (void)setValues:(NSArray *)values;
- (void)addValues:(NSArray *)values;
- (void)addNumber:(NSNumber *)value;
- (void)addDouble:(double)val;
- (void)setShouldBufferValues:(BOOL)flag;
- (BOOL)shouldBufferValues;
- (void)setRangeStart:(double)start end:(double)end;
- (void)setNumberOfBins:(int)numBins;
- (void)clearBins;
- (void)dealloc;

@end

@interface SIMHistogram (SIMHistogramPrivate)

- (void)_updateHistogramFromBuffer;
- (void)_updateBinsFromValues:(NSArray *)valueArray;
- (void)_incrementBinForValue:(double)val;
- (int)_findBinIndex:(int *)i forValue:(double)x;
- (void)_updateRangeValues;
- (void)_clearBinValues;

@end