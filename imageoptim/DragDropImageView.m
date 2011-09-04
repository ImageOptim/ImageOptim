/*
	File:		DragDropImageView.m

	Contains:	A sample to demonstrate Drag and Drop with Images in Cocoa
*/

#import "DragDropImageView.h"
#import "ImageOptim.h"
#import "FilesQueue.h"


@implementation DragDropImageView


- (id)initWithCoder:(NSCoder *)coder
{
    //------------------------------------------------------
	//   Init method called for Interface Builder objects
    //------------------------------------------------------
    if(self=[super initWithCoder:coder]){
        //register for all the image types we can display
        [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
		 //[NSImage imagePasteboardTypes]];
    }
    return self;
}
//Destination Operations
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    /*------------------------------------------------------
        method called whenever a drag enters our drop zone
     --------------------------------------------------------*/
    // Check if the pasteboard contains image data and source/user wants it copied
     /*   if ( [NSImage canInitWithPasteboard:[sender draggingPasteboard]] && [sender draggingSourceOperationMask] & NSDragOperationCopy ) {
            highlight=YES;//highlight our drop zone
            [self setNeedsDisplay: YES];
            return NSDragOperationCopy; //accept data as a copy operation
        }*/
    return NSDragOperationCopy;
	//NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    /*------------------------------------------------------
       method called whenever a drag exits our drop zone
    --------------------------------------------------------*/
    highlight=NO;//remove highlight of the drop zone
    [self setNeedsDisplay: YES];
}
-(void)drawRect:(NSRect)rect
{
    /*------------------------------------------------------
        draw method is overridden to do drop highlighing
    --------------------------------------------------------*/
    [super drawRect:rect];//do the usual draw operation to display the image
    if(highlight){
        //highlight by overlaying a gray border
        [[NSColor grayColor] set];
        [NSBezierPath setDefaultLineWidth: 5];
        [NSBezierPath strokeRect: rect];
    }
}
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    /*------------------------------------------------------
        method to determine if we can accept the drop
    --------------------------------------------------------*/
    highlight=NO;//finished with the drag so remove any highlighting
    [self setNeedsDisplay: YES];

	//check to see if we can accept the data

	return YES;// return [NSImage canInitWithPasteboard: [sender draggingPasteboard]];
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    /*------------------------------------------------------
        method that should handle the drop data
    --------------------------------------------------------*/
    if([sender draggingSource]!=self){
        //NSURL* fileURL;
		[self setHidden:YES];

		FilesQueue* filesqueue=[(ImageOptim*)[[NSApplication sharedApplication]delegate] valueForKey:@"filesQueue"];
		NSArray *files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];

		//Todo: limit to png and jpeg

		[filesqueue performSelectorInBackground:@selector(addPaths:) withObject:files];
		[[self window]setStyleMask: NSResizableWindowMask| NSClosableWindowMask | NSMiniaturizableWindowMask | NSTitledWindowMask];
		//[[self window] display];
		//NSLog(@"%@",filesqueue);
        //set the image using the best representation we can get from the pasteboard
        // if([NSImage canInitWithPasteboard: [sender draggingPasteboard]])
        //     [[self image] initWithPasteboard: [sender draggingPasteboard]];
        //if the drag comes from a file, set the window title to the filename
        //fileURL=[NSURL URLFromPasteboard: [sender draggingPasteboard]];
       // [[self window] setTitle: fileURL!=NULL ? [fileURL absoluteString] : @"(no name)"];
    }
    return YES;
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame;
{
    /*------------------------------------------------------
       delegate operation to set the standard window frame
    --------------------------------------------------------*/
    NSRect ContentRect=[[self window] frame];//get window frame size
    ContentRect.size=[[self image] size];//set it to the image frame size
    return [NSWindow frameRectForContentRect:ContentRect styleMask: [window styleMask]];
}

//source operations
- (void)mouseDown:(NSEvent*)event
{
   /*------------------------------------------------------
        catch mouse down events in order to start drag
    --------------------------------------------------------*/
    //get the Pasteboard used for drag and drop operations
 /*    NSPasteboard* dragPasteboard=[NSPasteboard pasteboardWithName:NSDragPboard];
    //create a new image for our semi-transparent drag image
    NSImage* dragImage=[[NSImage alloc] initWithSize:[[self image] size]];
    //add the image types we can send the data as(we'll send the actual data when it's requested)
    [dragPasteboard declareTypes:[NSArray arrayWithObject: NSTIFFPboardType] owner:self];
    [dragPasteboard addTypes:[NSArray arrayWithObject:NSPDFPboardType] owner:self];

    [dragImage lockFocus];//draw inside of our dragImage
    //draw our original image as 50% transparent
    [[self image] dissolveToPoint: NSZeroPoint fraction: 0.5f];
    [dragImage unlockFocus];//finished drawing
    [dragImage setScalesWhenResized:YES];//we want the image to resize
    [dragImage setSize:[self bounds].size];//change to the size we are displaying
    //execute the drag
    [self dragImage: dragImage//image to be displayed under the mouse
        at: [self bounds].origin//point to start drawing drag image
        offset: NSZeroSize//no offset, drag starts at mousedown location
        event:event//mousedown event
        pasteboard:dragPasteboard//pasteboard to pass to receiver
        source: self//object where the image is coming from
        slideBack: YES];//if the drag fails slide the icon back
    [dragImage release];//done with our dragImage
	*/
}
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
    /*------------------------------------------------------
        method to set drag masks
    --------------------------------------------------------*/
    return NSDragOperationCopy;//send data as copy operation
}
- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    /*------------------------------------------------------
        accept activation click as click in window
    --------------------------------------------------------*/
    return YES;//so source doesn't have to be the active window
}
- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
	/*----------------------------------
	method called by pasteboard to support promised
        drag types.
    --------------------------------------------------------*/
    //sender has accepted the drag and now we need to send the data for the type we promised
   /* if([type compare: NSTIFFPboardType]==NSOrderedSame){
            //set data for TIFF type on the pasteboard as requested
            [sender setData:[[self image] TIFFRepresentation] forType:NSTIFFPboardType];
    }else if([type compare: NSPDFPboardType]==NSOrderedSame){
            [sender setData:[self dataWithPDFInsideRect:[self bounds]] forType:NSPDFPboardType];
    }*/
}
@end
