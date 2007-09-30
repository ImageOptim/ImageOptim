#import "ImageOptim.h"
#import "FilesQueue.h"
#import "Worker.h"

@implementation ImageOptim

+(void)initialize
{
	NSMutableDictionary *defs = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defs];
}

-(void)awakeFromNib
{		
	filesQueue = [[FilesQueue alloc] initWithTableView:tableView andController:filesController];
}

- (void)sorryAlertEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	if (returnCode == NSAlertDefaultReturn)
	{
		[self showPrefs:self];
	}
	else if (returnCode == NSAlertAlternateReturn)
	{
		[application terminate:self];
	}
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)path
{
    [filesQueue addFilePath:path];
	return YES;
}

- (IBAction)showPrefs:(id)sender
{
	NSLog(@"show prefs");

	if (!prefsController)
	{
		prefsController = [PrefsController new];
		NSLog(@"new prefs = %@",prefsController);
	}
	[prefsController showWindow:self];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	NSLog(@"window close!");
	[application terminate:self];
}

-(void)dealloc
{
	[prefsController release];
	[super dealloc];
}


@end
