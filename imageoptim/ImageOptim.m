#import "ImageOptim.h"
#import "FilesQueue.h"
#import "RevealButtonCell.h"
#import "File.h"
#import "Workers/Worker.h"
#import "PrefsController.h"
#include <mach/mach_host.h>
#include <mach/host_info.h>
#import <Quartz/Quartz.h>

@implementation ImageOptim

@synthesize statusBarLabel,tableView,filesController,application,progressBar,credits, selectedIndexes;

- (void)setSelectedIndexes:(NSIndexSet *)indexSet
{
	//Get information from ArrayController
    if (indexSet != selectedIndexes) {
		selectedIndexes = [indexSet copy];
		[previewPanel reloadData];
	}
}

+ (void)migrateOldPreferences
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    BOOL migrated = [userDefaults boolForKey:@"PrefsMigrated"];
    if (!migrated) {
        NSString *const oldKeys[] = {
            @"AdvPng.Bundle", @"AdvPng.Enabled", @"AdvPng.Level", @"AdvPng.Path", @"Gifsicle.Bundle", @"Gifsicle.Enabled", @"Gifsicle.Path",
            @"JpegOptim.Bundle", @"JpegOptim.Enabled", @"JpegOptim.MaxQuality", @"JpegOptim.Path", @"JpegOptim.StripComments", @"JpegOptim.StripExif",
            @"JpegTran.Bundle", @"JpegTran.Enabled", @"JpegTran.Path", @"OptiPng.Bundle", @"OptiPng.Enabled", @"OptiPng.Level", @"OptiPng.Path",
            @"PngCrush.Bundle", @"PngCrush.Chunks", @"PngCrush.Enabled", @"PngCrush.Path", @"PngOut.Bundle", @"PngOut.Enabled",
            @"PngOut.InterruptIfTakesTooLong", @"PngOut.Level", @"PngOut.Path", @"PngOut.RemoveChunks",
        };

        for(int i=0; i < sizeof(oldKeys)/sizeof(oldKeys[0]); i++) {
            id oldValue = [userDefaults objectForKey:oldKeys[i]];
            if (oldValue) {
                NSString *newKey = [oldKeys[i] stringByReplacingOccurrencesOfString:@"." withString:@""];
                id newValue = [userDefaults objectForKey:newKey];
                if (![oldValue isEqual:newValue]) {
                    [userDefaults setObject:oldValue forKey:newKey];
                } else {
                    [userDefaults removeObjectForKey:oldKeys[i]]; // FIXME: remove unconditionally after a while
                }
            }
        }
        [userDefaults setBool:YES forKey:@"PrefsMigrated"];
    }
}

+(void)initialize
{
	NSMutableDictionary *defs = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];

	int maxTasks = [self numberOfCPUs]+1;
	if (maxTasks > 6) maxTasks++;

	[defs setObject:[NSNumber numberWithInt:maxTasks] forKey:@"RunConcurrentTasks"];
	[defs setObject:[NSNumber numberWithInt:(int)ceil((double)maxTasks/3.9)] forKey:@"RunConcurrentDirscans"];

	[[NSUserDefaults standardUserDefaults] registerDefaults:defs];

    [self migrateOldPreferences];
}


-(void)awakeFromNib
{
    [[statusBarLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];
	filesQueue = [[FilesQueue alloc] initWithTableView:tableView progressBar:progressBar andController:filesController];
//    [self performSelectorInBackground:@selector(loadDupes) withObject:nil];

	RevealButtonCell* cell=[[tableView tableColumnWithIdentifier:@"filename"]dataCell];
	[cell setInfoButtonAction:@selector(openInFinder)];
	[cell setTarget:tableView];

    [credits setString:@"Ooops"];
    [credits readRTFDFromFile:[[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"]];
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
    [filesQueue setRow:-1];
    [filesQueue addPath:path];
	[filesQueue runAdded];
	return YES;
}


-(IBAction)quickLookAction:(id)sender
{
	[filesQueue performSelector:@selector(quickLook)];
}

- (IBAction)startAgain:(id)sender
{
	[filesQueue startAgain];
}

- (IBAction)showPrefs:(id)sender
{
//	NSLog(@"show prefs");

//    [Dupe resetDupes]; // changes in prefs invalidate dupes database; FIXME: this is inaccurate and lame

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

-(IBAction)openPngOutHomepage:(id)sender
{
	[self openURL:@"http://www.advsys.net/ken/utils.htm"];
}
-(IBAction)openPngOutDownload:(id)sender
{
	[self openURL:@"http://www.jonof.id.au/pngout"];
}

-(IBAction)browseForFiles:(id)sender
{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];

    [oPanel setAllowsMultipleSelection:YES];
	[oPanel setCanChooseDirectories:YES];
	[oPanel setResolvesAliases:YES];
    [oPanel setAllowedFileTypes:[filesQueue fileTypes]];

    [oPanel beginSheetModalForWindow:[tableView window] completionHandler:^(NSInteger returnCode) {
	if (returnCode == NSOKButton) {
		[filesQueue setRow:-1];
        [filesQueue addPaths:[oPanel filenames]];
    }
    }];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    // let the window close immediately, clean in background
    [application performSelectorOnMainThread:@selector(terminate:) withObject:self waitUntilDone:NO];
}

-(void)applicationWillTerminate:(NSNotification*)n {
    [filesQueue cleanup];
}

-(NSString*)version {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

// Quick Look panel support

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel;
{
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
    // This document is now responsible of the preview panel
    // It is allowed to set the delegate, data source and refresh panel.
    previewPanel = panel;
    panel.delegate = self;
    panel.dataSource = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
    // This document loses its responsisibility on the preview panel
    // Until the next call to -beginPreviewPanelControl: it must not
    // change the panel's delegate, data source or refresh it.
    previewPanel = nil;
}

// Quick Look panel data source

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
    return [[filesController selectedObjects] count];
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
    return [NSURL fileURLWithPath:[[[filesController selectedObjects] objectAtIndex:index]filePath] ];
}

// Quick Look panel delegate

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
    // redirect all key down events to the table view
    if ([event type] == NSKeyDown) {
        [tableView keyDown:event];
        return YES;
    }
    return NO;
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	if ([menuItem action] == @selector(startAgain:)) {
		return [tableView numberOfRows]>0;
    }
	return [menuItem isEnabled];
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
    NSInteger index = [[filesController arrangedObjects] indexOfObject:item];
    if (index == NSNotFound) {
        return NSZeroRect;
    }

    NSRect iconRect = [tableView frameOfCellAtColumn:0 row:index];

    // check that the icon rect is visible on screen
    NSRect visibleRect = [tableView visibleRect];

    if (!NSIntersectsRect(visibleRect, iconRect)) {
        return NSZeroRect;
    }

    // convert icon rect to screen coordinates
    iconRect = [tableView convertRectToBase:iconRect];
    iconRect.origin = [[tableView window] convertBaseToScreen:iconRect.origin];

    return iconRect;
}

// This delegate method provides a transition image between the table view and the preview panel
- (id)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
	return [[NSWorkspace sharedWorkspace] iconForFile:[(NSURL *)item path]];
}


@end
