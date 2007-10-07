#import "ImageOptim.h"
#import "FilesQueue.h"
#import "Worker.h"
#include <mach/mach_host.h>
#include <mach/host_info.h>

@implementation ImageOptim

+(void)initialize
{
	srandom(random() ^ time(NULL));

	NSMutableDictionary *defs = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];
	
	int maxTasks = [self numberOfCPUs]+1;
	if (maxTasks > 6) maxTasks++;
	
	[defs setObject:[NSNumber numberWithInt:maxTasks] forKey:@"RunConcurrentTasks"];
	[defs setObject:[NSNumber numberWithFloat:ceilf((float)maxTasks/3.9F)] forKey:@"RunConcurrentDirscans"];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defs];
}

-(id)init
{
	if (self = [super init])
	{
		fileTypes = [[NSArray arrayWithObjects:@"png",@"PNG",NSFileTypeForHFSTypeCode( 'PNGf' ),@"public.png",@"image/png",
			@"jpg",@"jpeg",@"JPG",@"JPEG",NSFileTypeForHFSTypeCode( 'JPEG' ),@"public.jpeg",@"image/jpeg",nil] retain];
	}
	return self;
}

-(void)dealloc
{
	[prefsController release]; prefsController = nil;
	[fileTypes release]; fileTypes = nil;
	[super dealloc];
}

-(void)awakeFromNib
{		
	filesQueue = [[FilesQueue alloc] initWithTableView:tableView progressBar:progressBar andController:filesController];
}

+(int)numberOfCPUs
{
	host_basic_info_data_t hostInfo;
	mach_msg_type_number_t infoCount;	
	infoCount = HOST_BASIC_INFO_COUNT;
	host_info(mach_host_self(), HOST_BASIC_INFO, (host_info_t)&hostInfo, &infoCount);
	return MIN(32,MAX(1,(hostInfo.max_cpus)));
}

// invoked by Dock
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)path
{
    [filesQueue addFilePath:path dirs:YES];
	[filesQueue runAdded];
	return YES;
}

- (IBAction)showPrefs:(id)sender
{
//	NSLog(@"show prefs");

	if (!prefsController)
	{
		prefsController = [PrefsController new];
//		NSLog(@"new prefs = %@",prefsController);
	}
	[prefsController showWindow:self];
}

-(void)openURL:(NSString *)stringURL
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:stringURL]];
}

-(IBAction)openPngOutHomepage:(id)sender;
{
	[self openURL:@"http://www.advsys.net/ken/utils.htm"];
}
-(IBAction)openPngOutDownload:(id)sender;
{
	[self openURL:@"http://www.jonof.id.au/index.php?p=pngout"];
}

-(IBAction)browseForFiles:(id)sender
{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	
    [oPanel setAllowsMultipleSelection:YES];
	[oPanel setCanChooseDirectories:YES];
	[oPanel setResolvesAliases:YES];

    [oPanel beginSheetForDirectory:nil file:nil types:fileTypes modalForWindow:[tableView window] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];		
}

- (void)openPanelDidEnd:(NSOpenPanel *)oPanel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	if (returnCode == NSOKButton) {
        [filesQueue addFilesFromPaths:[oPanel filenames]];
    }
}

- (void)windowWillClose:(NSNotification *)aNotification
{
//	NSLog(@"window close!");
	[application terminate:self];
}

@end
