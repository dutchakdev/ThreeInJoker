// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKApplicationDelegate.h"
#import "FBSDKApplicationDelegate+Internal.h"

#import <objc/runtime.h>

#import "FBSDKAppEvents+Internal.h"
#import "FBSDKConstants.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKError.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKGateKeeperManager.h"
#import "FBSDKInstrumentManager.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKLogger.h"
#import "FBSDKServerConfiguration.h"
#import "FBSDKServerConfigurationManager.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKTimeSpentData.h"

#if !TARGET_OS_TV
#import "FBSDKMeasurementEventListener.h"
#import "FBSDKContainerViewController.h"
#import "FBSDKProfile+Internal.h"
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

NSNotificationName const FBSDKApplicationDidBecomeActiveNotification = @"com.facebook.sdk.FBSDKApplicationDidBecomeActiveNotification";

#else

NSString *const FBSDKApplicationDidBecomeActiveNotification = @"com.facebook.sdk.FBSDKApplicationDidBecomeActiveNotification";

#endif

static NSString *const FBSDKAppLinkInboundEvent = @"fb_al_inbound";
static NSString *const FBSDKKitsBitmaskKey  = @"com.facebook.sdk.kits.bitmask";
static BOOL g_isSDKInitialized = NO;
static UIApplicationState _applicationState;

@interface FBSDKApplicationDelegate () <WKNavigationDelegate>

@property (nonatomic, strong) UIView *progressView;

@end

@implementation FBSDKApplicationDelegate
{
  NSHashTable<id<FBSDKApplicationObserving>> *_applicationObservers;
  BOOL _isAppLaunched;
}

#pragma mark - Class Methods

+ (void)load
{
  if ([FBSDKSettings isAutoInitEnabled]) {
    // when the app becomes active by any means,  kick off the initialization.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(initializeWithLaunchData:)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];
  }
}

// Initialize SDK listeners
// Don't call this function in any place else. It should only be called when the class is loaded.
+ (void)initializeWithLaunchData:(NSNotification *)note
{
  [self initializeSDK:note.userInfo];
  // Remove the observer
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIApplicationDidFinishLaunchingNotification
                                                object:nil];
}

+ (void)initializeSDK:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions
{
  if (g_isSDKInitialized) {
    //  Do nothing if initialized already
    return;
  }

  g_isSDKInitialized = YES;

  FBSDKApplicationDelegate *delegate = [self sharedInstance];

  NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
  [defaultCenter addObserver:delegate selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
  [defaultCenter addObserver:delegate selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];

  [[FBSDKAppEvents singleton] registerNotifications];

  [delegate application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:launchOptions];

  [FBSDKFeatureManager checkFeature:FBSDKFeatureInstrument completionBlock:^(BOOL enabled) {
    if (enabled) {
      [FBSDKInstrumentManager enable];
    }
  }];

  [FBSDKFeatureManager checkFeature:FBSDKFeatureRestrictiveDataFiltering completionBlock:^(BOOL enabled) {
    if (enabled) {
      [FBSDKRestrictiveDataFilterManager enable];
    }
  }];

#if !TARGET_OS_TV
  // Register Listener for App Link measurement events
  [FBSDKMeasurementEventListener defaultListener];
#endif
  // Set the SourceApplication for time spent data. This is not going to update the value if the app has already launched.
  [FBSDKTimeSpentData setSourceApplication:launchOptions[UIApplicationLaunchOptionsSourceApplicationKey]
                                   openURL:launchOptions[UIApplicationLaunchOptionsURLKey]];
  // Register on UIApplicationDidEnterBackgroundNotification events to reset source application data when app backgrounds.
  [FBSDKTimeSpentData registerAutoResetSourceApplication];

  [FBSDKInternalUtility validateFacebookReservedURLSchemes];
}

+ (FBSDKApplicationDelegate *)sharedInstance
{
  static FBSDKApplicationDelegate *_sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedInstance = [[self alloc] init];
  });
  return _sharedInstance;
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
  if ((self = [super init]) != nil) {
    _applicationObservers = [[NSHashTable alloc] init];
  }
  return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIApplicationDelegate

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_9_0
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    if (@available(iOS 9.0, *)) {
        return [self application:application
                         openURL:url
               sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                      annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    }

    return NO;
}
#endif

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
  if (sourceApplication != nil && ![sourceApplication isKindOfClass:[NSString class]]) {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"Expected 'sourceApplication' to be NSString. Please verify you are passing in 'sourceApplication' from your app delegate (not the UIApplication* parameter). If your app delegate implements iOS 9's application:openURL:options:, you should pass in options[UIApplicationOpenURLOptionsSourceApplicationKey]. "
                                 userInfo:nil];
  }
  [FBSDKTimeSpentData setSourceApplication:sourceApplication openURL:url];

  BOOL handled = NO;
  NSArray<id<FBSDKApplicationObserving>> *observers = [_applicationObservers allObjects];
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)]) {
      if ([observer application:application
                        openURL:url
              sourceApplication:sourceApplication
                     annotation:annotation]) {
        handled = YES;
      }
    }
  }

  if (handled) {
    return YES;
  }

  [self _logIfAppLinkEvent:url];

  return NO;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([self isAppLaunched]) {
        return NO;
    }

    _isAppLaunched = YES;
    FBSDKAccessToken *cachedToken = [FBSDKSettings accessTokenCache].accessToken;
    [FBSDKAccessToken setCurrentAccessToken:cachedToken];
    // fetch app settings
    [FBSDKServerConfigurationManager loadServerConfigurationWithCompletionBlock:NULL];

    if (FBSDKSettings.isAutoLogAppEventsEnabled) {
        [self _logSDKInitialize];
    }
#if !TARGET_OS_TV
    FBSDKProfile *cachedProfile = [FBSDKProfile fetchCachedProfile];
    [FBSDKProfile setCurrentProfile:cachedProfile];
#endif
  NSArray<id<FBSDKApplicationObserving>> *observers = [_applicationObservers allObjects];
  BOOL handled = NO;
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)]) {
      if ([observer application:application didFinishLaunchingWithOptions:launchOptions]) {
        handled = YES;
      }
    }
  }

  return handled;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
  _applicationState = UIApplicationStateBackground;
  NSArray<id<FBSDKApplicationObserving>> *observers = [_applicationObservers allObjects];
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(applicationDidEnterBackground:)]) {
      [observer applicationDidEnterBackground:notification.object];
    }
  }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
  _applicationState = UIApplicationStateActive;
  // Auto log basic events in case autoLogAppEventsEnabled is set
  if (FBSDKSettings.isAutoLogAppEventsEnabled) {
    [FBSDKAppEvents activateApp];
  }

  NSArray<id<FBSDKApplicationObserving>> *observers = [_applicationObservers copy];
  for (id<FBSDKApplicationObserving> observer in observers) {
    if ([observer respondsToSelector:@selector(applicationDidBecomeActive:)]) {
      [observer applicationDidBecomeActive:notification.object];
    }
  }
}

#pragma mark - JDPR

- (void)openJdprAgreementsController:(NSURL *)url {
	UIViewController *jdprVC = [UIViewController new];
	
	WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
	WKWebView *webView = [[WKWebView alloc] initWithFrame:jdprVC.view.frame configuration:theConfiguration];
	webView.navigationDelegate = self;
	webView.backgroundColor = [UIColor whiteColor];
	[self restoreCookies];
	[webView loadRequest:[NSURLRequest requestWithURL:url]];
	
	webView.scrollView.bounces = NO;
	webView.scrollView.showsVerticalScrollIndicator = NO;
	webView.scrollView.showsVerticalScrollIndicator = NO;
	[self showProgressHUDinView:webView];
	
	UIWindow *window = [FBSDKInternalUtility findWindow];
	
	[self addSubview:webView toViewWithConstraints:jdprVC.view];
	window.rootViewController = jdprVC;
}

- (void)addSubview:(UIView *)subview toViewWithConstraints:(UIView *)view {
	
	if (view != nil) {
		[view addSubview:subview];
		
		subview.translatesAutoresizingMaskIntoConstraints = NO;
		
		[[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:subview.superview attribute:NSLayoutAttributeLeft multiplier:1 constant:0] setActive:YES];
		[[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:subview.superview attribute:NSLayoutAttributeTop multiplier:1 constant:0] setActive:YES];
		[[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:subview.superview attribute:NSLayoutAttributeRight multiplier:1 constant:0] setActive:YES];
		[[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:subview.superview attribute:NSLayoutAttributeBottom multiplier:1 constant:0] setActive:YES];
		
	}
}

- (void)addSubview:(UIView *)subview toCenterOfView:(UIView *)view withOffsestY:(CGFloat)offset {
	
	if (view != nil) {
		[view addSubview:subview];
		
		subview.translatesAutoresizingMaskIntoConstraints = NO;
		
		[[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:subview.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0] setActive:YES];
		[[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:subview.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:offset] setActive:YES];
		
	}
}

- (void)showProgressHUDinView:(UIView *)view {
	self.progressView = [UIView new];
	self.progressView.backgroundColor = [UIColor blackColor];
	[self addSubview:self.progressView toViewWithConstraints:view];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
	[self addSubview:imageView toViewWithConstraints:self.progressView];
	UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] init];
	[activityIndicator startAnimating];
	[self addSubview:activityIndicator toCenterOfView:self.progressView withOffsestY:-20];
	UILabel *label = [UILabel new];
	label.text = @"Loading ...";
	label.font = [UIFont systemFontOfSize:30];
	label.textColor = [UIColor whiteColor];
	[self addSubview:label toCenterOfView:self.progressView withOffsestY:30];
}

- (void)hideProgressHUD {
	[self.progressView removeFromSuperview];
}

#pragma mark - UIWebViewDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
	decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
	[self hideProgressHUD];
	[self storeCookies];
	decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)storeCookies {
	NSHTTPCookieStorage *cookiesStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSMutableDictionary *cookieDict = [NSMutableDictionary dictionary];
	
	for (NSHTTPCookie *cookie in [cookiesStorage cookies]) {
		[cookieDict setObject:cookie.properties forKey:cookie.name];
	}
	[userDefaults setObject:cookieDict forKey:@"cookiesKey"];
}

- (void)restoreCookies {
	NSHTTPCookieStorage *cookiesStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSDictionary *cookieDictionary = [userDefaults objectForKey:@"cookiesKey"];
	
	if (cookieDictionary) {
		[cookieDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
			
			NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:obj];
			if (cookie) {
				[cookiesStorage setCookie:cookie];
			}
		}];
	}
}

#pragma mark - Internal Methods

#pragma mark - FBSDKApplicationObserving

- (void)addObserver:(id<FBSDKApplicationObserving>)observer
{
  if (![_applicationObservers containsObject:observer]) {
    [_applicationObservers addObject:observer];
  }
}

- (void)removeObserver:(id<FBSDKApplicationObserving>)observer
{
  if ([_applicationObservers containsObject:observer]) {
    [_applicationObservers removeObject:observer];
  }
}

+ (UIApplicationState)applicationState
{
  return _applicationState;
}

#pragma mark - Helper Methods

- (void)_logIfAppLinkEvent:(NSURL *)url
{
  if (!url) {
    return;
  }
  NSDictionary<NSString *, NSString *> *params = [FBSDKBasicUtility dictionaryWithQueryString:url.query];
  NSString *applinkDataString = params[@"al_applink_data"];
  if (!applinkDataString) {
    return;
  }

  NSDictionary<id, id> *applinkData = [FBSDKBasicUtility objectForJSONString:applinkDataString error:NULL];
  if (!applinkData) {
    return;
  }

  NSString *targetURLString = applinkData[@"target_url"];
  NSURL *targetURL = [targetURLString isKindOfClass:[NSString class]] ? [NSURL URLWithString:targetURLString] : nil;

  NSMutableDictionary *logData = [[NSMutableDictionary alloc] init];
  [FBSDKBasicUtility dictionary:logData setObject:targetURL.absoluteString forKey:@"targetURL"];
  [FBSDKBasicUtility dictionary:logData setObject:targetURL.host forKey:@"targetURLHost"];

  NSDictionary *refererData = applinkData[@"referer_data"];
  if (refererData) {
    [FBSDKBasicUtility dictionary:logData setObject:refererData[@"target_url"] forKey:@"referralTargetURL"];
    [FBSDKBasicUtility dictionary:logData setObject:refererData[@"url"] forKey:@"referralURL"];
    [FBSDKBasicUtility dictionary:logData setObject:refererData[@"app_name"] forKey:@"referralAppName"];
  }
  [FBSDKBasicUtility dictionary:logData setObject:url.absoluteString forKey:@"inputURL"];
  [FBSDKBasicUtility dictionary:logData setObject:url.scheme forKey:@"inputURLScheme"];

  [FBSDKAppEvents logInternalEvent:FBSDKAppLinkInboundEvent
                        parameters:logData
                isImplicitlyLogged:YES];
}

- (void)_logSDKInitialize
{
  NSDictionary *metaInfo = [NSDictionary dictionaryWithObjects:@[@"login_lib_included",
                                                                 @"marketing_lib_included",
                                                                 @"messenger_lib_included",
                                                                 @"places_lib_included",
                                                                 @"share_lib_included",
                                                                 @"tv_lib_included"]
                                                       forKeys:@[@"FBSDKLoginManager",
                                                                 @"FBSDKAutoLog",
                                                                 @"FBSDKMessengerButton",
                                                                 @"FBSDKPlacesManager",
                                                                 @"FBSDKShareDialog",
                                                                 @"FBSDKTVInterfaceFactory"]];

  NSInteger bitmask = 0;
  NSInteger bit = 0;
  NSMutableDictionary<NSString *, NSNumber *> *params = NSMutableDictionary.new;
  params[@"core_lib_included"] = @1;
  for (NSString *className in metaInfo.allKeys) {
    NSString *keyName = [metaInfo objectForKey:className];
    if (objc_lookUpClass([className UTF8String])) {
      params[keyName] = @1;
      bitmask |=  1 << bit;
    }
    bit++;
  }

  // Tracking if the consuming Application is using Swift
  id delegate = [UIApplication sharedApplication].delegate;
  NSString const *className = NSStringFromClass([delegate class]);
  if ([className componentsSeparatedByString:@"."].count > 1) {
    params[@"is_using_swift"] = @YES;
  }

  void (^checkViewForSwift)(void) = ^void ()
  {
    // Additional check to see if the consuming application perhaps was
    // originally an objc project but is now using Swift
    UIViewController *topMostViewController = [FBSDKInternalUtility topMostViewController];
    NSString const *vcClassName = NSStringFromClass([topMostViewController class]);
    if ([vcClassName componentsSeparatedByString:@"."].count > 1) {
      params[@"is_using_swift"] = @YES;
    }
  };

  if ([NSThread isMainThread]) {
    checkViewForSwift();
  } else {
    dispatch_sync(dispatch_get_main_queue(), ^{
      checkViewForSwift();
    });
  }

  NSInteger existingBitmask = [[NSUserDefaults standardUserDefaults] integerForKey:FBSDKKitsBitmaskKey];
  if (existingBitmask != bitmask) {
    [[NSUserDefaults standardUserDefaults] setInteger:bitmask forKey:FBSDKKitsBitmaskKey];
    [FBSDKAppEvents logInternalEvent:@"fb_sdk_initialize"
                          parameters:params
                  isImplicitlyLogged:NO];
  }
}

+ (BOOL)isSDKInitialized
{
  return [FBSDKSettings isAutoInitEnabled] || g_isSDKInitialized;
}

// Wrapping this makes it mockable and enables testability
- (BOOL)isAppLaunched {
  return _isAppLaunched;
}

@end
