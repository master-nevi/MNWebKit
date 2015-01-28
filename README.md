NFFWebKit
=========

NFFWebKit is a reimplementation of the interface and feature set of iOS 8's WebKit framework.

#### Install:
Add following to Podfile:
```ruby
pod 'NFFWebKit', '~> 0.0.1'
```

#### Usage:
```objective-c
#import <NFFWebKit/NFFWebKit.h>
```

Use the NFFWebKitFactory to vend the API-user objects for WebKit. The concrete classes of the vended objects are hidden behind a set of protocols in order to implement the strategy pattern. The NFFWebKitFactory class serves as the context in a typical strategy pattern implementation and, based on the version of iOS that is running, it will create NFFWebKit objects (iOS 7 and below) or Apple WebKit Framework objects (iOS 8 and above).
