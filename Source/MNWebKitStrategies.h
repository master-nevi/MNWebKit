//
//  MNWebKitStrategies.h
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

/**
 A set of protocols used to mask the concrete classes used in WebKit as defined by the strategy pattern. They are modeled after iOS 8's WebKit Framework.
 */

typedef NS_ENUM(NSInteger, WebKitUserScriptInjectionTime) {
    WebKitUserScriptInjectionTimeAtDocumentStart,
    WebKitUserScriptInjectionTimeAtDocumentEnd
};

typedef NS_ENUM(NSInteger, WebKitNavigationActionPolicy) {
    WebKitNavigationActionPolicyCancel,
    WebKitNavigationActionPolicyAllow
};

typedef NS_ENUM(NSInteger, WebKitNavigationResponsePolicy) {
    WebKitNavigationResponsePolicyCancel,
    WebKitNavigationResponsePolicyAllow
};

@protocol WebKitWebViewConfigurationStrategy;
@protocol WebKitNavigationStrategy;
@protocol WebKitUserContentControllerStrategy;
@protocol WebKitUserScriptStrategy;
@protocol WebKitScriptMessageHandler;
@protocol WebKitNavigationDelegate;


@protocol WebKitWebViewStrategy <NSObject>
@property (nonatomic, weak) id <WebKitNavigationDelegate> navigationDelegate;
@property (nonatomic, readonly) id<WebKitWebViewConfigurationStrategy> configuration;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic) BOOL allowsMagnification;
//@property (nonatomic, readonly) BOOL loading; // not necessary, just available to forward
//@property (nonatomic, readonly) BOOL canGoBack; // not necessary, just available to forward
//@property (nonatomic, readonly) BOOL canGoForward; // not necessary, just available to forward
@property (nonatomic, readonly) UIScrollView *scrollView;
- (instancetype)initWithFrame:(CGRect)frame configuration:(id<WebKitWebViewConfigurationStrategy>)configuration;
- (id<WebKitNavigationStrategy>)loadRequest:(NSURLRequest *)request;
//- (id<MNWKNavigationStrategy>)goBack; // not necessary, just available to forward
//- (id<MNWKNavigationStrategy>)goForward; // not necessary, just available to forward
//- (id<MNWKNavigationStrategy>)reload; // not necessary, just available to forward
//- (void)stopLoading; // not necessary, just available to forward
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id dataObject, NSError *error))completionHandler;
@end


@protocol WebKitWebViewConfigurationStrategy <NSObject>
@property (nonatomic, strong) id<WebKitUserContentControllerStrategy> userContentController;
@end


@protocol WebKitNavigationStrategy <NSObject>
@property (nonatomic, readonly, copy) NSURLRequest *request;
@property (nonatomic, readonly, copy) NSURLResponse *response;
@property (nonatomic, readonly, copy) NSError *error;
@end


@protocol WebKitNavigationActionStrategy <NSObject>
@property (nonatomic, readonly, copy) NSURLRequest *request;
@end


@protocol WebKitNavigationResponseStrategy <NSObject>
@property (nonatomic, readonly, copy) NSURLResponse *response;
@end


@protocol WebKitUserContentControllerStrategy <NSObject>
@property (nonatomic, readonly) NSArray *userScripts;
- (void)addUserScript:(id<WebKitUserScriptStrategy>)userScript;
//- (void)removeAllUserScripts; // not necessary
- (void)addScriptMessageHandler:(id<WebKitScriptMessageHandler>)scriptMessageHandler name:(NSString *)name;
//- (void)removeScriptMessageHandlerForName:(NSString *)name; // not necessary
@end


@protocol WebKitUserScriptStrategy <NSObject>
@property (nonatomic, readonly) NSString *source;
@property (nonatomic, readonly) WebKitUserScriptInjectionTime injectionTime;
- (instancetype)initWithSource:(NSString *)source injectionTime:(NSInteger)injectionTime forMainFrameOnly:(BOOL)forMainFrameOnly;
@end


@protocol WebKitScriptMessageStrategy <NSObject>
@property (nonatomic, readonly) id body;
@property (nonatomic, readonly, weak) id<WebKitWebViewStrategy> webView;
@property (nonatomic, readonly) NSString *name;
@end


// Remove and replace with WKScriptMessageHandler when building against iOS8 SDK
@protocol WebKitScriptMessageHandler <NSObject>
@required
- (void)userContentController:(id<WebKitUserContentControllerStrategy>)userContentController didReceiveScriptMessage:(id<WebKitScriptMessageStrategy>)message;
@end


@protocol WebKitNavigationDelegate <NSObject>
@optional
- (void)webView:(id<WebKitWebViewStrategy>)webView decidePolicyForNavigationAction:(id<WebKitNavigationActionStrategy>)navigationAction decisionHandler:(void (^)(WebKitNavigationActionPolicy))decisionHandler;
- (void)webView:(id<WebKitWebViewStrategy>)webView decidePolicyForNavigationResponse:(id<WebKitNavigationResponseStrategy>)navigationResponse decisionHandler:(void (^)(WebKitNavigationResponsePolicy))decisionHandler;
- (void)webView:(id<WebKitWebViewStrategy>)webView didStartProvisionalNavigation:(id<WebKitNavigationStrategy>)navigation;
- (void)webView:(id<WebKitWebViewStrategy>)webView didFailProvisionalNavigation:(id<WebKitNavigationStrategy>)navigation withError:(NSError *)error;
- (void)webView:(id<WebKitWebViewStrategy>)webView didCommitNavigation:(id<WebKitNavigationStrategy>)navigation;
- (void)webView:(id<WebKitWebViewStrategy>)webView didFinishNavigation:(id<WebKitNavigationStrategy>)navigation;
- (void)webView:(id<WebKitWebViewStrategy>)webView didFailNavigation:(id<WebKitNavigationStrategy>)navigation withError:(NSError *)error;
@end
















