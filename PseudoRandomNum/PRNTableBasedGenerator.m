#import "PRNGenerator.h"
#import <Desiderata/NSValueArray.h>

@implementation PRNTableBasedGenerator

- init
{
	index = 0;
	table = [[NSMutableValueArray valueArrayWithObjCType: @encode (double)] retain];
	return self;
}

- setTable: (NSMutableValueArray *) array
{
	if (table) [table release];
	table = [array retain];
	return self;
}

- addDoubleToTable: (double) d
{
	double temp = d;
	[table addValue: &temp];
	return self;
}

- loadFromFileAtPath: (NSString *) path
{
	index = 0;
	if (table) [table release];
	table = (NSMutableValueArray *) [NSUnarchiver unarchiveObjectWithFile: path];
	if (!table)
		NSLog (@"PRNTableBasedGenerator: Unable to load file at: %@",
			path);
	else [table retain];
	return self;
}

- saveToFileAtPath: (NSString *) path
{
	if (![NSArchiver archiveRootObject: table toFile: path])
		NSLog (@"PRNTableBasedGenerator: Unable to save to file at: %@",
			path);
	return self;
}

- (double) nextDouble
{
	double temp;
	if (index >= [table count]) 
		index = 0;
	[table getValue: &temp atIndex: index++];
	return temp;
}

- (void) dealloc
{
	[table release];
	[super dealloc];
}

@end


