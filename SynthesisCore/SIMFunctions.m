/*
 * SIMFunctions.c
 *
 */

/* expx() -- exp() xcelerated
 * A fast and compact replacement of the exp() function originally developed by Schraudolph (2001 )
 * and further refined and enhanced by Cawley (2000) See Neural Computation 12,2009-2012 (2000).
 *
 */

#import <SynthesisCore/SIMFunctions.h>


void SIMSetStateValue(SIMStateValue *element,int index,id object){
    switch(element[index].type) {
        case SIMDoubleType: 
				element[index].state.doubleValue = [object doubleValue];
				break;
        case SIMFloatType: 
				element[index].state.floatValue = [object floatValue];	
				break;
        case SIMActivityType: 
				element[index].state.activityValue = [object longValue];
				break;
        case SIMUnsignedType: 
				element[index].state.unsignedValue = [object unsignedIntValue];
				break;
        case SIMBooleanType: 
				element[index].state.booleanValue = [object boolValue];
				break;
        case SIMIntegerType: 
				element[index].state.intValue = [object intValue];
				break;
        case SIMLongType: 
				element[index].state.longValue = [object longValue];	
				break;
        case SIMObjectType: 
				element[index].state.objectValue = [object retain]; // We will retain this object
				break;
        default: return;
    }
}


id SIMGetStateValue(SIMStateValue *element,int index){
    switch(element[index].type) {
        case SIMDoubleType: return [NSNumber numberWithDouble:element[index].state.doubleValue];
        case SIMFloatType: return [NSNumber numberWithFloat:element[index].state.floatValue];	
        case SIMActivityType: return [NSNumber numberWithLong:element[index].state.activityValue];
        case SIMUnsignedType: return [NSNumber numberWithUnsignedInt:element[index].state.unsignedValue];
        case SIMBooleanType: return [NSNumber numberWithBool:element[index].state.booleanValue];
        case SIMIntegerType: return [NSNumber numberWithInt:element[index].state.intValue];
        case SIMLongType: return [NSNumber numberWithLong:element[index].state.longValue];	
        case SIMObjectType: return element[index].state.objectValue;
		default: return nil;
    }
}


double SIMStateValueAsDouble(SIMStateValue *element,int index){
    switch(element[index].type) {
        case SIMDoubleType: return (double)element[index].state.doubleValue;
        case SIMFloatType: return (double)element[index].state.floatValue;	
        case SIMActivityType: return (double)element[index].state.activityValue;
        case SIMUnsignedType: return (double)element[index].state.unsignedValue;
        case SIMBooleanType: return (double)element[index].state.booleanValue;
        case SIMIntegerType: return (double)element[index].state.intValue;
        case SIMLongType: return (double)element[index].state.longValue;	
        case SIMObjectType: return (double)0.0; // Zero will represent an object value	
        default: return 0;
    }
}


void SIMCopyConnection(SIMConnection *from, SIMConnection *to)
{
    int i;
    to->dx = from->dx;
    to->dy = from->dy;
    to->dz = from->dz;
    to->strength = from->strength;
#ifdef CONNECTION_LATENCIES
    to->latency = from->latency;
#endif
    to->channelCount = from->channelCount;
    to->channels = malloc((to->channelCount)*sizeof(short int));
    for(i=0; i < to->channelCount; i++){
        to->channels[i] = from->channels[i];
    }
}


#define EXP_A (1048576/M_LN2)
#define EXP_C 60801


double expx(double y)
{
    union
    {
        double d;
#ifdef __LITTLE_ENDIAN__
        struct { int j, i; } n;
#else
        struct { int i, j; } n;
#endif
    } _eco;
    _eco.n.i = (int)(EXP_A * (y)) + (1072693248 - EXP_C);
    _eco.n.j = 0;

    return _eco.d;
}
