#import "ImageOptimController.h"
#import "FilesController.h"
#import "RevealButtonCell.h"
#import "Backend/Job.h"
#import "JobProxy.h"
#import "File.h"
#import "Backend/Workers/Worker.h"
#import "PrefsController.h"
#import "MyTableView.h"
#import "SharedPrefs.h"
#import "TaskStateCell.h"
#include <mach/mach_host.h>
#include <mach/host_info.h>
#import <Quartz/Quartz.h>

@implementation ImageOptimController

extern int quitWhenDone;

static const char *kIMPreviewPanelContext = "preview";
static NSToolbarIdentifier const kIOMainToolbarIdentifier = @"ImageOptim.MainToolbar.Enhanced";
static NSToolbarItemIdentifier const kIOToolbarAddIdentifier = @"ImageOptim.Toolbar.Add";
static NSToolbarItemIdentifier const kIOToolbarStopIdentifier = @"ImageOptim.Toolbar.Stop";
static NSToolbarItemIdentifier const kIOToolbarRetryFailedIdentifier = @"ImageOptim.Toolbar.RetryFailed";
static NSToolbarItemIdentifier const kIOToolbarAgainIdentifier = @"ImageOptim.Toolbar.Again";
static NSToolbarItemIdentifier const kIOToolbarClearIdentifier = @"ImageOptim.Toolbar.Clear";
static NSToolbarItemIdentifier const kIOToolbarSettingsIdentifier = @"ImageOptim.Toolbar.Settings";

typedef NS_ENUM(NSInteger, IOQueueFilterSegment) {
    IOQueueFilterSegmentAll = 0,
    IOQueueFilterSegmentRunning = 1,
    IOQueueFilterSegmentDone = 2,
    IOQueueFilterSegmentFailed = 3,
};

@synthesize filesController;

- (void)applicationWillFinishLaunching:(NSNotification *)unused {
    if (quitWhenDone) {
        [NSApp hide:self];
    }

    NSMutableDictionary *defs = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];

    NSUInteger maxTasks = [[NSProcessInfo processInfo] activeProcessorCount];

    defs[@"RunConcurrentFiles"] = @(maxTasks);
    defs[@"RunConcurrentDirscans"] = @((int)ceil((double)maxTasks / 3.9));

    // Use lighter defaults on slower machines
    if (maxTasks <= 4) {
        defs[@"PngOutEnabled"] = @(NO);
        if (maxTasks <= 2) {
            defs[@"PngCrush2Enabled"] = @(NO);
        }
    }

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults registerDefaults:defs];

    [self initStatusbarWithDefaults:userDefaults];

    IOSharedPrefsCopy(userDefaults);

    [filesController configureWithTableView:tableView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeNotification:) name:kJobQueueFinished object:filesController];

    NSArray *monospaceFontColumns = @[
        fileColumn,
        sizeColumn,
        originalSizeColumn,
        savingsColumn,
        bestToolColumn,
    ];
    for (NSTableColumn *column in monospaceFontColumns) {
        NSFont *font = [NSFont monospacedDigitSystemFontOfSize:13 weight:NSFontWeightRegular];
        [column.dataCell setFont:font];
    }

    [NSApp setServicesProvider:self];
}

- (void)configureToolbar {
    NSWindow *window = tableView.window;
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:kIOMainToolbarIdentifier];
    toolbar.delegate = self;
    toolbar.allowsUserCustomization = YES;
    toolbar.autosavesConfiguration = YES;
    toolbar.displayMode = NSToolbarDisplayModeIconAndLabel;
    toolbar.sizeMode = NSToolbarSizeModeRegular;
    window.toolbar = toolbar;
    window.toolbarStyle = NSWindowToolbarStyleUnifiedCompact;
    window.titleVisibility = NSWindowTitleVisible;
}

- (NSToolbarItem *)toolbarItemWithIdentifier:(NSToolbarItemIdentifier)itemIdentifier
                                       label:(NSString *)label
                                      symbol:(NSString *)symbol
                                      action:(SEL)action {
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    item.label = label;
    item.paletteLabel = label;
    item.toolTip = label;
    item.target = self;
    item.action = action;
    item.image = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:label];
    return item;
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return @[
        kIOToolbarAddIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        kIOToolbarStopIdentifier,
        kIOToolbarRetryFailedIdentifier,
        kIOToolbarAgainIdentifier,
        kIOToolbarClearIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        kIOToolbarSettingsIdentifier,
    ];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return @[
        kIOToolbarAddIdentifier,
        kIOToolbarStopIdentifier,
        kIOToolbarRetryFailedIdentifier,
        kIOToolbarAgainIdentifier,
        kIOToolbarClearIdentifier,
        kIOToolbarSettingsIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarSpaceItemIdentifier,
    ];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag {
    if ([itemIdentifier isEqualToString:kIOToolbarAddIdentifier]) {
        return [self toolbarItemWithIdentifier:itemIdentifier label:NSLocalizedString(@"Add Files", @"toolbar item") symbol:@"plus" action:@selector(browseForFiles:)];
    }
    if ([itemIdentifier isEqualToString:kIOToolbarStopIdentifier]) {
        return [self toolbarItemWithIdentifier:itemIdentifier label:NSLocalizedString(@"Stop", @"toolbar item") symbol:@"stop.fill" action:@selector(stop:)];
    }
    if ([itemIdentifier isEqualToString:kIOToolbarRetryFailedIdentifier]) {
        return [self toolbarItemWithIdentifier:itemIdentifier label:NSLocalizedString(@"Retry Failed", @"toolbar item") symbol:@"exclamationmark.triangle" action:@selector(retryFailed:)];
    }
    if ([itemIdentifier isEqualToString:kIOToolbarAgainIdentifier]) {
        return [self toolbarItemWithIdentifier:itemIdentifier label:NSLocalizedString(@"Optimize Again", @"toolbar item") symbol:@"arrow.clockwise" action:@selector(startAgain:)];
    }
    if ([itemIdentifier isEqualToString:kIOToolbarClearIdentifier]) {
        return [self toolbarItemWithIdentifier:itemIdentifier label:NSLocalizedString(@"Clear Done", @"toolbar item") symbol:@"checkmark.circle" action:@selector(clearComplete:)];
    }
    if ([itemIdentifier isEqualToString:kIOToolbarSettingsIdentifier]) {
        return [self toolbarItemWithIdentifier:itemIdentifier label:NSLocalizedString(@"Settings", @"toolbar item") symbol:@"gearshape" action:@selector(showPrefs:)];
    }
    return nil;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)item {
    NSToolbarItemIdentifier identifier = item.itemIdentifier;
    if ([identifier isEqualToString:kIOToolbarAddIdentifier]) {
        return [filesController canAdd];
    }
    if ([identifier isEqualToString:kIOToolbarStopIdentifier]) {
        return [filesController isStoppable];
    }
    if ([identifier isEqualToString:kIOToolbarRetryFailedIdentifier]) {
        return [filesController canRetryFailed];
    }
    if ([identifier isEqualToString:kIOToolbarAgainIdentifier]) {
        return [filesController canStartAgainOptimized:NO];
    }
    if ([identifier isEqualToString:kIOToolbarClearIdentifier]) {
        return [filesController canClearComplete];
    }
    return YES;
}

- (void)configureQueueFilter {
    if (queueFilterControl) {
        return;
    }

    NSScrollView *scrollView = tableView.enclosingScrollView;
    NSView *contentView = tableView.window.contentView;
    if (!scrollView || !contentView) {
        return;
    }

    queueFilterControl = [NSSegmentedControl segmentedControlWithLabels:@[
        NSLocalizedString(@"All", @"queue filter"),
        NSLocalizedString(@"Running", @"queue filter"),
        NSLocalizedString(@"Done", @"queue filter"),
        NSLocalizedString(@"Failed", @"queue filter"),
    ]
                                                            trackingMode:NSSegmentSwitchTrackingSelectOne
                                                                  target:self
                                                                  action:@selector(changeQueueFilter:)];
    queueFilterControl.segmentStyle = NSSegmentStyleRounded;
    queueFilterControl.controlSize = NSControlSizeSmall;
    queueFilterControl.selectedSegment = IOQueueFilterSegmentAll;
    queueFilterControl.translatesAutoresizingMaskIntoConstraints = NO;
    queueFilterControl.accessibilityLabel = NSLocalizedString(@"Queue filter", @"queue filter accessibility label");
    [queueFilterControl setToolTip:NSLocalizedString(@"Show all queued files", @"queue filter tooltip") forSegment:IOQueueFilterSegmentAll];
    [queueFilterControl setToolTip:NSLocalizedString(@"Show files currently running", @"queue filter tooltip") forSegment:IOQueueFilterSegmentRunning];
    [queueFilterControl setToolTip:NSLocalizedString(@"Show completed files", @"queue filter tooltip") forSegment:IOQueueFilterSegmentDone];
    [queueFilterControl setToolTip:NSLocalizedString(@"Show failed files", @"queue filter tooltip") forSegment:IOQueueFilterSegmentFailed];

    NSMutableArray<NSLayoutConstraint *> *constraintsToDeactivate = [NSMutableArray array];
    for (NSLayoutConstraint *constraint in contentView.constraints) {
        BOOL isScrollTopToProgress = constraint.firstItem == scrollView &&
                                     constraint.firstAttribute == NSLayoutAttributeTop &&
                                     constraint.secondItem == taskProgressIndicator &&
                                     constraint.secondAttribute == NSLayoutAttributeBottom;
        if (isScrollTopToProgress) {
            [constraintsToDeactivate addObject:constraint];
        }
    }
    [NSLayoutConstraint deactivateConstraints:constraintsToDeactivate];

    [contentView addSubview:queueFilterControl];
    [NSLayoutConstraint activateConstraints:@[
        [queueFilterControl.topAnchor constraintEqualToAnchor:taskProgressIndicator.bottomAnchor constant:10],
        [queueFilterControl.leadingAnchor constraintEqualToAnchor:taskProgressIndicator.leadingAnchor],
        [queueFilterControl.trailingAnchor constraintLessThanOrEqualToAnchor:taskProgressIndicator.trailingAnchor],
        [queueFilterControl.heightAnchor constraintEqualToConstant:24],
        [scrollView.topAnchor constraintEqualToAnchor:queueFilterControl.bottomAnchor constant:10],
    ]];
}

- (NSPredicate *)queueFilterPredicate {
    switch (queueFilterControl.selectedSegment) {
        case IOQueueFilterSegmentRunning:
            return [NSPredicate predicateWithBlock:^BOOL(JobProxy *job, NSDictionary *bindings) {
                return job.isRunningWorker;
            }];
        case IOQueueFilterSegmentDone:
            return [NSPredicate predicateWithBlock:^BOOL(JobProxy *job, NSDictionary *bindings) {
                return job.isDone && !job.isFailed;
            }];
        case IOQueueFilterSegmentFailed:
            return [NSPredicate predicateWithBlock:^BOOL(JobProxy *job, NSDictionary *bindings) {
                return job.isFailed;
            }];
        case IOQueueFilterSegmentAll:
        default:
            return nil;
    }
}

- (void)applyQueueFilter {
    filesController.filterPredicate = [self queueFilterPredicate];
    [filesController rearrangeObjects];
}

- (IBAction)changeQueueFilter:(id)sender {
    [self applyQueueFilter];
    [self updateStatusBar];
}

- (void)configureSelectionDetails {
    if (selectionDetailsLabel) {
        return;
    }

    NSScrollView *scrollView = tableView.enclosingScrollView;
    NSView *contentView = tableView.window.contentView;
    if (!scrollView || !contentView) {
        return;
    }

    selectionDetailsLabel = [NSTextField labelWithString:@""];
    selectionDetailsLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightRegular];
    selectionDetailsLabel.textColor = NSColor.secondaryLabelColor;
    selectionDetailsLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    selectionDetailsLabel.maximumNumberOfLines = 1;
    selectionDetailsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    selectionDetailsLabel.accessibilityLabel = NSLocalizedString(@"Selection details", @"selection details accessibility label");

    NSMutableArray<NSLayoutConstraint *> *constraintsToDeactivate = [NSMutableArray array];
    for (NSLayoutConstraint *constraint in contentView.constraints) {
        BOOL isStatusTopToScroll = constraint.firstItem == statusBarLabel &&
                                   constraint.firstAttribute == NSLayoutAttributeTop &&
                                   constraint.secondItem == scrollView &&
                                   constraint.secondAttribute == NSLayoutAttributeBottom;
        if (isStatusTopToScroll) {
            [constraintsToDeactivate addObject:constraint];
        }
    }
    [NSLayoutConstraint deactivateConstraints:constraintsToDeactivate];

    [contentView addSubview:selectionDetailsLabel];
    [NSLayoutConstraint activateConstraints:@[
        [selectionDetailsLabel.topAnchor constraintEqualToAnchor:scrollView.bottomAnchor constant:6],
        [selectionDetailsLabel.leadingAnchor constraintEqualToAnchor:statusBarLabel.leadingAnchor],
        [selectionDetailsLabel.trailingAnchor constraintEqualToAnchor:statusBarLabel.trailingAnchor],
        [selectionDetailsLabel.heightAnchor constraintEqualToConstant:16],
        [statusBarLabel.topAnchor constraintEqualToAnchor:selectionDetailsLabel.bottomAnchor constant:4],
    ]];

    [self updateSelectionDetails];
}

- (NSString *)formattedByteCount:(NSNumber *)byteCount {
    if (!byteCount) {
        return NSLocalizedString(@"-", @"empty byte count");
    }

    static NSByteCountFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSByteCountFormatter new];
        formatter.allowedUnits = NSByteCountFormatterUseAll;
        formatter.countStyle = NSByteCountFormatterCountStyleFile;
    });
    return [formatter stringFromByteCount:[byteCount longLongValue]];
}

- (NSString *)formattedSavings:(NSNumber *)percentOptimized {
    if (!percentOptimized) {
        return NSLocalizedString(@"-", @"empty percentage");
    }
    return [NSString stringWithFormat:NSLocalizedString(@"%.1f%%", @"percentage detail"), [percentOptimized doubleValue]];
}

- (NSString *)detailsForJob:(JobProxy *)job {
    NSString *state = job.taskStateText ?: NSLocalizedString(@"Queued", @"task state");
    NSString *tool = job.currentToolName ?: job.bestToolName ?: NSLocalizedString(@"-", @"empty tool");
    NSString *original = [self formattedByteCount:job.byteSizeOriginal];
    NSString *optimized = [self formattedByteCount:job.byteSizeOptimized];
    NSString *saved = [self formattedSavings:job.percentOptimized];

    NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithArray:@[
        job.fileName ?: job.filePath.lastPathComponent ?: NSLocalizedString(@"Selected file", @"selection detail"),
        state,
        [NSString stringWithFormat:NSLocalizedString(@"Original %@", @"selection detail"), original],
        [NSString stringWithFormat:NSLocalizedString(@"Optimized %@", @"selection detail"), optimized],
        [NSString stringWithFormat:NSLocalizedString(@"Saved %@", @"selection detail"), saved],
        [NSString stringWithFormat:NSLocalizedString(@"Tool %@", @"selection detail"), tool],
    ]];

    if (job.statusText.length) {
        [parts addObject:job.statusText];
    }

    return [parts componentsJoinedByString:@"  |  "];
}

- (NSString *)detailsForSelectedJobs:(NSArray<JobProxy *> *)jobs {
    NSUInteger done = 0;
    NSUInteger failed = 0;
    NSUInteger running = 0;
    unsigned long long originalBytes = 0;
    unsigned long long optimizedBytes = 0;

    for (JobProxy *job in jobs) {
        if (job.isFailed) {
            failed++;
        } else if (job.isDone) {
            done++;
        } else if (job.isRunningWorker) {
            running++;
        }

        originalBytes += [job.byteSizeOriginal unsignedLongLongValue];
        optimizedBytes += [job.byteSizeOptimized unsignedLongLongValue];
    }

    return [NSString stringWithFormat:NSLocalizedString(@"%lu selected  |  Done %lu  |  Running %lu  |  Failed %lu  |  Original %@  |  Optimized %@", @"multiple selection details"),
                                      (unsigned long)[jobs count],
                                      (unsigned long)done,
                                      (unsigned long)running,
                                      (unsigned long)failed,
                                      [self formattedByteCount:@(originalBytes)],
                                      [self formattedByteCount:@(optimizedBytes)]];
}

- (void)updateSelectionDetails {
    NSArray<JobProxy *> *selectedJobs = [filesController selectedObjects];
    NSString *details;
    if (![selectedJobs count]) {
        details = NSLocalizedString(@"No file selected", @"selection details");
    } else if ([selectedJobs count] == 1) {
        details = [self detailsForJob:[selectedJobs firstObject]];
    } else {
        details = [self detailsForSelectedJobs:selectedJobs];
    }

    selectionDetailsLabel.stringValue = details;
    selectionDetailsLabel.toolTip = details;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kJobQueueFinished object:filesController];
    [credits removeObserver:self forKeyPath:@"effectiveAppearance"];
}

- (void)handleServices:(NSPasteboard *)pboard
              userData:(NSString *)userData
                 error:(NSString **)error {
    NSArray<NSURL *> *urls = [filesController fileURLsFromPasteboard:pboard];
    if ([urls count] > 0) {
        [filesController performSelectorInBackground:@selector(addURLs:) withObject:urls];
    }
}

static void appendFormatNameIfLossyEnabled(NSUserDefaults *defs, NSString *name, NSString *key, NSMutableArray *arr) {
    NSInteger q = [defs integerForKey:key];
    if (q > 0 && q < 100) {
        [arr addObject:[NSString stringWithFormat:@"%@ %ld%%", name, q]];
    }
}

- (void)initStatusbarWithDefaults:(NSUserDefaults *)defs {
    [[statusBarLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];

    static BOOL overallAvg = NO;
    static NSString *defaultText;
    defaultText = statusBarLabel.stringValue;
    NSByteCountFormatter *sizeFormatter = [[NSByteCountFormatter alloc] init];

    static NSNumberFormatter *percFormatter;
    percFormatter = [NSNumberFormatter new];

    if (quitWhenDone) {
        defaultText = NSLocalizedString(@"ImageOptim will quit when optimizations are complete", @"status bar");
    }

    [percFormatter setMaximumFractionDigits:1];
    [percFormatter setNumberStyle:NSNumberFormatterPercentStyle];

    statusBarUpdateQueue = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_OR, 0, 0,
                                                  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
    dispatch_source_set_event_handler(statusBarUpdateQueue, ^{
        NSString *str = defaultText;
        __block NSString *taskSummary = @"";
        __block double taskProgress = 0;
        BOOL selectable = NO;
        @synchronized(self->filesController) {
            long long bytesTotal = 0, optimizedTotal = 0;
            double optimizedFractionTotal = 0, maxOptimizedFraction = 0;
            NSUInteger optimizedFileCount = 0;
            NSUInteger doneFileCount = 0;
            NSUInteger failedFileCount = 0;
            NSUInteger runningFileCount = 0;
            NSUInteger remainingFileCount = 0;
            BOOL anyBusyFiles = false;

            NSArray *content = [self->filesController content];
            for (JobProxy *f in content) {
                assert([f isKindOfClass:[JobProxy class]]);

                if (!anyBusyFiles && [f isBusy]) {
                    anyBusyFiles = YES;
                }

                if ([f isFailed]) {
                    failedFileCount++;
                } else if ([f isDone]) {
                    doneFileCount++;
                } else if ([f isRunningWorker]) {
                    runningFileCount++;
                } else {
                    remainingFileCount++;
                }

                const NSUInteger bytes = [f.byteSizeOriginal unsignedIntegerValue];
                const NSUInteger optimized = [f.byteSizeOptimized unsignedIntegerValue];
                if (bytes && optimized && (bytes != optimized || [f isDone])) {
                    const double optimizedFraction = 1.0 - (double)optimized / (double)bytes;
                    if (optimizedFraction > maxOptimizedFraction) {
                        maxOptimizedFraction = optimizedFraction;
                    }
                    optimizedFractionTotal += optimizedFraction;
                    bytesTotal += bytes;
                    optimizedTotal += optimized;
                    optimizedFileCount++;
                }
            }

            if (optimizedFileCount > 1 && bytesTotal) {
                const double savedTotal = 1.0 - (double)optimizedTotal / (double)bytesTotal;
                const double savedAvg = optimizedFractionTotal / (double)optimizedFileCount;
                if (savedTotal > 0.001) {
                    if (savedTotal * 0.8 > savedAvg) {
                        overallAvg = YES;
                    } else if (savedAvg * 0.8 > savedTotal) {
                        overallAvg = NO;
                    }

                    NSString *fmtStr;
                    double avgNum;
                    if (overallAvg) {
                        fmtStr = NSLocalizedString(@"Saved %@ out of %@. %@ overall (up to %@ per file)", "total ratio, status bar");
                        avgNum = savedTotal;
                    } else {
                        fmtStr = NSLocalizedString(@"Saved %@ out of %@. %@ per file on average (up to %@)", "per file avg, status bar");
                        avgNum = savedAvg;
                    }

                    const long long bytesSaved = bytesTotal - optimizedTotal;

                    str = [NSString stringWithFormat:fmtStr,
                                                     [sizeFormatter stringFromByteCount:bytesSaved],
                                                     [sizeFormatter stringFromByteCount:bytesTotal],
                                                     [percFormatter stringFromNumber:@(avgNum)],
                                                     [percFormatter stringFromNumber:@(maxOptimizedFraction)]];
                    selectable = YES;
                }
            } else if ([defs boolForKey:@"GuetzliEnabled"]) {
                str = @"Warning: Guetzli tool enabled. Optimizations may take a very long time.";
            } else if ([defs boolForKey:@"LossyEnabled"]) {
                NSMutableArray *arr = [NSMutableArray new];
                appendFormatNameIfLossyEnabled(defs, @"JPEG", @"JpegOptimMaxQuality", arr);
                appendFormatNameIfLossyEnabled(defs, @"PNG", @"PngMinQuality", arr);
                appendFormatNameIfLossyEnabled(defs, @"GIF", @"GifQuality", arr);
                if ([arr count]) {
                    str = [NSString stringWithFormat:@"%@ (%@)",
                                                     NSLocalizedString(@"Lossy minification enabled", @"status bar"),
                                                     [arr componentsJoinedByString:@", "]];
                }
            } else if (anyBusyFiles) {
                str = @"";
            }

            NSUInteger totalFileCount = [content count];
            taskSummary = [NSString stringWithFormat:NSLocalizedString(@"Total %lu   Done %lu   Running %lu   Remaining %lu   Failed %lu", @"task summary"),
                                                     (unsigned long)totalFileCount,
                                                     (unsigned long)doneFileCount,
                                                     (unsigned long)runningFileCount,
                                                     (unsigned long)remainingFileCount,
                                                     (unsigned long)failedFileCount];
            taskProgress = totalFileCount ? 100.0 * (double)(doneFileCount + failedFileCount) / (double)totalFileCount : 0;

            // that was also in KVO, but caused deadlocks there. Here it's deferred.
            [self->filesController updateStoppableState];
        }

        dispatch_async(dispatch_get_main_queue(), ^() {
            [self->statusBarLabel setStringValue:str];
            [self->statusBarLabel setSelectable:selectable];
            [self->taskSummaryLabel setStringValue:taskSummary];
            [self->taskProgressIndicator setMinValue:0];
            [self->taskProgressIndicator setMaxValue:100];
            [self->taskProgressIndicator setDoubleValue:taskProgress];
            if (self->queueFilterControl.selectedSegment != IOQueueFilterSegmentAll) {
                [self->filesController rearrangeObjects];
            }
            [self updateSelectionDetails];
        });
        usleep(100000); // 1/10th of a sec to avoid updating statusbar as fast as possible (100% cpu on the statusbar alone is ridiculous)
    });
    dispatch_resume(statusBarUpdateQueue);

    [filesController addObserver:self forKeyPath:@"isBusy" options:0 context:nil];
    [filesController addObserver:self forKeyPath:@"arrangedObjects.@count" options:0 context:nil];
    [filesController addObserver:self forKeyPath:@"arrangedObjects.@sum.isDone" options:0 context:nil];
    [filesController addObserver:self forKeyPath:@"arrangedObjects.@sum.isFailed" options:0 context:nil];
    [filesController addObserver:self forKeyPath:@"arrangedObjects.@sum.isRunningWorker" options:0 context:nil];
    [filesController addObserver:self forKeyPath:@"arrangedObjects.@sum.byteSizeOptimized" options:0 context:nil];
    [filesController addObserver:self forKeyPath:@"selectionIndexes" options:0 context:(void *)kIMPreviewPanelContext];

    [self updateStatusBar]; // Initial display

    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                      object:defs
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self updateStatusBar];
                                                  }];
}

- (void)updateStatusBar {
    dispatch_source_merge_data(statusBarUpdateQueue, 1);
}

- (void)awakeFromNib {
    if (quitWhenDone) {
        [NSApp hide:self];
    }

    [self configureToolbar];
    [self configureQueueFilter];
    [self configureSelectionDetails];

    tableView.rowHeight = 30;
    tableView.intercellSpacing = NSMakeSize(3, 4);
    tableView.usesAlternatingRowBackgroundColors = NO;
    tableView.style = NSTableViewStyleFullWidth;
    taskSummaryLabel.font = [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightMedium];

    RevealButtonCell *cell = [[tableView tableColumnWithIdentifier:@"filename"] dataCell];
    [cell setInfoButtonAction:@selector(openInFinder:)];
    [cell setTarget:tableView];

    [credits setString:@""];

    // this creates and sets the text for textview
    [self performSelectorInBackground:@selector(loadCreditsHTML:) withObject:nil];
    [credits addObserver:self forKeyPath:@"effectiveAppearance" options:0 context:nil];
}

- (void)loadCreditsHTML:(id)_unused {
    static const char header[] = "<!DOCTYPE html>\
    <meta charset=utf-8>\
    <style>\
    html,body {font:11px/1.5 'Lucida Grande', sans-serif; color: #000; background: transparent; margin:0;}\
    </style>\
    <title>Credits</title>";

    NSMutableData *html = [NSMutableData dataWithBytesNoCopy:(void *)header length:sizeof(header) freeWhenDone:NO];
    NSString*creditsPath = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"html"];
    NSData *credits = [NSData dataWithContentsOfFile:creditsPath];
    if (!credits) {
        return;
    }
    [html appendData:credits];
    NSAttributedString *tmpStr = [[NSAttributedString alloc]
              initWithHTML:html
        documentAttributes:nil];

    if (!tmpStr) return;
    dispatch_async(dispatch_get_main_queue(), ^() {
        @try {
            [self->credits setEditable:YES];
            [self->credits insertText:tmpStr replacementRange:NSMakeRange(0, 0)];
            [self->credits setEditable:NO];
            [self adaptCreditsAppearance];
        } @catch (id) { /*nothing*/
        }
    });
}

- (BOOL)isDarkMode {
    NSAppearanceName bestAppearance = [credits.effectiveAppearance bestMatchFromAppearancesWithNames:@[ NSAppearanceNameAqua, NSAppearanceNameDarkAqua ]];
    return [bestAppearance isEqualToString:NSAppearanceNameDarkAqua];
}

- (void)adaptCreditsAppearance {
    credits.textColor = [self isDarkMode] ? [NSColor whiteColor] : [NSColor blackColor];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // Defer and coalesce statusbar updates
    dispatch_source_merge_data(statusBarUpdateQueue, 1);

    if (object == credits && [keyPath isEqualToString:@"effectiveAppearance"]) {
        [self adaptCreditsAppearance];
    }

    if (context == kIMPreviewPanelContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateSelectionDetails];
        });
        [previewPanel reloadData];
    }
}

- (void)observeNotification:(NSNotification *)notif {
    if (!filesController.isBusy) {
        if (quitWhenDone) {
            [NSApp terminate:self];
        } else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"BounceDock"]) {
            [NSApp requestUserAttention:NSInformationalRequest];
        }
    }
}

// invoked by Dock
- (void)application:(NSApplication *)sender openFiles:(NSArray *)paths {
    [filesController setRow:-1];
    [sender replyToOpenOrPrint:[filesController addPaths:paths] ? NSApplicationDelegateReplySuccess : NSApplicationDelegateReplyFailure];
}

- (IBAction)quickLookAction:(id)sender {
    [tableView performSelector:@selector(quickLook)];
}

- (IBAction)revert:(id)sender {
    [filesController revert];
}

- (IBAction)stop:(id)sender {
    [filesController stopSelected];
}

- (IBAction)startAgain:(id)sender {
    // alt-click on a button (this is used from menu too, but alternative menu item covers that anyway
    BOOL onlyOptimized = !!([[NSApp currentEvent] modifierFlags] & NSEventModifierFlagOption);
    [filesController startAgainOptimized:onlyOptimized];
}

- (IBAction)startAgainOptimized:(id)sender {
    [filesController startAgainOptimized:YES];
}

- (IBAction)retryFailed:(id)sender {
    [filesController retryFailed];
}

- (IBAction)clearComplete:(id)sender {
    [filesController clearComplete];
}

- (IBAction)showPrefs:(id)sender {
    if (!prefsController) {
        prefsController = [PrefsController new];
    }
    [prefsController showWindow:self];
}

- (IBAction)showLossyPrefs:(id)sender {
    if (!prefsController) {
        prefsController = [PrefsController new];
    }
    [prefsController showLossySettings:sender];
}

- (IBAction)openApiHomepage:(id)sender {
    [self openURL:@"https://imageoptim.com/app-api"];
}

- (IBAction)openHomepage:(id)sender {
    [self openURL:@"https://imageoptim.com"];
}

- (IBAction)viewSource:(id)sender {
    [self openURL:@"https://imageoptim.com/source"];
}

- (IBAction)openDonationPage:(id)sender {
    [self openURL:@"https://imageoptim.com/donate.html"];
}

- (void)openURL:(NSString *)stringURL {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:stringURL]];
}

- (IBAction)browseForFiles:(id)sender {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];

    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setResolvesAliases:YES];
    [oPanel setAllowedContentTypes:[filesController fileContentTypes]];

    [oPanel beginSheetModalForWindow:[tableView window]
                   completionHandler:^(NSInteger returnCode) {
                       if (returnCode == NSModalResponseOK) {
                           NSWindow *myWindow = [self->tableView window];
                           [myWindow setStyleMask:[myWindow styleMask] | NSWindowStyleMaskResizable];
                           [self->filesController setRow:-1];
                           [self->filesController addURLs:oPanel.URLs];
                       }
                   }];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)n {
    [filesController cleanup];
}

- (NSString *)version {
    return [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
}

// Quick Look panel support
- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel;
{
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
    // This document is now responsible of the preview panel
    // It is allowed to set the delegate, data source and refresh panel.
    previewPanel = panel;
    panel.delegate = self;
    panel.dataSource = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
    // This document loses its responsisibility on the preview panel
    // Until the next call to -beginPreviewPanelControl: it must not
    // change the panel's delegate, data source or refresh it.
    previewPanel = nil;
}

// Quick Look panel data source
- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    return [[filesController selectedObjects] count];
}

- (id<QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index {
    return [filesController selectedObjects][index];
}

// Quick Look panel delegate
- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event {
    // redirect all key down events to the table view
    if ([event type] == NSEventTypeKeyDown) {
        [tableView keyDown:event];
        return YES;
    }
    return NO;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(startAgain:)) {
        return [filesController canStartAgainOptimized:NO];
    } else if (action == @selector(startAgainOptimized:)) {
        return [filesController canStartAgainOptimized:YES];
    } else if (action == @selector(retryFailed:)) {
        return [filesController canRetryFailed];
    } else if (action == @selector(clearComplete:)) {
        return [filesController canClearComplete];
    } else if (action == @selector(revert:)) {
        return [filesController canRevert];
    } else if (action == @selector(stop:)) {
        return [filesController isStoppable];
    }

    return [menuItem isEnabled];
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id<QLPreviewItem>)item {
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
    iconRect.origin = [tableView convertPoint:iconRect.origin toView:nil];
    iconRect = [tableView.window convertRectToScreen:iconRect];

    return iconRect;
}

@end
