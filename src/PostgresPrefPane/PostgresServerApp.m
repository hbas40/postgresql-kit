
#import "PostgresServerApp.h"
#import "PostgresPrefPaneShared.h"

NSTimeInterval PostgresServerAppBackupTimerInterval = 10.0; // TODO: backup fires once every five minutes

@implementation PostgresServerApp

@synthesize server;
@synthesize connection;
@synthesize dataPath;
@synthesize backupPath;
@synthesize isRemoteAccess;
@synthesize isBackupEnabled;
@synthesize backupTimeInterval;
@synthesize serverPort;
@synthesize defaultServerPort;
@synthesize backupTimer;

-(void)dealloc {
	[self setDataPath:nil];
	[self setBackupPath:nil];
	[self setConnection:nil];
	[self setServer:nil];
	[[self backupTimer] invalidate];
	[self setBackupTimer:nil];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////

-(BOOL)awakeThread {

	// set up shared postgres object
	[self setServer:[FLXServer sharedServer]];
	if([self server]==nil) {
		return NO;
	}
	
	// set postgres delegate
	[[self server] setDelegate:self];

	// NSConnection object
	[self setConnection:[NSConnection defaultConnection]];
	[[self connection] setRootObject:self];
	if([[self connection] registerName:PostgresServerAppIdentifier]==NO) {
		return NO;
	}

	// set server port to default
	defaultServerPort = [FLXServer defaultPort];	
	[self setServerPort:defaultServerPort];
	
	// success
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// messages

-(void)startServer {

	// set server info
	if([self isRemoteAccess]) {
		[[self server] setHostname:@"*"];
		[[self server] setPort:[self serverPort]];
		NSLog(@"Setting hostname as %@ and port as %d",[[self server] hostname],[[self server] port]);
	} else {
		[[self server] setHostname:nil];
		NSLog(@"Setting hostname as nil");
	}
		
	// create application support path
	BOOL isDirectory = NO;
	if([[NSFileManager defaultManager] fileExistsAtPath:[self dataPath] isDirectory:&isDirectory]==NO) {
		[[NSFileManager defaultManager] createDirectoryAtPath:[self dataPath] attributes:nil];
	}
	
	// initialize the data directory if nesessary
	NSString* theDataDirectory = [[self dataPath] stringByAppendingPathComponent:@"data"];
	if([[self server] startWithDataPath:theDataDirectory]==NO) {
		// starting failed, possibly because a server is already running
		if([[self server] state]==FLXServerStateAlreadyRunning) {
			[[self server] stop];
		}
	}    
	
	// start backup timer
	[self setBackupTimer:[NSTimer scheduledTimerWithTimeInterval:PostgresServerAppBackupTimerInterval target:self selector:@selector(backupTimerDidFire:) userInfo:nil repeats:YES]];
}

-(void)stopServer {
	[[self backupTimer] invalidate];
	[self setBackupTimer:nil];	
	[[self server] stop];
}

-(NSString* )serverVersion {
	NSString* serverVersion = [[[self server] serverVersion] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSString* serverPrefix = @"postgres (PostgreSQL) ";
	if([serverVersion hasPrefix:serverPrefix]) {
		return [serverVersion substringFromIndex:[serverPrefix length]];
	} else {
		return serverVersion;
	}
}

-(FLXServerState)serverState {
	return [[self server] state];
}

-(NSString* )serverStateAsString {
	return [[self server] stateAsString];
}

////////////////////////////////////////////////////////////////////////////////

-(NSString* )dataSpaceFreeAsString {
	NSParameterAssert([self dataPath]);
	NSDictionary* theDictionary = [[NSFileManager defaultManager] fileSystemAttributesAtPath:[self dataPath]];
	if(theDictionary==nil) return nil;
	unsigned long long theFreeBytes = [[theDictionary objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];		
	if(theFreeBytes >= (1024L * 1024L * 1024L)) {
		return [NSString stringWithFormat:@"%.2fGB",(double)theFreeBytes / (double)(1024L * 1024L * 1024L)];
	}
	if(theFreeBytes >= (1024L * 1024L)) {
		return [NSString stringWithFormat:@"%.2fMB",(double)theFreeBytes / (double)(1024L * 1024L)];
	}
	if(theFreeBytes >= 1024) {
		return [NSString stringWithFormat:@"%.2fKB",(double)theFreeBytes / (double)(1024L)];
	}
	return [NSString stringWithFormat:@"%llu bytes",theFreeBytes];
}

////////////////////////////////////////////////////////////////////////////////

-(void)backupTimerDidFire:(id)sender {
	NSString* theDirectory = [[self backupPath] stringByAppendingPathComponent:@"backup"];
	// ensure is a directory, etc
	BOOL isDirectory;
	if([[NSFileManager defaultManager] fileExistsAtPath:theDirectory isDirectory:&isDirectory]==NO) {
		// we create the directory at the path
		NSDictionary* theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:0750],NSFilePosixPermissions,nil];
		BOOL isCreated = [[NSFileManager defaultManager] createDirectoryAtPath:theDirectory attributes:theAttributes];
		if(isCreated==NO) {
			[self serverMessage:[NSString stringWithFormat:@"Unable to create directory at path: %@",theDirectory]];
			return;
		}
	}
	if(isDirectory==NO) {
		[self serverMessage:[NSString stringWithFormat:@"Not a directory at path: %@",theDirectory]];
		return;		
	}
	// ok - read contents of directory to find the latest file
	NSLog(@"TODO: read contents of directory");	
}

////////////////////////////////////////////////////////////////////////////////

-(void)serverMessage:(NSString* )theMessage {
	NSLog(@"server message: %@",theMessage);
}

-(void)serverStateDidChange:(NSString* )theMessage {
	NSLog(@"server state did change: %@",theMessage);	
}

@end