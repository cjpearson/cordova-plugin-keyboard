/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVKeyboard.h"
#import <Cordova/CDVAvailability.h>
#import <objc/runtime.h>

#ifndef __CORDOVA_3_2_0
#warning "The keyboard plugin is only supported in Cordova 3.2 or greater, it may not work properly in an older version. If you do use this plugin in an older version, make sure the HideKeyboardFormAccessoryBar and KeyboardShrinksView preference values are false."
#endif

@interface CDVKeyboard () <UIScrollViewDelegate>

@property (nonatomic, readwrite, assign) BOOL keyboardIsVisible;

@end

@interface AnimationDetails : NSObject
@property (nonatomic, readwrite, assign) CGFloat from;
@property (nonatomic, readwrite, assign) CGFloat to;
@property (nonatomic, readwrite, assign) CGRect screen;
@end

@implementation AnimationDetails

@end;

@implementation CDVKeyboard {
    AnimationDetails *_animationDetails;
    BOOL _shouldAnimateWebView;
}

- (id)settingForKey:(NSString*)key
{
    return [self.commandDelegate.settings objectForKey:[key lowercaseString]];
}

#pragma mark Initialize

- (void)pluginInitialize
{
    NSString* setting = nil;

    _shouldAnimateWebView = NO;
    setting = @"HideKeyboardFormAccessoryBar";
    if ([self settingForKey:setting]) {
        self.hideFormAccessoryBar = [(NSNumber*)[self settingForKey:setting] boolValue];
    }

    setting = @"KeyboardShrinksView";
    if ([self settingForKey:setting]) {
        self.shrinkView = [(NSNumber*)[self settingForKey:setting] boolValue];
    }

    setting = @"DisableScrollingWhenKeyboardShrinksView";
    if ([self settingForKey:setting]) {
        self.disableScrollingInShrinkView = [(NSNumber*)[self settingForKey:setting] boolValue];
    }

    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    __weak CDVKeyboard* weakSelf = self;

    _keyboardShowObserver = [nc addObserverForName:UIKeyboardDidShowNotification
                                            object:nil
                                             queue:[NSOperationQueue mainQueue]
                                        usingBlock:^(NSNotification* notification) {
            [weakSelf.commandDelegate evalJs:@"Keyboard.fireOnShow();"];
                                        }];
    _keyboardHideObserver = [nc addObserverForName:UIKeyboardDidHideNotification
                                            object:nil
                                             queue:[NSOperationQueue mainQueue]
                                        usingBlock:^(NSNotification* notification) {
            [weakSelf.commandDelegate evalJs:@"Keyboard.fireOnHide();"];
                                        }];

    _keyboardWillShowObserver = [nc addObserverForName:UIKeyboardWillShowNotification
                                                object:nil
                                                 queue:[NSOperationQueue mainQueue]
                                            usingBlock:^(NSNotification* notification) {
            [weakSelf.commandDelegate evalJs:@"Keyboard.fireOnShowing();"];
            weakSelf.keyboardIsVisible = YES;
                                            }];
    _keyboardWillHideObserver = [nc addObserverForName:UIKeyboardWillHideNotification
                                                object:nil
                                                 queue:[NSOperationQueue mainQueue]
                                            usingBlock:^(NSNotification* notification) {
            [weakSelf.commandDelegate evalJs:@"Keyboard.fireOnHiding();"];
            weakSelf.keyboardIsVisible = NO;
                                            }];

    _shrinkViewKeyboardWillChangeFrameObserver = [nc addObserverForName:UIKeyboardWillChangeFrameNotification
                                                                 object:nil
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification* notification) {
                                                                 [weakSelf performSelector:@selector(shrinkViewKeyboardWillChangeFrame:) withObject:notification afterDelay:0];
                                                                 CGRect screen = [[UIScreen mainScreen] bounds];
                                                                 CGRect keyboard = ((NSValue*)notification.userInfo[@"UIKeyboardFrameEndUserInfoKey"]).CGRectValue;
                                                                 CGRect intersection = CGRectIntersection(screen, keyboard);
                                                                 CGFloat height = MIN(intersection.size.width, intersection.size.height);
                                                                 [weakSelf.commandDelegate evalJs: [NSString stringWithFormat:@"cordova.fireWindowEvent('keyboardHeightWillChange', { 'keyboardHeight': %f })", height]];
                                                             }];

    self.webView.scrollView.delegate = self;
}

#pragma mark HideFormAccessoryBar

static IMP UIOriginalImp;
static IMP WKOriginalImp;

- (void)setHideFormAccessoryBar:(BOOL)hideFormAccessoryBar
{
    if (hideFormAccessoryBar == _hideFormAccessoryBar) {
        return;
    }

    NSString* UIClassString = [@[@"UI", @"Web", @"Browser", @"View"] componentsJoinedByString:@""];
    NSString* WKClassString = [@[@"WK", @"Content", @"View"] componentsJoinedByString:@""];

    Method UIMethod = class_getInstanceMethod(NSClassFromString(UIClassString), @selector(inputAccessoryView));
    Method WKMethod = class_getInstanceMethod(NSClassFromString(WKClassString), @selector(inputAccessoryView));

    if (hideFormAccessoryBar) {
        UIOriginalImp = method_getImplementation(UIMethod);
        WKOriginalImp = method_getImplementation(WKMethod);

        IMP newImp = imp_implementationWithBlock(^(id _s) {
            return nil;
        });

        method_setImplementation(UIMethod, newImp);
        method_setImplementation(WKMethod, newImp);
    } else {
        method_setImplementation(UIMethod, UIOriginalImp);
        method_setImplementation(WKMethod, WKOriginalImp);
    }

    _hideFormAccessoryBar = hideFormAccessoryBar;
}

#pragma mark KeyboardShrinksView

- (void)setShrinkView:(BOOL)shrinkView
{
    // Remove WKWebView's keyboard observers when using shrinkView
    // They've caused several issues with the plugin (#32, #55, #64)
    // Even if you later set shrinkView to false, the observers will not be added back
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    if ([self.webView isKindOfClass:NSClassFromString(@"WKWebView")]) {
        [nc removeObserver:self.webView name:UIKeyboardWillHideNotification object:nil];
        [nc removeObserver:self.webView name:UIKeyboardWillShowNotification object:nil];
        [nc removeObserver:self.webView name:UIKeyboardWillChangeFrameNotification object:nil];
        [nc removeObserver:self.webView name:UIKeyboardDidChangeFrameNotification object:nil];
    }
    _shrinkView = shrinkView;
}

- (void)shrinkViewKeyboardWillChangeFrame:(NSNotification*)notif
{
    BOOL shouldAnimate = _shouldAnimateWebView;
    // No-op on iOS 7.0.  It already resizes webview by default, and this plugin is causing layout issues
    // with fixed position elements.  We possibly should attempt to implement shrinkview = false on iOS7.0.
    // iOS 7.1+ behave the same way as iOS 6
    if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_7_1 && NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        return;
    }

    // If the view is not visible, we should do nothing. E.g. if the inappbrowser is open.
    if (!(self.viewController.isViewLoaded && self.viewController.view.window)) {
        return;
    }

    self.webView.scrollView.scrollEnabled = YES;

    CGRect screen = [[UIScreen mainScreen] bounds];
    CGRect statusBar = [[UIApplication sharedApplication] statusBarFrame];
    CGRect keyboard = ((NSValue*)notif.userInfo[@"UIKeyboardFrameEndUserInfoKey"]).CGRectValue;

    // Work within the webview's coordinate system
    keyboard = [self.webView convertRect:keyboard fromView:nil];
    statusBar = [self.webView convertRect:statusBar fromView:nil];
    screen = [self.webView convertRect:screen fromView:nil];

    // if the webview is below the status bar, offset and shrink its frame
    if ([self settingForKey:@"StatusBarOverlaysWebView"] != nil && ![[self settingForKey:@"StatusBarOverlaysWebView"] boolValue]) {
        CGRect full, remainder;
        CGRectDivide(screen, &remainder, &full, statusBar.size.height, CGRectMinYEdge);
        screen = full;
    }

    CGFloat currentScreenHeight = self.webView.frame.size.height;

    // Get the intersection of the keyboard and screen and move the webview above it
    // Note: we check for _shrinkView at this point instead of the beginning of the method to handle
    // the case where the user disabled shrinkView while the keyboard is showing.
    // The webview should always be able to return to full size
    CGRect keyboardIntersection = CGRectIntersection(screen, keyboard);
    if (CGRectContainsRect(screen, keyboardIntersection) && !CGRectIsEmpty(keyboardIntersection) && _shrinkView && self.keyboardIsVisible) {
        screen.size.height -= keyboardIntersection.size.height;
        self.webView.scrollView.scrollEnabled = !self.disableScrollingInShrinkView;
    }

    CGFloat newScreenHeight = screen.size.height;
    // When keyboard will be hidden, willShow and show is triggered again
    // even though keyboard is already visible, ignoring as early as possible
    if(newScreenHeight == self.webView.frame.size.height)
    {
        return;
    }

    // A view's frame is in its superview's coordinate system so we need to convert again
    if(!shouldAnimate)
    {
        self.webView.frame = [self.webView.superview convertRect:screen fromView:self.webView];
        return;
    }

    NSDictionary* userInfo = [notif userInfo];
    NSNumber *durationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval duration = durationValue.doubleValue;

    BOOL isGrowing = newScreenHeight > currentScreenHeight;

    // If webView is growing, change it's frame imediately, so it's content is not clipped during animation
    if (isGrowing) {
        self.webView.frame = [self.webView.superview convertRect:screen fromView:self.webView];
    }
    // Tell JS that it can start animating with values
    NSString *javascriptString = [NSString stringWithFormat:@"Keyboard.beginAnimation(%f, %f, %f)", currentScreenHeight, newScreenHeight, duration*1000];
    [self.commandDelegate evalJs: javascriptString];

    _animationDetails = [[AnimationDetails alloc] init];
    _animationDetails.from = currentScreenHeight;
    _animationDetails.to = newScreenHeight;
    _animationDetails.screen = screen;

    // alternative to using animationComplete but the timer can finish before
    // the browser is finished animating, thereby clipping the animation

//    __weak typeof(self) weakSelf = self;
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        __strong typeof(weakSelf) self = weakSelf;
//        // If webview was shrinking, change it's frame after animation is complete
//        if (!isGrowing) {
//            self.webView.frame = [self.webView.superview convertRect:screen fromView:self.webView];
//        }
//    });
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView
{
    if (_shrinkView && _keyboardIsVisible) {
        CGFloat maxY = scrollView.contentSize.height - scrollView.bounds.size.height;
        if (scrollView.bounds.origin.y > maxY) {
            scrollView.bounds = CGRectMake(scrollView.bounds.origin.x, maxY,
                                           scrollView.bounds.size.width, scrollView.bounds.size.height);
        }
    }
}

#pragma mark Plugin interface

- (void)shrinkView:(CDVInvokedUrlCommand*)command
{
    if (command.arguments.count > 0) {
        id value = [command.arguments objectAtIndex:0];
        if (!([value isKindOfClass:[NSNumber class]])) {
            value = [NSNumber numberWithBool:NO];
        }

        self.shrinkView = [value boolValue];
    }

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:self.shrinkView]
                                callbackId:command.callbackId];
}

- (void)disableScrollingInShrinkView:(CDVInvokedUrlCommand*)command
{
    if (command.arguments.count > 0) {
        id value = [command.arguments objectAtIndex:0];
        if (!([value isKindOfClass:[NSNumber class]])) {
            value = [NSNumber numberWithBool:NO];
        }

        self.disableScrollingInShrinkView = [value boolValue];
    }

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:self.disableScrollingInShrinkView]
                                callbackId:command.callbackId];
}

- (void)hideFormAccessoryBar:(CDVInvokedUrlCommand*)command
{
    if (command.arguments.count > 0) {
        id value = [command.arguments objectAtIndex:0];
        if (!([value isKindOfClass:[NSNumber class]])) {
            value = [NSNumber numberWithBool:NO];
        }

        self.hideFormAccessoryBar = [value boolValue];
    }

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:self.hideFormAccessoryBar]
                                callbackId:command.callbackId];
}

- (void)hide:(CDVInvokedUrlCommand*)command
{
    [self.webView endEditing:YES];
}

// JS indicates that it finished handling Keyboard animation
- (void)animationComplete:(CDVInvokedUrlCommand*)command
{
    if(!_animationDetails)
    {
        return;
    }

    BOOL isGrowing = [_animationDetails from] < [_animationDetails to];
    // If webview was shrinking, change it's frame after animation is complete
    if (!isGrowing) {
        self.webView.frame = [self.webView.superview convertRect:[_animationDetails screen] fromView:self.webView];
    }
    _animationDetails = nil;
}

// JS indicates that it wants to handle Keyboard animation
- (void)enableAnimation:(CDVInvokedUrlCommand *)command
{
    _shouldAnimateWebView = YES;
}

// JS indicates that it finished handling Keyboard animation
- (void)disableAnimation:(CDVInvokedUrlCommand*)command
{
    _shouldAnimateWebView = NO;
}

#pragma mark dealloc

- (void)dealloc
{
    // since this is ARC, remove observers only
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

    [nc removeObserver:_keyboardShowObserver];
    [nc removeObserver:_keyboardHideObserver];
    [nc removeObserver:_keyboardWillShowObserver];
    [nc removeObserver:_keyboardWillHideObserver];
    [nc removeObserver:_shrinkViewKeyboardWillChangeFrameObserver];
}

@end
