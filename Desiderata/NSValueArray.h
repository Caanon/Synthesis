// Under FoundationKit, you could use an NSArray of NSValue instances
// to achieve somewhat the same effect as a Storage under earlier
// versions of NeXTSTEP.  One major difference is that if all of
// the values in the array are of the same type, Storage is more
// space-efficient because it doesn't require the extra object
// overhead.  [The NSArray+NSValue version requires 1+N objects,
// while Storage requires 1 object.]  Furthermore, the NSArray+NSValue
// version will require about 2+2N separate mallocs, while the
// Storage version only requires 2 mallocs.  [Each malloc has some
// overhead, and on some systems may have more overhead due to
// memory granularity concerns.]
//
// For small systems, this is reasonable.  But for large systems,
// it is not.
//
// NSValueArray is a variation on NSArray which provides
// a Storage-style abstraction which can also be accessed like an
// NSArray of NSValue instances.  Internally it uses an NSData
// instance to store the value data, which is transparently
// (hopefully) converted to and from NSValue instances as necessary.
// It also can be accessed somewhat like an NSArray instance extended
// to contain NSValue all of the same type.
//
// The archiving format is exactly that of NSArray.  This ability depends on
// the existence of the function NSGetSizeAndAlignment().  The archive written
// by this object can be read by an NSArray transparently.  If you choose to load a
// prearchived NSArray or NSMutableArray using a NSValueArray it must have contained
// only NSValues of the same type.  These will then be stored internally in an efficient
// manner.  These could be stored more efficiently however the convenience of having
// an archive format identical to that of NSArrays was too alluring.
//
// Documentation?  We don't need no stinking documentation!
//
// There are sections of this object which are guaranteed to be untested.  The object
// itself has been used extensively however the methods which replace and insert, etc 
// have not been.  There is also certainly performance tuning which could be done.
// 
//
// Rewritten for OpenStep, 1996 Sean Hill, shill@iphysiol.unil.ch
// Originally by Scott Hess, shess@winternet.com

#import <Foundation/Foundation.h>

@interface NSValueArray : NSArray
+ valueArray:(const void *)values count:(unsigned)count withObjCType:(const char *)type;
- initWithValues:(const void *)values count:(unsigned)count withObjCType:(const char *)type;
-(void)getValue:(void *)value atIndex:(unsigned)index;
- (NSValueArray *)valueArrayFromRange:(NSRange)range;
-(const char *)objCType;
-(unsigned)valueSize;
-(const void *)bytes;
- mutableCopyFromZone:(NSZone *)zone;
- copyFromZone:(NSZone *)zone;

@end

@interface NSMutableValueArray : NSMutableArray
+ valueArray:(const void *)values count:(unsigned)count withObjCType:(const char *)type;
+ valueArrayWithObjCType:(const char *)type;
+ valueArrayWithCount:(unsigned)count withObjCType:(const char *)type;
- initWithValues:(const void *)values count:(unsigned)count withObjCType:(const char *)type;
- initWithCount:(unsigned)count withObjCType:(const char *)type;
-(void)getValue:(void *)value atIndex:(unsigned)index;
-(NSMutableValueArray *)valueArrayFromRange:(NSRange)range;
-(const char *)objCType;
-(unsigned)valueSize;
-(const void *)bytes;
-(void *)mutableBytes;
-(void)addValue:(const void *)value;
-(void)addValues:(const void *)values count:(unsigned)count;
-(void)replaceValue:(const void *)value atIndex:(unsigned)index;
-(void)insertValue:(const void *)value atIndex:(unsigned)index;
-(void)removeValueAtIndex:(unsigned)index;
- mutableCopyFromZone:(NSZone *)zone;
- copyFromZone:(NSZone *)zone;

@end

@interface NSNumber (NSValueArrayNumberExtensions)
+ (NSValue *)value:(const void *)value withObjCType:(const char *)type;	
@end
