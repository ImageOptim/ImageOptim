#import "MyTableView.h"
#import "FilesQueue.h"
#import "RevealButtonCell.h"
#import "File.h"
#import "log.h"

@implementation MyTableView

-(void)removeObjects:(NSArray *)objects {
    FilesQueue *f = (FilesQueue*)[self delegate];

    [[self undoManager] registerUndoWithTarget:self selector:@selector(addObjects:) object:objects];
    [f removeObjects:objects];
}

-(void)addObjects:(NSArray *)objects {
    FilesQueue *f = (FilesQueue*)[self delegate];

    [[self undoManager] registerUndoWithTarget:self selector:@selector(removeObjects:) object:objects];
    [f addObjects:objects];
}

- (IBAction)delete:(id)sender {
    FilesQueue *f = (FilesQueue*)[self delegate];
    [self removeObjects:[f selectedObjects]];
}

- (IBAction)copy:(id)sender {
    FilesQueue *f = (FilesQueue*)[self delegate];

    NSArray *selected = [f selectedObjects];
    NSMutableArray *filePaths = [NSMutableArray arrayWithCapacity:[selected count]];
    NSMutableArray *fileNames = [NSMutableArray arrayWithCapacity:[selected count]];
    for(File *file in selected) {
        NSString *path = file.filePath.path;
        [filePaths addObject:path];
        [fileNames addObject:[path.lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    };
    if ([filePaths count]) {
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];

        [pboard declareTypes:@[NSFilenamesPboardType, NSStringPboardType] owner:self];
        [pboard setPropertyList:filePaths forType:NSFilenamesPboardType];
        [pboard setString:[fileNames componentsJoinedByString:@"\n"] forType:NSStringPboardType];
    }
}

-(NSArray*)filesForDataURI {
    FilesQueue *f = (FilesQueue*)[self delegate];

    NSArray *selectedFiles = [f selectedObjects];
    NSMutableArray *files = [NSMutableArray arrayWithCapacity:[selectedFiles count]];
    NSUInteger totalSize = 0;
    for(File *file in selectedFiles) {
        if (![file isDone] || !file.byteSizeOptimized) continue;
        if (file.byteSizeOptimized > 100000) continue;
        totalSize += file.byteSizeOptimized;
        if (totalSize > 1000000) break;
        [files addObject:file];
    }
    return files;
}

- (IBAction)copyAsDataURI:(id)sender {
    NSMutableArray *urls = [NSMutableArray new];
    for(File *file in [self filesForDataURI]) {
        NSData *data = [NSData dataWithContentsOfURL:file.filePath];

        NSString *type = file.fileType == FILETYPE_PNG ? @"png" : (file.fileType == FILETYPE_JPEG ? @"jpeg" : (file.fileType == FILETYPE_GIF ? @"gif" : nil));
        if (!type) continue;

        NSString *url = [[NSString stringWithFormat:@"data:image/%@;base64,", type]
                         stringByAppendingString:[data base64Encoding]];

        [urls addObject:url];
    }

    NSPasteboard *pboard = [NSPasteboard generalPasteboard];

    [pboard declareTypes:@[NSStringPboardType] owner:nil];
    [pboard setString:[urls componentsJoinedByString:@"\n"] forType:NSStringPboardType];
}

- (IBAction)cut:(id)sender
{
    [self copy:sender];
    [self delete:sender];
    [[self undoManager] setActionName:NSLocalizedString(@"Cut",@"undo command name")];
}

- (IBAction)paste:(id)sender
{
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];

    NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];
    NSMutableArray *urls = [NSMutableArray arrayWithCapacity:[paths count]];
    for(NSString *path in paths) {
        [urls addObject:[NSURL fileURLWithPath:path]];
    }

    FilesQueue *f = (FilesQueue*)[self delegate];
    [f addURLsBelowSelection:urls];
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    SEL action = [menuItem action];

    if (action == @selector(delete:) || action == @selector(copy:) || action ==  @selector(cut:)) {
        return [self numberOfSelectedRows] > 0;
    } else if (action == @selector(copyAsDataURI:)) {
        NSData *data = [NSData data];
        return [data respondsToSelector:@selector(base64Encoding)] && [self numberOfSelectedRows] > 0 && [[self filesForDataURI] count] > 0;
    } else if (action == @selector(paste:)) {
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
        NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];
        return [paths count]>0;
    } else if (action == @selector(selectAll:)) {
        return [self numberOfRows]>0;
    }
    return [menuItem isEnabled];
}

- (void)keyDown:(NSEvent *)theEvent {
    if (![theEvent isARepeat] && [self numberOfSelectedRows]) {
        switch ([theEvent keyCode]) {
        case 49: /*space*/
            [self quickLook];
            return;
        case 51: /*backspace*/
        case 117: /*delete*/
            [self delete:self];
            return;
        }
    }

    [super keyDown:theEvent];
}


// Tracking rect support
- (void)updateTrackingAreas {

    for (NSTrackingArea *area in [self trackingAreas]) {
        // We have to uniquely identify our own tracking areas
        if (([area owner] == self) && ([[area userInfo] objectForKey:@"Row"] != nil)) {
            [self removeTrackingArea:area];
        }
    }

    // Find the visible cells that have a non-empty tracking rect and add rects for each of them
    NSRange visibleRows = [self rowsInRect:[self visibleRect]];
    NSIndexSet *visibleColIndexes = [self columnIndexesInRect:[self visibleRect]];

    NSPoint mouseLocation = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];

    for (NSInteger row = visibleRows.location; row < visibleRows.location + visibleRows.length; row++) {
        // If it is a "full width" cell, we don't have to go through the rows
        for (NSInteger col = [visibleColIndexes firstIndex]; col != NSNotFound; col = [visibleColIndexes indexGreaterThanIndex:col]) {
            NSCell *cell = [self preparedCellAtColumn:col row:row];
            if ([cell isKindOfClass:[RevealButtonCell class]]) {
                RevealButtonCell *imagecell = (id)cell;
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInteger:col], @"Col",
                                          [NSNumber numberWithInteger:row], @"Row", nil];
                [imagecell addTrackingAreasForView:self inRect:[self frameOfCellAtColumn:col row:row]
                 withUserInfo:userInfo mouseLocation:mouseLocation];
            }
        }
    }
}

-(void)setMouseEntered:(BOOL)entered fromEvent:(NSEvent *)event {
    // Delegate this to the appropriate cell. In order to allow the cell to maintain state, we copy it and use the copy until the mouse is moved outside of the cell.
    NSDictionary *userInfo = [event userData];
    NSNumber *row = [userInfo valueForKey:@"Row"];
    NSNumber *col = [userInfo valueForKey:@"Col"];
    if (row && col) {
        NSInteger rowVal = [row integerValue], colVal = [col integerValue];
        RevealButtonCell *cell = (RevealButtonCell *)[self preparedCellAtColumn:colVal row:rowVal];
        assert([cell isKindOfClass:[RevealButtonCell class]]);

        if (iMouseCell != cell) {
            iMouseCol = colVal;
            iMouseRow = rowVal;
            // Store a COPY of the cell for use when tracking in an area
            iMouseCell = cell = [cell copy];
        }

        [cell setMouseEntered:entered];
        [self updateCell:cell];
    }
}
- (void)mouseEntered:(NSEvent *)event {
    [self setMouseEntered:YES fromEvent:event];
}

- (void)mouseExited:(NSEvent *)event {
    [self setMouseEntered:NO fromEvent:event];
    iMouseCell = nil;
    iMouseCol = -1;
    iMouseRow = -1;
}


/* Since NSTableView/NSOutineView uses the same cell to "stamp" out each row, we need to send the mouseEntered/mouseExited events each time it is drawn. The easy hook for this is the preparedCell method.
 */
- (NSCell *)preparedCellAtColumn:(NSInteger)column row:(NSInteger)row {
    // We check if the selectedCell is nil or not -- the selectedCell is a cell that is currently being edited or tracked. We don't want to return our override if we are in that state.
    if (iMouseCell && [self selectedCell] == nil && (row == iMouseRow) && (column == iMouseCol)) {
        return iMouseCell;
    } else {
        return [super preparedCellAtColumn:column row:row];
    }
}

/* In order for the cell to properly update itself with an "updateCell:" call, we must handle the "mouseCell" as a special case
 */
- (void)updateCell:(NSCell *)aCell {
    if (aCell == iMouseCell) {
        [self setNeedsDisplayInRect:[self frameOfCellAtColumn:iMouseCol row:iMouseRow]];
    } else {
        [super updateCell:aCell];
    }
}



- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    if (isLocal) return NSDragOperationMove;

    return NSDragOperationCopy;

}

-(void) quickLook {
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    } else {
        [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
    }
}

-(void)awakeFromNib {
    [self setDoubleAction:@selector(openInFinder:)];
}

-(NSArray *)clickedRowSelection {
    FilesQueue *fc = (FilesQueue *)[self delegate];
    assert([fc isKindOfClass:[FilesQueue class]]);

    NSInteger row = [self clickedRow];
    if (row < 0 || ([self isRowSelected:row] && [self numberOfSelectedRows] > 1)) {
        return [fc selectedObjects];
    } else {
        return @[[[fc arrangedObjects] objectAtIndex:row]];
    }
}

-(void)openInFinder:(id)sender {
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[[self clickedRowSelection] valueForKey:@"filePath"]];
}
@end
