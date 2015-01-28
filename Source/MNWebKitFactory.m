//
//  WebKitFactory.m
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

#import "MNWebKitFactory.h"
#import "MNWebKitWebView.h"
#import "MNWebKitWebViewConfiguration.h"
#import "MNWebKitNavigation.h"
#import "MNWebKitUserContentController.h"
#import "MNWebKitUserScript.h"
#import "MNWebKitScriptMessage.h"
//#import <WebKit/WebKit.h> // UNCOMMENT WHEN WEBKIT WORKS

typedef NS_ENUM(NSInteger, MNWebKitFactoryClassSet) {
    MNWebKitFactoryClassSetClassic,
    MNWebKitFactoryClassSetModern
};

@implementation MNWebKitFactory {
    Class _webViewClass;
    Class _webViewConfigurationClass;
    Class _navigationClass;
    Class _userContentControllerClass;
    Class _userScriptClass;
    Class _scriptMessageClass;
}

- (instancetype)initWithClassSet:(MNWebKitFactoryClassSet)classSet {
    if (self = [super init]) {
        if (classSet == MNWebKitFactoryClassSetClassic) {
            _webViewClass = [MNWebKitWebView class];
            _webViewConfigurationClass = [MNWebKitWebViewConfiguration class];
            _navigationClass = [MNWebKitNavigation class];
            _userContentControllerClass = [MNWebKitUserContentController class];
            _userScriptClass = [MNWebKitUserScript class];
            _scriptMessageClass = [MNWebKitScriptMessage class];
        }
        else {
            // UNCOMMENT WHEN WEBKIT WORKS
            /*_webViewClass = [WKWebView class];
            _webViewConfigurationClass = [WKWebViewConfiguration class];
            _navigationClass = [WKNavigation class];
            _userContentControllerClass = [WKUserContentController class];
            _userScriptClass = [WKUserScript class];
            _scriptMessageClass = [WKScriptMessage class];*/
            
            _webViewClass = [MNWebKitWebView class];
            _webViewConfigurationClass = [MNWebKitWebViewConfiguration class];
            _navigationClass = [MNWebKitNavigation class];
            _userContentControllerClass = [MNWebKitUserContentController class];
            _userScriptClass = [MNWebKitUserScript class];
            _scriptMessageClass = [MNWebKitScriptMessage class];
        }
    }
    
    return self;
}

+ (MNWebKitFactory *)sharedInstance {
    static MNWebKitFactory *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL isIOS8OrAbove = ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0);
        sharedInstance = [[self alloc] initWithClassSet:(isIOS8OrAbove ? MNWebKitFactoryClassSetModern : MNWebKitFactoryClassSetClassic)];
    });
    
    return sharedInstance;
}

+ (UIView<WebKitWebViewStrategy> *)webKitWebViewWithFrame:(CGRect)frame configuration:(id<WebKitWebViewConfigurationStrategy>)configuration {
    return [[[MNWebKitFactory sharedInstance]->_webViewClass alloc] initWithFrame:frame configuration:configuration];
}

+ (id<WebKitWebViewConfigurationStrategy>)webKitWebViewConfiguration {
    return [[MNWebKitFactory sharedInstance]->_webViewConfigurationClass new];
}

+ (id<WebKitUserScriptStrategy>)webKitUserScriptWithSource:(NSString *)source injectionTime:(NSInteger)injectionTime forMainFrameOnly:(BOOL)forMainFrameOnly {
    return [[[MNWebKitFactory sharedInstance]->_userScriptClass alloc] initWithSource:source injectionTime:injectionTime forMainFrameOnly:forMainFrameOnly];
}

@end
