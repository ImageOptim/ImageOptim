//
//  PrefsController.m
//  ImageOptim
//
//  Created by porneL on 24.wrz.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PrefsController.h"
#import "ImageOptim.h"
#import "Transformers.h"

@implementation PrefsController

-(id)init
{
	if (self = [super initWithWindowNibName:@"PrefsController"])
	{
		int cpus = [ImageOptim numberOfCPUs];
		maxNumberOfTasks = MIN(cpus*6, MAX(8, cpus * 2 + 2));
		recommendedNumberOfTasks = cpus+2 + (cpus>6?1:0);
		criticalNumberOfTasks = (maxNumberOfTasks + recommendedNumberOfTasks)/2;
		
		CeilFormatter *cf = [[[CeilFormatter alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:cf forName:@"CeilFormatter"];
		
		DisabledColor *dc = [[[DisabledColor alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:dc forName:@"DisabledColor"];		
	}
	NSLog(@"init prefs %@",self);
	return self;
}


-(int)maxNumberOfTasks {
	return maxNumberOfTasks;
}
-(int)recommendedNumberOfTasks {
	return recommendedNumberOfTasks;
}
-(int)criticalNumberOfTasks {
	return criticalNumberOfTasks;
}

-(IBAction)addGammaChunks:(id)sender
{
	NSArray *chunks = [NSArray arrayWithObjects:@"gAMA",@"sRGB",@"iCCP",@"cHRM",nil];
	NSEnumerator *enu = [chunks objectEnumerator];
	NSString *name;
	NSArray *content = [chunksController arrangedObjects];
	BOOL done = NO;
	
	while(name = [enu nextObject])
	{
		NSDictionary *chunk = [NSDictionary dictionaryWithObject:name forKey:@"name"];
		if (NSNotFound == [content indexOfObject:chunk])
		{
			[chunksController addObject:chunk];
			done = YES;
		}
	}
	if (!done) NSBeep();
}


-(void)showWindow:(id)sender
{
	NSLog(@"window show?");
	owner = sender;
	[super showWindow:sender];
	[[self window] makeKeyAndOrderFront:self];
	
	[tasksSlider setNumberOfTickMarks:[self maxNumberOfTasks]];
	[tasksSlider setAllowsTickMarkValuesOnly:YES];
}
@end
