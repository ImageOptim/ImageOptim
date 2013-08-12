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

NSDictionary *statusImages;

@synthesize selectedIndexes,filesQueue;

- (void)setSelectedIndexes:(NSIndexSet *)indexSet
{
	//Get information from ArrayController
    if (indexSet != selectedIndexes) {
		selectedIndexes = [indexSet copy];
		[previewPanel reloadData];
	}
}

-(void)migrateOldPreferences
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
- (void)applicationWillFinishLaunching:(NSNotification *)unused {


    NSMutableDictionary *defs = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];

	int maxTasks = [self numberOfCPUs];
    
	[defs setObject:[NSNumber numberWithInt:maxTasks] forKey:@"RunConcurrentTasks"];
	[defs setObject:[NSNumber numberWithInt:(int)ceil((double)maxTasks/3.9)] forKey:@"RunConcurrentDirscans"];

	[[NSUserDefaults standardUserDefaults] registerDefaults:defs];

    [self migrateOldPreferences];

	filesQueue = [[FilesQueue alloc] initWithTableView:tableView progressBar:progressBar andController:filesController];

    [NSApp setServicesProvider:self];
    NSUpdateDynamicServices();
}

- (void)handleServices:(NSPasteboard *)pboard
              userData:(NSString *)userData
                 error:(NSString **)error {
    NSLog(@"Service called");
    [self.filesQueue pasteObjectsFrom:pboard];
}

NSString *formatSize(long long byteSize, NSNumberFormatter *formatter)
{
    NSString *unit;
    double size;

    if (byteSize > 1000*1000LL) {
        size = (double)byteSize / (1000.0*1000.0);
        unit = NSLocalizedString(@"MB", "megabytes suffix");
    } else {
        size = (double)byteSize / 1000.0;
        unit = NSLocalizedString(@"KB", "kilobytes suffix");
    }

    return [[formatter stringFromNumber:[NSNumber numberWithDouble:size]] stringByAppendingString:unit];
};


-(void)initStatusbar
{
    [[statusBarLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];

    static BOOL overallAvg = NO;
    static NSString *defaultText; defaultText = statusBarLabel.stringValue;
    static NSNumberFormatter* formatter; formatter = [NSNumberFormatter new];
    static NSNumberFormatter* percFormatter; percFormatter = [NSNumberFormatter new];

    [formatter setMaximumFractionDigits:1];
    [percFormatter setMaximumFractionDigits:1];
    [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    [percFormatter setNumberStyle: NSNumberFormatterPercentStyle];

    statusBarUpdateQueue = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_OR, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_event_handler(statusBarUpdateQueue, ^{
        NSString *str = defaultText;
        @synchronized (filesController) {
            if ([filesController.arrangedObjects count] > 1) {

                NSNumber *bytes = [filesController valueForKeyPath:@"arrangedObjects.@sum.byteSizeOriginal"],
                *optimized = [filesController valueForKeyPath:@"arrangedObjects.@sum.byteSizeOptimized"];

                double savedTotal = 100.0*(1.0-[optimized doubleValue]/[bytes doubleValue]);
                if (savedTotal > 0.1) {
                    long long bytesL = [bytes longLongValue], bytesSaved = bytesL - [optimized longLongValue];
                    double savedAvg = [[filesController valueForKeyPath:@"arrangedObjects.@avg.percentOptimized"] doubleValue];

                    NSString *fmtStr; NSNumber *avgNum;
                    if (savedTotal*0.8 > savedAvg) {
                        overallAvg = YES;
                    } else if (savedAvg*0.8 > savedTotal){
                        overallAvg = NO;
                    }

                    if (overallAvg) {
                        fmtStr = NSLocalizedString(@"Saved %@ out of %@. %@ overall (up to %@ per file)","total ratio");
                        avgNum = [NSNumber numberWithDouble:savedTotal/100.0];
                    } else {
                        fmtStr = NSLocalizedString(@"Saved %@ out of %@. %@ per file on average (up to %@)","per file avg");
                        avgNum = [NSNumber numberWithDouble:savedAvg/100.0];
                    }

                    double max = [[filesController valueForKeyPath:@"arrangedObjects.@max.percentOptimized"] doubleValue];

                    str = [NSString stringWithFormat:fmtStr,
                           formatSize(bytesSaved, formatter),
                           formatSize(bytesL, formatter),
                           [percFormatter stringFromNumber: avgNum],
                           [percFormatter stringFromNumber: [NSNumber numberWithDouble:max/100.0]]];
                }
            }
        }
        [statusBarLabel setStringValue:str];
    });
    dispatch_resume(statusBarUpdateQueue);

    [filesController addObserver:self forKeyPath:@"arrangedObjects.@count" options:NSKeyValueObservingOptionNew context:nil];
    [filesController addObserver:self forKeyPath:@"arrangedObjects.@avg.percentOptimized" options:NSKeyValueObservingOptionNew context:nil];
    [filesController addObserver:self forKeyPath:@"arrangedObjects.@sum.byteSizeOptimized" options:NSKeyValueObservingOptionNew context:nil];
}

-(void)awakeFromNib {

	RevealButtonCell* cell=[[tableView tableColumnWithIdentifier:@"filename"]dataCell];
	[cell setInfoButtonAction:@selector(openInFinder)];
	[cell setTarget:tableView];

    [credits setString:@""];

    // this creates and sets the text for textview
    [self loadCreditsHTML];

    [self initStatusbar];
    [self preloadStatusImages];
}


-(void)loadCreditsHTML{

    static const char header[] = "<!DOCTYPE html>\
    <meta charset=utf-8>\
    <style>\
    html,body {font:11px/1.5 'Lucida Grande', sans-serif; color: #000; background: transparent; margin:0;}\
    </style>\
    <title>Credits</title>";

    NSMutableData *html = [NSMutableData dataWithBytesNoCopy:(void*)header length:sizeof(header) freeWhenDone:NO];
    [html appendData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"html"]]];

		[credits setEditable:YES];
		NSAttributedString *tmpStr = [[NSAttributedString alloc]
									  initWithHTML:html
									  documentAttributes:nil];
		[credits insertText:tmpStr];
		[credits setEditable:NO];
}

-(void)preloadStatusImages {
    statusImages = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSImage imageNamed:@"err"], @"err",
                   [NSImage imageNamed:@"wait"], @"wait",
                   [NSImage imageNamed:@"progress"], @"progress",
                   [NSImage imageNamed:@"noopt"], @"noopt",
                   [NSImage imageNamed:@"ok"], @"ok",
                   nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // Defer and coalesce statusbar updates
    dispatch_source_merge_data(statusBarUpdateQueue, 1);
}

-(int)numberOfCPUs
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
    [filesQueue addPaths:[NSArray arrayWithObject:path]];
	return YES;
}


-(IBAction)quickLookAction:(id)sender
{
	[filesQueue performSelector:@selector(quickLook)];
}

- (IBAction)startAgain:(id)sender
{
    // alt-click on a button (this is used from menu too, but alternative menu item covers that anyway
    BOOL onlyOptimized = !!([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask);
	[filesQueue startAgainOptimized:onlyOptimized];
}

- (IBAction)startAgainOptimized:(id)sender
{
    [filesQueue startAgainOptimized:YES];
}


- (IBAction)clearComplete:(id)sender
{
	[filesQueue clearComplete];
}


- (IBAction)showPrefs:(id)sender
{
	if (!prefsController) {
		prefsController = [PrefsController new];
	}
	[prefsController showWindow:self];
}

-(IBAction)openHomepage:(id)sender
{
    [self openURL:@"http://imageoptim.com"];
}

-(IBAction)viewSource:(id)sender
{
	[self openURL:@"http://imageoptim.com/source"];
}

-(IBAction)openDonationPage:(id)sender
{
	[self openURL:@"http://imageoptim.com/donate.html"];
}

-(void)openURL:(NSString *)stringURL
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:stringURL]];
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
		NSWindow *myWindow=[tableView window];
		[myWindow setStyleMask:[myWindow styleMask]| NSResizableWindowMask ];
		[filesQueue setRow:-1];
        [filesQueue addPaths:[oPanel filenames]];
    }
    }];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    // let the window close immediately, clean in background
    [NSApp performSelectorOnMainThread:@selector(terminate:) withObject:self waitUntilDone:NO];
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
    SEL action = [menuItem action];
	if (action == @selector(startAgain:)) {
		return [filesQueue canStartAgainOptimized:NO];
    } else if (action == @selector(startAgainOptimized:)) {
		return [filesQueue canStartAgainOptimized:YES];
    } else if (action == @selector(clearComplete:)) {
        return [filesQueue canClearComplete];
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
