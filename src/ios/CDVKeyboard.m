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

#ifndef __CORDOVA_3_2_0
#warning "The keyboard plugin is only supported in Cordova 3.2 or greater, it may not work properly in an older version. If you do use this plugin in an older version, make sure the HideKeyboardFormAccessoryBar and KeyboardShrinksView preference values are false."
#endif

@interface CDVKeyboard () <UIScrollViewDelegate>

@property (nonatomic, readwrite, assign) BOOL keyboardIsVisible;

@end

@implementation CDVKeyboard

- (id)settingForKey:(NSString*)key
{
    return [self.commandDelegate.settings objectForKey:[key lowercaseString]];
}

#pragma mark Initialize

- (void)pluginInitialize
{
    NSString* setting = nil;

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
    
    _accessoryBarHeight = 44;
}

#pragma mark HideFormAccessoryBar

- (BOOL)hideFormAccessoryBar
{
    return _hideFormAccessoryBar;
}

- (void)setHideFormAccessoryBar:(BOOL)ahideFormAccessoryBar
{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    __weak CDVKeyboard* weakSelf = self;

    if (ahideFormAccessoryBar == _hideFormAccessoryBar) {
        return;
    }

    if (ahideFormAccessoryBar) {
        [nc removeObserver:_hideFormAccessoryBarKeyboardShowObserver];
        _hideFormAccessoryBarKeyboardShowObserver = [nc addObserverForName:UIKeyboardWillShowNotification
                                                                    object:nil
                                                                     queue:[NSOperationQueue mainQueue]
                                                                usingBlock:^(NSNotification* notification) {
                // we can't hide it here because the accessory bar hasn't been created yet, so we delay on the queue
                [weakSelf performSelector:@selector(formAccessoryBarKeyboardWillShow:) withObject:notification afterDelay:0];
            }];

        [nc removeObserver:_hideFormAccessoryBarKeyboardHideObserver];
        _hideFormAccessoryBarKeyboardHideObserver = [nc addObserverForName:UIKeyboardWillHideNotification
                                                                    object:nil
                                                                     queue:[NSOperationQueue mainQueue]
                                                                usingBlock:^(NSNotification* notification) {
                [weakSelf formAccessoryBarKeyboardWillHide:notification];
            }];
    } else {
        [nc removeObserver:_hideFormAccessoryBarKeyboardShowObserver];
        [nc removeObserver:_hideFormAccessoryBarKeyboardHideObserver];

        // if a keyboard is already visible (and the accessorybar was hidden), hide observer will NOT be called, so we observe it once
        if (self.keyboardIsVisible && _hideFormAccessoryBar) {
            _hideFormAccessoryBarKeyboardHideObserver = [nc addObserverForName:UIKeyboardWillHideNotification
                                                                        object:nil
                                                                         queue:[NSOperationQueue mainQueue]
                                                                    usingBlock:^(NSNotification* notification) {
                    [weakSelf formAccessoryBarKeyboardWillHide:notification];
                    [[NSNotificationCenter defaultCenter] removeObserver:_hideFormAccessoryBarKeyboardHideObserver];
                }];
        }
    }

    _hideFormAccessoryBar = ahideFormAccessoryBar;
}

- (NSArray*)getKeyboardViews:(UIView*)viewToSearch{
    NSArray *subViews;
    
    for (UIView *possibleFormView in viewToSearch.subviews) {
        if ([[possibleFormView description] hasPrefix: self.getKeyboardFirstLevelIdentifier]) {
            if(IsAtLeastiOSVersion(@"8.0")){
                for (UIView* subView in possibleFormView.subviews) {
                    return subView.subviews;
                }
            }else{
                return possibleFormView.subviews;
            }
        }
        
    }
    return subViews;
}

- (NSString*)getKeyboardFirstLevelIdentifier{
    if(!IsAtLeastiOSVersion(@"8.0")){
        return @"<UIPeripheralHostView";
    }else{
        return @"<UIInputSetContainerView";
    }
}

- (void)formAccessoryBarKeyboardWillShow:(NSNotification*)notif
{
    if (!_hideFormAccessoryBar) {
        return;
    }

    UIWindow *keyboardWindow = nil;
    for (UIWindow *windows in [[UIApplication sharedApplication] windows]) {
        if (![[windows class] isEqual:[UIWindow class]]) {
            keyboardWindow = windows;
            break;
        }
    }
    
    for (UIView* peripheralView in [self getKeyboardViews:keyboardWindow]) {
        
        // hides the backdrop (iOS 7)
        if ([[peripheralView description] hasPrefix:@"<UIKBInputBackdropView"]) {
            // check that this backdrop is for the accessory bar (at the top),
            // sparing the backdrop behind the main keyboard
            CGRect rect = peripheralView.frame;
            if (rect.origin.y == 0) {
                [[peripheralView layer] setOpacity:0.0];
            }
        }
        
        // hides the accessory bar
        if ([[peripheralView description] hasPrefix:@"<UIWebFormAccessory"]) {
            //remove the extra scroll space for the form accessory bar
            CGRect newFrame = self.webView.scrollView.frame;
            newFrame.size.height += peripheralView.frame.size.height;
            self.webView.scrollView.frame = newFrame;
            
            _accessoryBarHeight = peripheralView.frame.size.height;
            
            // remove the form accessory bar
            if(IsAtLeastiOSVersion(@"8.0")){
                [[peripheralView layer] setOpacity:0.0];
            }else{
                [peripheralView removeFromSuperview];
            }
            
        }
        // hides the thin grey line used to adorn the bar (iOS 6)
        if ([[peripheralView description] hasPrefix:@"<UIImageView"]) {
            [[peripheralView layer] setOpacity:0.0];
        }
    }
}

- (void)formAccessoryBarKeyboardWillHide:(NSNotification*)notif
{
    // restore the scrollview frame
    self.webView.scrollView.frame = CGRectMake(0, 0, self.webView.frame.size.width, self.webView.frame.size.height);
}

#pragma mark KeyboardShrinksView

- (void)shrinkViewKeyboardWillChangeFrame:(NSNotification*)notif
{
    // No-op on iOS 7.0.  It already resizes webview by default, and this plugin is causing layout issues
    // with fixed position elements.  We possibly should attempt to implement shrinkview = false on iOS7.0.
    // iOS 7.1+ behave the same way as iOS 6
    if (NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_7_1 && NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1){
        return;
    }
    
    // If the view is not visible, we should do nothing. E.g. if the inappbrowser is open.
    if (!(self.viewController.isViewLoaded && self.viewController.view.window)){
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
    if(![[self settingForKey:@"StatusBarOverlaysWebView"] boolValue]){
        CGRect full, remainder;
        CGRectDivide(screen, &remainder, &full, statusBar.size.height, CGRectMinYEdge);
        screen = full;
    }
    
    // Get the intersection of the keyboard and screen and move the webview above it
    // Note: we check for _shrinkView at this point instead of the beginning of the method to handle
    // the case where the user disabled shrinkView while the keyboard is showing.
    // The webview should always be able to return to full size
    CGRect keyboardIntersection = CGRectIntersection(screen, keyboard);
    if(CGRectContainsRect(screen, keyboardIntersection) && !CGRectIsEmpty(keyboardIntersection) && _shrinkView && self.keyboardIsVisible){
        
        screen.size.height -= keyboardIntersection.size.height;
        
        if (_hideFormAccessoryBar){
            screen.size.height += _accessoryBarHeight;
        }
        
        self.webView.scrollView.scrollEnabled = !self.disableScrollingInShrinkView;
    }
    
    // A view's frame is in its superview's coordinate system so we need to convert again
    self.webView.frame = [self.webView.superview convertRect:screen fromView:self.webView];
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(_shrinkView){
        scrollView.bounds = self.webView.bounds;
    }
}

#pragma mark Plugin interface

- (void)shrinkView:(CDVInvokedUrlCommand*)command
{
    id value = [command.arguments objectAtIndex:0];
    if (!([value isKindOfClass:[NSNumber class]])) {
        value = [NSNumber numberWithBool:NO];
    }
    
    self.shrinkView = [value boolValue];
}

- (void)disableScrollingInShrinkView:(CDVInvokedUrlCommand*)command
{
    id value = [command.arguments objectAtIndex:0];
    if (!([value isKindOfClass:[NSNumber class]])) {
        value = [NSNumber numberWithBool:NO];
    }
    
    self.disableScrollingInShrinkView = [value boolValue];
}

- (void)hideFormAccessoryBar:(CDVInvokedUrlCommand*)command
{
    id value = [command.arguments objectAtIndex:0];
    if (!([value isKindOfClass:[NSNumber class]])) {
        value = [NSNumber numberWithBool:NO];
    }
    
    self.hideFormAccessoryBar = [value boolValue];
}

- (void)hide:(CDVInvokedUrlCommand*)command
{
    [self.webView endEditing:YES];
}

#pragma mark dealloc

- (void)dealloc
{
    // since this is ARC, remove observers only
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    
    [nc removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [nc removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [nc removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

@end
