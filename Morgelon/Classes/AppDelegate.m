#import "AppDelegate.h"
#import "MorgelonTitleScene.h"

@implementation AppController

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	CCGLView *glView = [CCGLView viewWithFrame:self.window.bounds
								   pixelFormat:kEAGLColorFormatRGB565
								   depthFormat:0
							preserveBackbuffer:NO
									sharegroup:nil
								 multiSampling:NO
							   numberOfSamples:0];

	CCDirectorIOS *director = (CCDirectorIOS *)[CCDirector sharedDirector];
	director.wantsFullScreenLayout = YES;
	director.displayStats = NO;
	director.animationInterval = 1.0 / 60.0;
	director.view = glView;
	director.delegate = self;
	director.projection = CCDirectorProjection2D;
	[director enableRetinaDisplay:YES];

	[CCTexture setDefaultAlphaPixelFormat:CCTexturePixelFormat_RGBA8888];
	CCFileUtils *sharedFileUtils = [CCFileUtils sharedFileUtils];
	sharedFileUtils.enableiPhoneResourcesOniPad = YES;

	[director pushScene:[MorgelonTitleScene scene]];

	self.window.rootViewController = [[UIViewController alloc] init];
	self.window.rootViewController.view = glView;
	[self.window makeKeyAndVisible];
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	[[CCDirector sharedDirector] pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[[CCDirector sharedDirector] resume];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[[CCDirector sharedDirector] stopAnimation];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[[CCDirector sharedDirector] startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[[CCDirector sharedDirector] end];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	[[CCDirector sharedDirector] purgeCachedData];
}

@end
