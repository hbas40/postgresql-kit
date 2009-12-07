
#import <Cocoa/Cocoa.h>
#import <PostgresServerKit/PostgresServerKit.h>
#import "AppDelegate.h"

@interface IdentityMapPreferences : NSObject {
	NSWindow* ibMainWindow;
	NSWindow* ibIdentityMapWindow;
	AppDelegate* ibAppDelegate;
	NSArrayController* ibGroupsArrayController;
}

// IB Outlets
@property (assign) IBOutlet NSWindow* ibMainWindow;
@property (assign) IBOutlet NSWindow* ibIdentityMapWindow;
@property (assign) IBOutlet AppDelegate* ibAppDelegate;
@property (assign) IBOutlet NSArrayController* ibGroupsArrayController;

// properties
@property (readonly) FLXPostgresServer* server;

// IB Actions
-(IBAction)doIdentityMap:(id)sender;
-(IBAction)doButton:(id)sender;

@end