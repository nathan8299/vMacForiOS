#import "AppDelegate.h"
#import "MainView.h"
#import "EmulationManager.h"
#import "SSZipArchive.h"
#import "MBProgressHUD.h"

@interface UIWindow (Additions)
- (void)makeKey:(id)arg1;
- (void)orderFront:(id)arg1;
- (void)setContentView:(id)arg1;
@end

@interface AppDelegate ()
@property (strong, nonatomic) MBProgressHUD *progressHUD;
@end

IMPORTFUNC blnr InitEmulation(void);
IMPORTFUNC int is_iPad(void);

@implementation AppDelegate

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if (url != nil && [url isFileURL]) {
		NSString *docdir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
		
		if ([[url lastPathComponent] rangeOfString:@"dsk" options:NSCaseInsensitiveSearch].location != NSNotFound) {
			NSError *error = nil;
			
			[[NSFileManager defaultManager] moveItemAtURL:url toURL:[NSURL fileURLWithPath:[docdir stringByAppendingPathComponent:[url lastPathComponent]]] error:&error];
			
			if (!error) {
				[self alertWithTitle:@"Success" message:[NSString stringWithFormat:@"The file, %@, has been transferred to the disk list.", [url lastPathComponent]]];
			}
			else {
				[self alertWithTitle:@"Error" message:[NSString stringWithFormat:@"The file, %@, has not been transferred to the disk list.", [url lastPathComponent]]];
                
			}
		}
		else if ([[url lastPathComponent] rangeOfString:@"zip" options:NSCaseInsensitiveSearch].location != NSNotFound) {
			if ([SSZipArchive unzipFileAtPath:[url path] toDestination:docdir]) {
				[self alertWithTitle:@"Success" message:[NSString stringWithFormat:@"The file, %@, has been unzipped and transferred to the package list.", [url lastPathComponent]]];
				
				NSError *error = nil;
				
				[[NSFileManager defaultManager] removeItemAtPath:[url path] error:&error];
				
				if (error) {
					[self alertWithTitle:@"Error" message:@"Although the package was successfully unzipped, there was an error removing the zip file."];
				}
			}
			else {
				[self alertWithTitle:@"Error" message:[NSString stringWithFormat:@"The file, %@, has not been transferred to the disk list.", [url lastPathComponent]]];
			}
		}
		return YES;
	}
	
	return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setInitOk:[[EmulationManager sharedManager] initEmulation]];
    [self initPreferences];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [self setWindow:[[UIWindow alloc] init]];
    
    if (IPAD()==YES) {
        [_window setFrame:CGRectMake(0, 0, 1024, 768)];
        [_window setTransform:CGAffineTransformMake(0, -1, 1, 0, -128, 128)];
    }
    else {
        [_window setFrame:CGRectMake(0, 0, 568, 320)];
        [_window setTransform:CGAffineTransformMake(0, -1, 1, 0, -80, 120)];
    }
    
    [self setMainView:[[MainView alloc] initWithFrame:[[self window] bounds]]];
    
    [_window setContentView:_mainView];
    [_window makeKeyAndVisible];
    
    if (_initOk) {
        [[EmulationManager sharedManager] startEmulation:self];
    }
    
    [self setProgressHUD:[MBProgressHUD showHUDAddedTo:[self mainView] animated:YES]];
    [[self progressHUD] setRemoveFromSuperViewOnHide:YES];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"dismiss_hud" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *aNotification) {
        [[self progressHUD] hide:YES];
    }];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[EmulationManager sharedManager] suspendEmulation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[EmulationManager sharedManager] resumeEmulation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[EmulationManager sharedManager] suspendEmulation];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initPreferences
{    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
     @"KeyboardLayout": @"US",
     @"ScreenSizeToFit": [NSNumber numberWithBool:YES],
     @"KeyboardAlpha": [NSNumber numberWithFloat:0.8],
     @"ScreenPosition": [NSNumber numberWithInt:dirUp | dirLeft],
     @"Sound Enabled": [NSNumber numberWithBool:YES],
     @"DiskEjectSound": [NSNumber numberWithBool:YES],
     @"TrackpadMode": [NSNumber numberWithBool:NO],
     @"KeyboardSound": [NSNumber numberWithBool:YES],
     @"CanDeleteDiskImages": [NSNumber numberWithBool:YES]}];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferences:) name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)didChangePreferences:(NSNotification *)aNotification
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SoundEnabled"]) {
        MySound_Start();
    }
    else {
        MySound_Stop();
    }
}

-(void)alertWithTitle:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
	
	[alert show];
}

@end
