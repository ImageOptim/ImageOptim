//
//  File.m
//
//  Created by porneL on 8.wrz.07.
//

#import "File.h"

#import "Workers/AdvCompWorker.h"
#import "Workers/PngoutWorker.h"
#import "Workers/OptiPngWorker.h"
#import "Workers/PngCrushWorker.h"
#import "Workers/JpegoptimWorker.h"
#import "Workers/JpegtranWorker.h"
#import "Workers/GifsicleWorker.h"
//#import "Dupe.h"

@implementation File

@synthesize byteSize, byteSizeOptimized, filePath, displayName, statusText, statusOrder, statusImage, percentDone;

-(id)initWithFilePath:(NSString *)name;
{
	if (self = [self init])
	{	
		[self setFilePath:name];
		[self setStatus:@"wait" order:0 text:NSLocalizedString(@"New file",@"newly added to the queue")];
	}
	return self;	
}


-(NSString *)fileName
{	
	if (displayName) return displayName;
	if (filePath) return filePath;
	return nil;
}

-(void)setFilePath:(NSString *)s
{
	if (filePath != s)
	{
		filePath = [s copy];
		
        self.displayName = [[NSFileManager defaultManager] displayNameAtPath:filePath];		
	}
}

- (id)copyWithZone:(NSZone *)zone
{
	File *f = [[File allocWithZone:zone] init];
	[f setByteSize:byteSize];
	[f setByteSizeOptimized:byteSizeOptimized];
	[f setFilePath:filePath];
	return f;
}

-(void)setByteSize:(NSUInteger)size
{
    @synchronized(self) 
    {        
        if (!byteSize && size > 10)
        {
            byteSize = size;
            if (!byteSizeOptimized || byteSizeOptimized > byteSize) [self setByteSizeOptimized:size];		
        }
    }
}

-(double)percentOptimized
{
	if (!byteSizeOptimized) return 0.0;
	double p = 100.0 - 100.0* (double)byteSizeOptimized/(double)byteSize;
	if (p<0) return 0.0;
	return p;
}

-(void)setPercentOptimized:(double)unused
{
	// just for KVO
}

-(BOOL)isOptimized
{
	return byteSizeOptimized < byteSize;
}

-(BOOL)isDone
{
	return done;
}

-(void)setByteSizeOptimized:(NSUInteger)size
{
    @synchronized(self) 
    {        
        if ((!byteSizeOptimized || size < byteSizeOptimized) && size > 30)
        {
    //		NSLog(@"We've got a new winner. old %d new %d",byteSizeOptimized,size);
            byteSizeOptimized = size;
            [self setPercentOptimized:0.0]; //just for KVO
        }
    }
}

-(void)removeOldFilePathOptimized
{
	if (filePathOptimized)
	{
        if ([filePathOptimized length])
        {
            [[NSFileManager defaultManager] removeItemAtPath:filePathOptimized error:nil];
        }
        filePathOptimized = nil;
	}
}

-(void)setFilePathOptimized:(NSString *)path size:(NSUInteger)size toolName:(NSString*)toolname
{
    @synchronized(self) 
    {        
        NSLog(@"File %@ optimized with %@ from %u to %u in %@",filePath?filePath:filePathOptimized,toolname,(unsigned int)byteSizeOptimized,(unsigned int)size,path);
        if (size <= byteSizeOptimized)
        {
            bestToolName = [toolname stringByReplacingOccurrencesOfString:@"Worker" withString:@""];
            assert(![filePathOptimized isEqualToString:path]);
            [self removeOldFilePathOptimized];
            filePathOptimized = path;
            [self setByteSizeOptimized:size];
        }
    }
}

-(BOOL)saveResult
{
	if (!filePathOptimized) 
	{
		NSLog(@"WTF? save without filePathOptimized? for %@", filePath);
		return NO;
	}
	
	@try
	{
		NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
		BOOL preserve = [defs boolForKey:@"PreservePermissions"];
		BOOL backup = [defs boolForKey:@"BackupFiles"];
		NSFileManager *fm = [NSFileManager defaultManager];
		
		if (backup)
		{
            NSError *error = nil;
			NSString *backupPath = [filePath stringByAppendingString:@"~"];
			
			[fm removeItemAtPath:backupPath error:nil];// ignore error
			
			BOOL res;
			if (preserve)
			{
				res = [fm copyItemAtPath:filePath toPath:backupPath error:&error];
			}
            else
			{
				res = [fm moveItemAtPath:filePath toPath:backupPath error:&error];
			}
			
			if (!res)
			{
				NSLog(@"failed to save backup as %@ (preserve = %d) %@",backupPath,preserve,error);
				return NO;
			}
		}
		
		if (preserve)
		{		
			NSFileHandle *writehandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
			NSData *data = [NSData dataWithContentsOfFile:filePathOptimized];
			
			if (writehandle && data && [data length] == byteSizeOptimized && [data length] > 34)
			{
				[writehandle writeData:data];
				[writehandle truncateFileAtOffset:[data length]];
                [writehandle closeFile];
                [self removeOldFilePathOptimized];
			}
			else 
			{
				NSLog(@"Temp file size %u does not match expected %u in %@ for %@",(unsigned int)[data length],(unsigned int)byteSizeOptimized,filePathOptimized,filePath);
				return NO;				
			}
		}
		else
		{
            NSError *error = nil;
			if (!backup) {[fm removeItemAtPath:filePath error:nil];} //ignore error
			
			if ([fm moveItemAtPath:filePathOptimized toPath:filePath error:&error]) 
			{
                filePathOptimized = nil;
            }            
            else
            {
                NSLog(@"Failed to move from %@ to %@; %@",filePathOptimized, filePath, error);
				return NO;				
			}
		}
	}
	@catch(NSException *e)
	{
		NSLog(@"Exception thrown %@",e);
		return NO;
	}
	
	return YES;
}

-(void)workerHasStarted:(Worker *)worker
{
	@synchronized(self)
    {
		workersActive++;
        NSString *name = [[worker className] stringByReplacingOccurrencesOfString:@"Worker" withString:@""];
        [self setStatus:@"progress" order:4 text:[NSString stringWithFormat:NSLocalizedString(@"Started %@",@"command name"),name]];
    }
}

-(void)saveResultAndUpdateStatus {
    if ([self saveResult])
    { 
        done = YES;
        [self setStatus:@"ok" order:7 text:[NSString stringWithFormat:NSLocalizedString(@"Optimized successfully with %@",@"tooltip"),bestToolName]];
    }
    else 
    {
        NSLog(@"saveResult failed");
        [self setStatus:@"err" order:9 text:NSLocalizedString(@"Optimized file could not be saved",@"tooltip")];				
    }
}

-(void)workerHasFinished:(Worker *)worker
{
	@synchronized(self) 
    {
        workersActive--;
        workersFinished++;
       
        if (!workersActive)
        {
            if (!byteSize || !byteSizeOptimized)
            {
                NSLog(@"worker %@ finished, but result file has 0 size",worker);
                [self setStatus:@"err" order:8 text:NSLocalizedString(@"Size of optimized file is 0",@"tooltip")];
            }
            else if (workersFinished == workersTotal)
            {
                if (byteSize > byteSizeOptimized)
                {
                    NSOperation *saveOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(saveResultAndUpdateStatus) object:nil];
                    [workers addObject:saveOp];
                    [fileIOQueue addOperation:saveOp];                    
                }
                else
                {
                    done = YES;
                    [self setStatus:@"noopt" order:5 text:NSLocalizedString(@"File cannot be optimized any further",@"tooltip")];	
//                    if (dupe) [Dupe addDupe:dupe];
                }
            }
            else
            {
                [self setStatus:@"wait" order:2 text:NSLocalizedString(@"Waiting to start more optimisations",@"tooltip")];
            }
        }
    }	    
}

//-(void)checkDupe:(NSData *)data {
//    Dupe *d = [[Dupe alloc] initWithData:data];
//    @synchronized(self) {
//        dupe = d;        
//    }
//    if ([Dupe isDupe:dupe])
//    {
//        [self cleanup];
//        [self setStatus:@"noopt" text:@"File was already optimized by ImageOptim"];
//    }
//    
//}

#define FILETYPE_PNG 1
#define FILETYPE_JPEG 2
#define FILETYPE_GIF 3

-(int)fileType:(NSData *)data
{
	const unsigned char pngheader[] = {0x89,0x50,0x4e,0x47,0x0d,0x0a};
    const unsigned char jpegheader[] = {0xff,0xd8,0xff};
    const unsigned char gifheader[] = {0x47,0x49,0x46,0x38};
    char filedata[6];

    [data getBytes:filedata length:sizeof(filedata)];
    
	if (0==memcmp(filedata, pngheader, sizeof(pngheader)))
	{
		return FILETYPE_PNG;
	}
    else if (0==memcmp(filedata, jpegheader, sizeof(jpegheader)))
    {
        return FILETYPE_JPEG;
    }
    else if (0==memcmp(filedata, gifheader, sizeof(gifheader)))
    {
        return FILETYPE_GIF;
    }
	return 0;
}

-(void)enqueueWorkersInCPUQueue:(NSOperationQueue *)queue fileIOQueue:(NSOperationQueue *)aFileIOQueue
{
    fileIOQueue = aFileIOQueue; // will be used for saving
    
    [self setStatus:@"wait" order:0 text:NSLocalizedString(@"Waiting in queue",@"tooltip")];
    
    @synchronized(self)
    {
        workersActive++; // isBusy must say yes!
    }
    
    workers = [[NSMutableArray alloc] initWithCapacity:10];
    
    NSOperation *actualEnqueue = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(doEnqueueWorkersInCPUQueue:) object:queue];
    [workers addObject:actualEnqueue];
    [fileIOQueue addOperation:actualEnqueue];        
}

-(void)doEnqueueWorkersInCPUQueue:(NSOperationQueue *)queue 
{  
    [self setStatus:@"progress" order:3 text:NSLocalizedString(@"Inspecting file",@"tooltip")];        

    @synchronized(self)
    {
        workersActive--;        
        byteSize=0; // reset to allow restart
        byteSizeOptimized=0;
    }
    	
	
	NSMutableArray *runFirst = [NSMutableArray new];
	NSMutableArray *runLater = [NSMutableArray new];
		
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
    NSData *fileData = [NSData dataWithContentsOfMappedFile:filePath];
    NSUInteger length = [fileData length];
    if (!fileData || !length)
    {
        [self setStatus:@"err" order:8 text:NSLocalizedString(@"Can't map file into memory",@"tooltip")]; 
        return;
    }
    [self setByteSize:length];

    int fileType = [self fileType:fileData];
    
	if (fileType == FILETYPE_PNG)
	{
        Worker *w = nil;
        BOOL chunksRemoved=NO;
		if ([defs boolForKey:@"PngCrushEnabled"])
		{
			w = [[PngCrushWorker alloc] initWithFile:self];
			if ([w makesNonOptimizingModifications]) {chunksRemoved=YES;[runFirst addObject:w];}
			else [runLater addObject:w];
		}
		if ([defs boolForKey:@"OptiPngEnabled"])
		{
			w = [[OptiPngWorker alloc] initWithFile:self];
			if ([w makesNonOptimizingModifications]) [runFirst addObject:w];
			else [runLater addObject:w];
		}
		if ([defs boolForKey:@"PngOutEnabled"])
		{
			w = [[PngoutWorker alloc] initWithFile:self];
			if (!chunksRemoved && [w makesNonOptimizingModifications]) [runFirst addObject:w];
			else [runLater addObject:w];
		}
		if ([defs boolForKey:@"AdvPngEnabled"])
		{
			w = [[AdvCompWorker alloc] initWithFile:self];
			if ([w makesNonOptimizingModifications]) [runFirst addObject:w];
			else [runLater addObject:w];
		}
	}
	else if (fileType == FILETYPE_JPEG)
    {
        if ([defs boolForKey:@"JpegOptimEnabled"])
        {
            Worker *w = [[JpegoptimWorker alloc] initWithFile:self];
            if ([w makesNonOptimizingModifications]) [runFirst addObject:w];
			else [runLater addObject:w];
        }
        if ([defs boolForKey:@"JpegTranEnabled"])
        {
            Worker *w = [[JpegtranWorker alloc] initWithFile:self];
            [runLater addObject:w];
        }
    }
	else if (fileType == FILETYPE_GIF)
    {
        if ([defs boolForKey:@"GifsicleEnabled"])
        {
            GifsicleWorker *w = [[GifsicleWorker alloc] initWithFile:self];
            w.interlace = NO;
            [runLater addObject:w];
            
            w = [[GifsicleWorker alloc] initWithFile:self];
            w.interlace = YES;
            [runLater addObject:w];
        }
    }
    else {
        [self setStatus:@"err" order:8 text:NSLocalizedString(@"File is neither PNG, GIF nor JPEG",@"tooltip")];
		//NSBeep();
        [self cleanup];
        return;
    }
    
//    NSOperation *checkDupe = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(checkDupe:) object:fileData];
//    // largeish files are best to skip
//    if (length > 10000) [checkDupe setQueuePriority:NSOperationQueuePriorityHigh];
//    else if (length < 3000) [checkDupe setQueuePriority:NSOperationQueuePriorityLow];
//    [workers addObject:checkDupe];
//    [fileIOQueue addOperation:checkDupe];
    
	Worker *lastWorker = nil;
	
	workersTotal += [runFirst count] + [runLater count];

	for(Worker *w in runFirst)
	{
        if (lastWorker) 
        {
            [w addDependency:lastWorker];            
        }
        else {
            [w setQueuePriority:NSOperationQueuePriorityLow]; // finish first!
        }
		[queue addOperation:w];
		lastWorker = w;
	}
	
    lastWorker = [runFirst lastObject];
	for(Worker *w in runLater)
	{
        if (lastWorker) [w addDependency:lastWorker];
		[queue addOperation:w];
	}	
	
    [workers addObjectsFromArray:runFirst];
    [workers addObjectsFromArray:runLater];
    
	if (!workersTotal) 
	{
		[self setStatus:@"err" order:8 text:NSLocalizedString(@"All neccessary tools have been disabled in Preferences",@"tooltip")];
        [self cleanup];
	}
    else {
        [self setStatus:@"wait" order:1 text:NSLocalizedString(@"Waiting to be optimized",@"tooltip")];
    }
}

-(void)cleanup
{
    @synchronized(self)
    {
        [workers makeObjectsPerformSelector:@selector(cancel)];
        [workers removeAllObjects];
        [self removeOldFilePathOptimized];
    }
}

-(BOOL)isBusy
{
    BOOL isit;
    @synchronized(self)
    {
        isit = workersActive || workersTotal != workersFinished;        
    }
    return isit;
}

-(void)setStatus:(NSString *)imageName order:(NSInteger)order text:(NSString *)text
{
    @synchronized(self) 
    {
        if (statusText == text) return;
        statusOrder = order;
        self.statusText = text;
        self.statusImage = [NSImage imageNamed:imageName];
    }
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"%@ %d/%d (workers active %d, finished %d, total %d)", self.filePath,self.byteSize,self.byteSizeOptimized, workersActive, workersFinished, workersTotal];
}

+(NSInteger)fileByteSize:(NSString *)afile
{
	NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:afile error:nil];
	if (attr) return [[attr objectForKey:NSFileSize] integerValue];
    NSLog(@"Could not stat %@",afile);
	return 0;
}

@end
