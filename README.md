# Keyboard

> The `Keyboard` object provides some functions to customize the keyboard.

This plugin has only been tested in Cordova 3.2 or greater, and its use in previous Cordova versions is not recommended (potential conflict with keyboard customization code present in the core in previous Cordova versions). 

If you do use this plugin in an older Cordova version (again, not recommended), you have to make sure the HideKeyboardFormAccessoryBar and KeyboardShrinksView preference values are *always* false, and only use the API functions to turn things on/off.

This plugin supports the __HideKeyboardFormAccessoryBar__ (boolean) and __KeyboardShrinksView__ (boolean) preferences in config.xml.

- [Methods](#methods)
 - [Keyboard.shrinkView](#keyboardshrinkview)
 - [Keyboard.hideFormAccessoryBar](#keyboardhideformaccessorybar)
 - [Keyboard.disableScrollingInShrinkView](#keyboarddisablescrollinginshrinkview)
 - [Keyboard.hide](#keyboardhide)
 - [Keyboard.show](#keyboardshow)
- [Properties](#properties)
 - [Keyboard.isVisible](#keyboardisvisible)
 - [Keyboard.automaticScrollToTopOnHiding](#keyboardautomaticscrolltotoponhiding)
- [Events](#events)
 - [keyboardDidShow](#keyboarddidshow)
 - [keyboardDidHide](#keyboarddidhide)
 - [keyboardWillShow](#keyboardwillshow)
 - [keyboardWillHide](#keyboardwillhide)
 - [keyboardHeightWillChange](#keyboardheightwillchange)

# Methods

## Keyboard.shrinkView

Shrink the WebView when the keyboard comes up.

    Keyboard.shrinkView(true);

#### Description

Set to true to shrink the WebView when the keyboard comes up. The WebView shrinks instead of the viewport shrinking and the page scrollable. This applies to apps that position their elements relative to the bottom of the WebView. This is the default behaviour on Android, and makes a lot of sense when building apps as opposed to webpages.


#### Supported Platforms

- iOS

#### Quick Example

    Keyboard.shrinkView(true);
    Keyboard.shrinkView(false);

## Keyboard.hideFormAccessoryBar

Hide the keyboard toolbar.

    Keyboard.hideFormAccessoryBar(true);

#### Description

Set to true to hide the additional toolbar that is on top of the keyboard. This toolbar features the Prev, Next, and Done buttons.


#### Supported Platforms

- iOS

#### Quick Example

    Keyboard.hideFormAccessoryBar(true);
    Keyboard.hideFormAccessoryBar(false);


## Keyboard.disableScrollingInShrinkView

Disable scrolling when the the WebView is shrunk.

    Keyboard.disableScrollingInShrinkView(true);

#### Description

Set to true to disable scrolling when the WebView is shrunk.


#### Supported Platforms

- iOS

#### Quick Example

    Keyboard.disableScrollingInShrinkView(true);
    Keyboard.disableScrollingInShrinkView(false);
 
## Keyboard.hide

Hide the keyboard

    Keyboard.hide();

#### Description

Call this method to hide the keyboard

#### Supported Platforms

- iOS
- Android

#### Quick Example

    Keyboard.hide();

## Keyboard.show

Show the keyboard

    Keyboard.show();

#### Description

Call this method to show the keyboard.


#### Supported Platforms

- Android

#### Quick Example

    Keyboard.show();

# Properties

## Keyboard.isVisible

Determine if the keyboard is visible.

    if (Keyboard.isVisible) {
        // do something
    }

#### Description

Read this property to determine if the keyboard is visible.


#### Supported Platforms

- iOS

## Keyboard.automaticScrollToTopOnHiding

Specifies whenether content of page would be automatically scrolled to the top of the page
when keyboard is hiding.

    Keyboard.automaticScrollToTopOnHiding = true;

#### Description

Set this to true if you need that page scroll to beginning when keyboard is hiding.
This is allows to fix issue with elements declared with position: fixed,
after keyboard is hiding.


#### Supported Platforms

- iOS

# Events

## keyboardDidShow

This event is fired when keyboard fully shown.

    window.addEventListener('keyboardDidShow', function () {
        // Describe your logic which will be run each time keyboard is shown.
    });

#### Description

Attach handler to this event to be able to receive notification when keyboard is shown.


#### Supported Platforms

- iOS

## keyboardDidHide

This event is fired when the keyboard is fully closed.

    window.addEventListener('keyboardDidHide', function () {
        // Describe your logic which will be run each time keyboard is closed.
    });

#### Description

Attach handler to this event to be able to receive notification when keyboard is closed.


#### Supported Platforms

- iOS

## keyboardWillShow

This event fires before keyboard will be shown.

    window.addEventListener('keyboardWillShow', function () {
        // Describe your logic which will be run each time when keyboard is about to be shown.
    });

#### Description

Attach handler to this event to be able to receive notification when keyboard is about to be shown on the screen.


#### Supported Platforms

- iOS

## keyboardWillHide

This event is fired when the keyboard is fully closed.

    window.addEventListener('keyboardWillHide', function () {
        // Describe your logic which will be run each time when keyboard is about to be closed.
    });

#### Description

Attach handler to this event to be able to receive notification when keyboard is about to be closed.


#### Supported Platforms

- iOS

## keyboardHeightWillChange

This event is fired when the keyboard is fully closed.

    window.addEventListener('keyboardHeightWillChange', function (event) {
        // Describe your logic which will be run each time when keyboard is about to be closed.
        console.log(event.keyboardHeight);
    });

#### Description

Attach handler to this event to be able to receive notification when keyboard is about to be closed.


#### Supported Platforms

- iOS

