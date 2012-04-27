/*   SynthesisCore
 *   by Sean Hill
 *   (c) 2003 All Rights Reserved.
 *   
 */

#import <SynthesisCore/Simulator.h>
#import <SynthesisCore/SIMObject.h>
#import <SynthesisCore/RungeKutta4.h>
#import <PseudoRandomNum/PRNGenerator.h>


@class NSArray,SIMNetwork;

@interface SIMModel:SIMObject
{
		SIMType *cellType;
        SIMIntegrationMethods _integrationMethod;
		unsigned short _assignedIndex;  // Uses the AssignedIndex entry in the description dictionary
        id stateGenerator;
        SIMState userState;
        int randomSeed;
        SIM_DEFINE_DERIVATIVE_FUNCTION(evaluateDerivatives);
		NSString *modelName;
}

- initWithDescription:(NSDictionary *)aDescription;
- (void) initializeWithCellType:(SIMType *)cellType;
- (void) updateVariableIndexes;
- (unsigned) assignedIndex;
- (void)_setup;

- (void) setRandomNumberSeed:(int)seed;
- (int) randomNumberSeed;
- (PRNGenerator *) randomStateGenerator;

- (void) initUserState;

- (void) updateState: (SIMState *) aState dt: (float) dt  time: (float) t;
- (void) updateParameters;

- (void)evaluateDerivatives:(SIMStateValue *)dy initialValues:(SIMStateValue *)y
	time:(float)t context:(SIMState *)state;
- (void) updateStateUsingForwardEuler:(SIMState *)element dt:(float)dt time:(float)time;
- (void) updateStateUsingRungeKutta4thOrder:(SIMState *)element dt:(float)dt time:(float)time;

- (void) setRandomValuesForState: (SIMState *) element;
- (void) setInitialValuesForState: (SIMState *) element;
- (void) setNullValuesForState: (SIMState *) element;
- (unsigned long) indexOfVariable:(NSString *)varName;
- (NSString *)variableAtIndex:(unsigned)index;
- (NSDictionary *)variableDictionary;
- (SIMValueType)typeForVariable:(NSString *)varName;

- (double) doubleValueOfVariable:(NSString *)var forState:(SIMState *)state;
- (float) floatValueOfVariable:(NSString *)var forState:(SIMState *)state;
- (int) intValueOfVariable:(NSString *)var forState:(SIMState *)state;
- (SIMActivityStateValue) activityValueOfVariable:(NSString *)var forState:(SIMState *)state;
- (long) longValueOfVariable:(NSString *)var forState:(SIMState *)state;
- (BOOL) boolValueOfVariable:(NSString *)var forState:(SIMState *)state;
- (id) objectValueOfVariable:(NSString *)var forState:(SIMState *)state;


- (NSArray *)allVariables;
- (NSArray *)allVariableKeys; 

- (int) numVariables;

- (void) archiveState:(SIMState *)element withCoder:(NSCoder *)coder;
- (void) unarchiveState:(SIMState *)element withCoder:(NSCoder *)coder;

- (void) archiveRemoteState:(SIMState *)element withCoder:(NSCoder *)coder;
- (void) unarchiveRemoteState:(SIMState *)element withCoder:(NSCoder *)coder;

- (void) allocState: (SIMState *) element;
- (void) deallocState: (SIMState *) element;

- (void) dealloc;

- (id) initWithCoder:(NSCoder *)coder;
- (void) encodeWithCoder: (NSCoder *) coder;

- (void) setModelName:(NSString *)name;
- (NSString *)modelName;

@end

