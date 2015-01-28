//
//  MNWebView.m
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

#import "MNWebKitWebView.h"
#import "MNWebKitWebViewConfiguration.h"
#import "MNWebKitNavigation.h"
#import "MNWebKitUserContentController_Internal.h"
#import "MNWebKitScriptMessage.h"
#import "MNWebKitScriptMessage_Internal.h"
#import <GDataXML-HTML/GDataXMLNode.h>
#import "NSURLResponse+MNWKEncoding.h"
#import "GDataXMLDocument+MNWKExportToHTML.h"
#import "MNWebKitNavigationAction_Internal.h"
#import "MNWebKitNavigation_Internal.h"
#import "MNWebKitNavigationResponse_Internal.h"

#define WKLog(fmt, ...) NSLog((@"%s [Line %d] \n\n\t" fmt @"\n\n"), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

static NSString *const kMNWebKitWebViewCallbackScheme = @"mncallback";

@interface MNWebKitWebView () <UIWebViewDelegate>

@end

@implementation MNWebKitWebView {
    BOOL _isSafeToEvaluateJavaScript;
    MNWebKitWebViewConfiguration *_configuration;
    NSMutableArray *_scriptEvaluationOperations;
    MNWebKitNavigation *_navigation;
    NSOperationQueue *_backgroundQueue;
}

@synthesize title;
@synthesize scrollView;
@synthesize navigationDelegate = _navigationDelegate;

- (instancetype)initWithFrame:(CGRect)frame configuration:(MNWebKitWebViewConfiguration *)configuration {
    if (self = [super initWithFrame:frame]) {
        _configuration = configuration;
        self.delegate = self;
        _scriptEvaluationOperations = [NSMutableArray array];
        _backgroundQueue = [NSOperationQueue new];
    }
    return self;
}

- (void)setAllowsMagnification:(BOOL)allowsMagnification {
    self.scalesPageToFit = allowsMagnification;
}

- (BOOL)allowsMagnification {
    return self.scalesPageToFit;
}

- (MNWebKitNavigation *)loadRequest:(NSURLRequest *)request {
    _navigation = [MNWebKitNavigation new];
    _navigation.request = request;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([_navigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
            MNWebKitNavigationAction *navigationAction = [[MNWebKitNavigationAction alloc] initWithRequest:request];
            [_navigationDelegate webView:self decidePolicyForNavigationAction:navigationAction decisionHandler:^(WebKitNavigationActionPolicy navigationActionPolicy) {
                if (navigationActionPolicy == WebKitNavigationActionPolicyAllow) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self privateLoadRequest:request];
                    }];
                }
            }];
        }
        else {
            [self privateLoadRequest:request];
        }
    }];
    
    return _navigation;
}

- (MNWebKitWebViewConfiguration *)configuration {
    return _configuration;
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id dataObject, NSError *error))completionHandler {
    // wrap javascript around an eval() wrapped around JSON.stringify() so that the returned javascript object can be serialized into a cocoa foundation object
    NSMutableString *mjs = [[NSMutableString alloc] initWithString:@"JSON.stringify(eval(\""];
    NSString *doubleQuoteEscapedJavaScript = [javaScriptString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    [mjs appendString:doubleQuoteEscapedJavaScript];
    [mjs appendString:@"\"));"];
    
    NSString *jsRetString = [self stringByEvaluatingJavaScriptFromString:mjs];
    
    if (completionHandler) {
        if (jsRetString && ![jsRetString isEqualToString:@"null"]) {
            [[NSOperationQueue new] addOperationWithBlock:^{
                NSError *jsonParseError = nil;
                id foundationObject = [NSJSONSerialization JSONObjectWithData:[jsRetString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonParseError];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completionHandler(foundationObject, jsonParseError);
                }];
            }];
        } else {
            completionHandler(nil, nil);
        }
    }
}

#pragma mark - UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[[request URL] scheme] isEqualToString:kMNWebKitWebViewCallbackScheme] ) {
        NSString *encodedStr = [[request URL] resourceSpecifier];
        NSString *decodedStr = [self decodeURLFormat:encodedStr];
        
        if ([decodedStr rangeOfString:@"scriptMessageReady"].location != NSNotFound) {
            NSArray *components = [decodedStr componentsSeparatedByString:@":"];
            NSString *scriptMessageHandlerName = components[1];
            
            // get message handler object
            id<WebKitScriptMessageHandler> scriptMessageHandler = [_configuration.userContentController scriptMessageHandlerWithName:scriptMessageHandlerName];
            
            // create JavaScript string which will retreive message data when evaluated
            NSString *getMessageBodyForScriptMessageHandlerJavaScriptString = [self getMessageBodyForScriptMessageHandlerJavaScriptString:scriptMessageHandlerName];

            void (^evaluateJavaScriptAndParseReturnedObject)() = ^{
                // call message data callback and relay message to message handler
                [self evaluateJavaScript:getMessageBodyForScriptMessageHandlerJavaScriptString completionHandler:^(id dataObject, NSError *error) {
                    if (!error) {
                        id<WebKitScriptMessageStrategy> scriptMessage = [[MNWebKitScriptMessage alloc] initWithBody:dataObject webView:self name:scriptMessageHandlerName];
                        [scriptMessageHandler userContentController:_configuration.userContentController didReceiveScriptMessage:scriptMessage];
                    }
                    else {
                        [self reportError:error isDuringProvisionalNavigation:NO];
                    }
                }];
            };

            if (_isSafeToEvaluateJavaScript) {
                evaluateJavaScriptAndParseReturnedObject();
            }
            else {
                // store scripts to be evaluated at a safe time
                [_scriptEvaluationOperations addObject:[NSBlockOperation blockOperationWithBlock:evaluateJavaScriptAndParseReturnedObject]];
            }
        }
        else if ([decodedStr rangeOfString:@"nsLog"].location != NSNotFound) {
            WKLog(@"JavaScript Log: %@", decodedStr/*[decodedStr componentsSeparatedByString:@":"][1]*/);
        }
        
        return NO;
    }
    else if (navigationType != UIWebViewNavigationTypeOther) {
        // We want to inject the user scripts into pages traveled via hyperlinks as well so we'll use [self loadRequest:] to re-inject. Page loading via [self loadRequest:] will have a navigation type of UIWebViewNavigationTypeOther, so these should be let through or nothing will render :).
        
        // perform more sophisticated policy enabling from here
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self loadRequest:request];
        }];
        
        return NO;
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    // unexpected results occur when attempting to inject javascript here.
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (!_isSafeToEvaluateJavaScript) {
        _isSafeToEvaluateJavaScript = YES;
        
        // [UIWebViewDelegate webViewDidFinishLoad:] is the safest place to evaluate JavaScript using [UIWebView stringByEvaluatingJavaScriptFromString:]
        if ([_scriptEvaluationOperations count]) {
            NSArray *scriptEvaluationOperations = [NSArray arrayWithArray:_scriptEvaluationOperations];
            [_scriptEvaluationOperations removeAllObjects];
            [[NSOperationQueue mainQueue] addOperations:scriptEvaluationOperations waitUntilFinished:NO];
        }
    }
    
    if ([_navigationDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [_navigationDelegate webView:self didFinishNavigation:_navigation];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self reportError:error isDuringProvisionalNavigation:NO];
}

#pragma mark - Internal lib

#pragma mark - Loading and parsing

- (void)privateLoadRequest:(NSURLRequest *)request {
    if ([_navigationDelegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [_navigationDelegate webView:self didStartProvisionalNavigation:_navigation];
    }
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            [self reportError:connectionError isDuringProvisionalNavigation:YES];
            return;
        }
        
        if ([_navigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationResponse:decisionHandler:)]) {
            MNWebKitNavigationResponse *navigationResponse = [[MNWebKitNavigationResponse alloc] initWithResponse:response];
            [_navigationDelegate webView:self decidePolicyForNavigationResponse:navigationResponse decisionHandler:^(WebKitNavigationResponsePolicy navigationResponsePolicy) {
                if (navigationResponsePolicy == WebKitNavigationResponsePolicyAllow) {
                    [_backgroundQueue addOperationWithBlock:^{
                        [self parseResponse:response data:data fromRequest:request];
                    }];
                }
                else {
                    [self reportErrorWithDescription:@"Frame load interrupted" code:102 isDuringProvisionalNavigation:YES];
                }
            }];
        }
        else {
            [_backgroundQueue addOperationWithBlock:^{
                [self parseResponse:response data:data fromRequest:request];
            }];
        }
    }];
}

- (void)parseResponse:(NSURLResponse *)response data:(NSData *)data fromRequest:(NSURLRequest *)request {
    _navigation.response = response;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([_navigationDelegate respondsToSelector:@selector(webView:didCommitNavigation:)]) {
            [_navigationDelegate webView:self didCommitNavigation:_navigation];
        }
    }];
    
    // parse web page
    NSError *parseError;
    GDataXMLDocument *htmlDoc;
    
    if ([response.MIMEType rangeOfString:@"image/"].location != NSNotFound) {
        NSString *htmlString = [NSString stringWithFormat:@"<html><head></head><body style=\"margin: 0px;\"><img src=\"%@\" width=\"100%%\" height=\"100%%\"></body></html>", [[request URL] absoluteString]];
        htmlDoc = [[GDataXMLDocument alloc] initWithHTMLString:htmlString encoding:NSUTF8StringEncoding error:&parseError];
    }
    else if ([response.MIMEType rangeOfString:@"text/html"].location != NSNotFound) {
        htmlDoc = [[GDataXMLDocument alloc] initWithHTMLData:data encoding:[response MNWK_encoding] error:&parseError];
    }
    else {
        [self reportErrorWithDescription:@"Unrecognized MIME type" code:102 isDuringProvisionalNavigation:NO];
        return;
    }
    
    if (parseError) {
        [self reportError:parseError isDuringProvisionalNavigation:NO];
        return;
    }
    
    // create JavaScript string which embodies all web kit related library and user scripts
    NSMutableString *javaScriptStringForHeadElement = [NSMutableString string];
    
    // add core JavaScript library
    [javaScriptStringForHeadElement appendString:[self coreLibraryJavaScriptString]];
    [javaScriptStringForHeadElement appendString:@"\n\n"];
    
    // create script message handlers
    [javaScriptStringForHeadElement appendString:[self createScriptMessageHandlersJavaScriptString]];
    [javaScriptStringForHeadElement appendString:@"\n\n"];
    
    // add document start user scripts
    [javaScriptStringForHeadElement appendString:[self userScriptsJavaScriptStringForInjectionTime:WebKitUserScriptInjectionTimeAtDocumentStart]];
    [javaScriptStringForHeadElement appendString:@"\n\n"];
    
    // add document end user scripts which will be evaluated upon DOMContentLoaded event fire
    [javaScriptStringForHeadElement appendString:@"window.addEventListener('DOMContentLoaded', function() {"];
    [javaScriptStringForHeadElement appendString:@"\n"];
    [javaScriptStringForHeadElement appendString:[self userScriptsJavaScriptStringForInjectionTime:WebKitUserScriptInjectionTimeAtDocumentEnd]];
    [javaScriptStringForHeadElement appendString:@"}, false);"];
    
    // find head element
    NSError *headFindError;
    GDataXMLElement *head = (GDataXMLElement *)[htmlDoc firstNodeForXPath:@"/*/head" error:&headFindError];
    if (headFindError) {
        [self reportError:headFindError isDuringProvisionalNavigation:NO];
        return;
    }
    
    if (!head) {
        [self reportErrorWithDescription:@"Headless HTML" code:102 isDuringProvisionalNavigation:NO];
        return;
    }
    
    // add JavaScript string to a script html element and add the element to the html head element
    GDataXMLElement *scriptElement = [GDataXMLNode elementWithName:@"script"];
    [scriptElement addAttribute:[GDataXMLNode attributeWithName:@"type" stringValue:@"text/javascript"]];
    [scriptElement addChild:[GDataXMLNode textWithStringValue:[NSString stringWithString:javaScriptStringForHeadElement]]];
    [head addChild:scriptElement];
    
    // export the html object tree back into a string
    NSString *modifiedHTMLString = [htmlDoc MNWK_exportHTML];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _isSafeToEvaluateJavaScript = NO;
        [super loadHTMLString:modifiedHTMLString baseURL:[request URL]];
    }];
}

- (void)reportErrorWithDescription:(NSString *)description code:(NSInteger)code isDuringProvisionalNavigation:(BOOL)isDuringProvisionalNavigation {
    NSError *error = [NSError errorWithDomain:@"MNWebKitDomain" code:code userInfo:@{NSLocalizedDescriptionKey: description}];
    [self reportError:error isDuringProvisionalNavigation:isDuringProvisionalNavigation];
}

- (void)reportError:(NSError *)error isDuringProvisionalNavigation:(BOOL)isDuringProvisionalNavigation {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (isDuringProvisionalNavigation) {
            NSURLRequest *request = _navigation.request;
            NSMutableDictionary *modifiedUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
            if ([request URL]) {
                [modifiedUserInfo addEntriesFromDictionary:@{@"NSErrorFailingURLKey": [request URL],
                                                             @"NSErrorFailingURLStringKey": [[request URL] absoluteString]}];
            }
            NSError *modifiedError = [NSError errorWithDomain:@"MNWebKitDomain" code:error.code userInfo:[NSDictionary dictionaryWithDictionary:modifiedUserInfo]];
            
            _navigation.error = modifiedError;
            
            if ([_navigationDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
                [_navigationDelegate webView:self didFailProvisionalNavigation:_navigation withError:modifiedError];
            }
        }
        else {
            NSURLRequest *request = _navigation.request;
            NSURLResponse *response = _navigation.response;
            NSMutableDictionary *modifiedUserInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
            if ([request URL]) {
                [modifiedUserInfo addEntriesFromDictionary:@{@"NSErrorFailingURLKey": [request URL],
                                                             @"NSErrorFailingURLStringKey": [[request URL] absoluteString]}];
            }
            if (response) {
                [modifiedUserInfo addEntriesFromDictionary:@{@"NSErrorFailingResponseKey": response}];
            }
            
            NSError *modifiedError = [NSError errorWithDomain:@"MNWebKitDomain" code:error.code userInfo:[NSDictionary dictionaryWithDictionary:modifiedUserInfo]];
            
            _navigation.error = modifiedError;

            
            if ([_navigationDelegate respondsToSelector:@selector(webView:didFailNavigation:withError:)]) {
                [_navigationDelegate webView:self didFailNavigation:_navigation withError:modifiedError];
            }
        }
    }];
}

#pragma mark - JavaScript injections

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script {
    if (_isSafeToEvaluateJavaScript) {
        return [super stringByEvaluatingJavaScriptFromString:script];
    }
    else {
        NSAssert(NO, @"It's not safe to evaluate JavaScript, wait until the web view has finished loading.");
    }
    
    return nil;
}

#pragma mark - JavaScript string create

- (NSString *)coreLibraryJavaScriptString {
    return [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"MNWebKitCore" withExtension:@"js"] encoding:NSUTF8StringEncoding error:NULL];
}

- (NSString *)createScriptMessageHandlersJavaScriptString {
    NSMutableString *retString = [NSMutableString string];
    
    for (NSString *scriptMessageHandlerName in [_configuration.userContentController scriptMessageHandlerNames]) {
        NSString *createScriptMessageHandlerScript = [self createScriptMessageHandlerJavaScriptString:scriptMessageHandlerName];
        [retString appendString:createScriptMessageHandlerScript];
        [retString appendString:@"\n\n"];
    }
    
    return [NSString stringWithString:retString];
}

- (NSString *)userScriptsJavaScriptStringForInjectionTime:(WebKitUserScriptInjectionTime)injectionTime {
    NSMutableString *retString = [NSMutableString string];
    
    NSArray *userScripts = [_configuration.userContentController userScriptsForInjectionTime:injectionTime];
    for (id<WebKitUserScriptStrategy> userScript in userScripts) {
        [retString appendString:userScript.source];
        [retString appendString:@"\n\n"];
    }
    
    return [NSString stringWithString:retString];
}

- (NSString *)createScriptMessageHandlerJavaScriptString:(NSString *)scriptMessageHandlerName {
    return [NSString stringWithFormat:@"createScriptMessageHandler('%@');", scriptMessageHandlerName];
}

- (NSString *)getMessageBodyForScriptMessageHandlerJavaScriptString:(NSString *)scriptMessageHandlerName {
    return [NSString stringWithFormat:@"getMessageBodyForScriptMessageHandler('%@');", scriptMessageHandlerName];
}

#pragma mark - Helpers

- (NSString *)decodeURLFormat:(NSString *)string {
    NSString *result = [string stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

@end
