//
//  WebKitFactory.h
//
//  Copyright (c) 2015 David Robles
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol WebKitUserScriptStrategy;
@protocol WebKitWebViewConfigurationStrategy;
@protocol WebKitWebViewStrategy;

/**
 This factory is used to vend the API-user creatable objects for WebKit. The concrete classes of the vended objects are hidden behind a set of protocols in order to implement the strategy pattern. This class serves as the context in a typical strategy pattern implementation and, based on the version of iOS that is running, it will create MNWebKit objects (iOS 7 and below) or Apple WebKit Framework objects (iOS 8 and above).
 */
@interface MNWebKitFactory : NSObject

+ (UIView<WebKitWebViewStrategy> *)webKitWebViewWithFrame:(CGRect)frame configuration:(id<WebKitWebViewConfigurationStrategy>)configuration;

+ (id<WebKitWebViewConfigurationStrategy>)webKitWebViewConfiguration;

+ (id<WebKitUserScriptStrategy>)webKitUserScriptWithSource:(NSString *)source injectionTime:(NSInteger)injectionTime forMainFrameOnly:(BOOL)forMainFrameOnly;

@end
