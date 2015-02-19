NMWebKit
=========

NMWebKit is a reimplementation of the interface and feature set of iOS 8's WebKit framework.

#### Install:
Add following to Podfile (Currently not submitted to public PodSpec repo however if there's a demand I could):
```ruby
pod 'NMWebKit', '~> 0.0.1'
```

#### Usage:
```objective-c
#import <NMWebKit/NMWebKit.h>
```

Use the NMWebKitFactory to vend the API-user objects for WebKit. The concrete classes of the vended objects are hidden behind a set of protocols in order to implement the strategy pattern. The NMWebKitFactory class serves as the context in a typical strategy pattern implementation and, based on the version of iOS that is running, it will create NMWebKit objects (iOS 7 and below) or Apple WebKit Framework objects (iOS 8 and above).
