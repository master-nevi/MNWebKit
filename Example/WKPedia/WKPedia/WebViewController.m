//
//  WebViewController.m
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

#import "WebViewController.h"
#import "TableOfContentsViewController.h"
#import "NSString+WKPediaExtras.h"
#import <MNWebKit/MNWebKit.h>

@interface WebViewController () <UISplitViewControllerDelegate, WebKitScriptMessageHandler, WebKitNavigationDelegate>

@property (nonatomic, readonly) UIView<WebKitWebViewStrategy> *webView;
@property (nonatomic, readonly) TableOfContentsViewController *tableOfContentsViewController;
@property (nonatomic, readwrite) IBOutlet UIBarButtonItem *contentsBarButtonItem;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@end

static void* WebViewControllerObservationContext = &WebViewControllerObservationContext;

@implementation WebViewController

- (id<WebKitWebViewStrategy>)webView {
    return (id<WebKitWebViewStrategy>)self.view;
}

- (TableOfContentsViewController *)tableOfContentsViewController {
    return  (TableOfContentsViewController *)[self.splitViewController.viewControllers.firstObject topViewController];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        self.navigationItem.leftBarButtonItem = nil;
    }
    else {
        self.navigationItem.leftBarButtonItem = self.contentsBarButtonItem;
    }
}

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"loading" context:WebViewControllerObservationContext];
    [self.webView removeObserver:self forKeyPath:@"title" context:WebViewControllerObservationContext];
}

- (IBAction)contentsButtonActivated:(id)sender {
    if (IS_IOS8_OR_ABOVE) {
        [[UIApplication sharedApplication] sendAction:self.splitViewController.displayModeButtonItem.action to:self.splitViewController.displayModeButtonItem.target from:sender forEvent:nil];
    }
}

- (void)loadView {
    id<WebKitWebViewConfigurationStrategy> configuration = [MNWebKitFactory webKitWebViewConfiguration];
    
    [self addUserScriptsToUserContentController:configuration.userContentController];
    
    UIView<WebKitWebViewStrategy> *webView = [MNWebKitFactory webKitWebViewWithFrame:CGRectZero configuration:configuration];
    
    webView.navigationDelegate = self;
    
    self.view = webView;
}

- (void)addUserScriptsToUserContentController:(id<WebKitUserContentControllerStrategy>)userContentController {
    NSString *hideTableOfContentsScriptString = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"hide" withExtension:@"js"] encoding:NSUTF8StringEncoding error:NULL];
    
    id<WebKitUserScriptStrategy> hideTableOfContentsScript = [MNWebKitFactory webKitUserScriptWithSource:hideTableOfContentsScriptString injectionTime:WebKitUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    
    [userContentController addUserScript:hideTableOfContentsScript];
    
    NSString *fetchTableOfContentsScriptString = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"fetch" withExtension:@"js"] encoding:NSUTF8StringEncoding error:NULL];
    
    id<WebKitUserScriptStrategy> fetchTableOfContentsScript = [MNWebKitFactory webKitUserScriptWithSource:fetchTableOfContentsScriptString injectionTime:WebKitUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [userContentController addUserScript:fetchTableOfContentsScript];
    
    [userContentController addScriptMessageHandler:self name:@"didFetchTableOfContents"];
}

#pragma mark - WKScriptMessageHandler methods

- (void)userContentController:(id<WebKitUserContentControllerStrategy>)userContentController didReceiveScriptMessage:(id<WebKitScriptMessageStrategy>)message {
    if ([message.name isEqual:@"didFetchTableOfContents"])
        [self.tableOfContentsViewController didFinishLoadingTableOfContents:message.body];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.webView addObserver:self forKeyPath:@"loading" options:(NSKeyValueObservingOptions)0 context:WebViewControllerObservationContext];
    [self.webView addObserver:self forKeyPath:@"title" options:(NSKeyValueObservingOptions)0 context:WebViewControllerObservationContext];
    
    self.webView.allowsMagnification = YES;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://en.wikipedia.org/w/index.php?title=San_Francisco&mobileaction=toggle_view_desktop"]];
    [self.webView loadRequest:request];
}

#pragma mark - WKNavigationDelegate methods

- (void)webView:(id<WebKitWebViewStrategy>)webView decidePolicyForNavigationAction:(id<WebKitNavigationActionStrategy>)navigationAction decisionHandler:(void (^)(WebKitNavigationActionPolicy))decisionHandler {
    // case 1 - deny request
//    NSLog(@"1.0");
//    decisionHandler(WebKitNavigationActionPolicyCancel); // terminates here
    
    // case 2 - deny response
//    NSLog(@"2.0");
//    decisionHandler(WebKitNavigationActionPolicyAllow);
    
    // case 3 - happy path
//    NSLog(@"3.0");
    decisionHandler(WebKitNavigationActionPolicyAllow);
    
    // case 4 - bad request (make the original request unreachable)
//    NSLog(@"4.0");
//    decisionHandler(WebKitNavigationActionPolicyAllow);
}

- (void)webView:(id<WebKitWebViewStrategy>)webView decidePolicyForNavigationResponse:(id<WebKitNavigationResponseStrategy>)navigationResponse decisionHandler:(void (^)(WebKitNavigationResponsePolicy))decisionHandler {
//    NSLog(@"2.2");
//    decisionHandler(WebKitNavigationResponsePolicyCancel);
    
//    NSLog(@"3.2");
    decisionHandler(WebKitNavigationResponsePolicyAllow);
}

- (void)webView:(id<WebKitWebViewStrategy>)webView didStartProvisionalNavigation:(id<WebKitNavigationStrategy>)navigation {
//    NSLog(@"2.1");
    
//    NSLog(@"3.1");
    
//    NSLog(@"4.1");
}

- (void)webView:(id<WebKitWebViewStrategy>)webView didFailProvisionalNavigation:(id<WebKitNavigationStrategy>)navigation withError:(NSError *)error {
//    NSLog(@"2.3");
    
//    NSLog(@"4.2");
}

- (void)webView:(id<WebKitWebViewStrategy>)webView didCommitNavigation:(id<WebKitNavigationStrategy>)navigation {
//    NSLog(@"3.3");
}

- (void)webView:(id<WebKitWebViewStrategy>)webView didFinishNavigation:(id<WebKitNavigationStrategy>)navigation {
//    NSLog(@"3.4");
}

#pragma mark - External API

- (void)loadRequest:(NSURLRequest *)request {
    [self.webView loadRequest:request];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"title"]) {
        self.title = [self.webView.title wkpedia_stringByDeletingWikipediaSnippet];
    }
}

#pragma mark - UISplitViewControllerDelegate methods

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController {
    if (!IS_IOS8_OR_ABOVE) {
        barButtonItem.title = NSLocalizedString(@"Contents", @"Contents");
        [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
        self.masterPopoverController = popoverController;
    }
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    if (!IS_IOS8_OR_ABOVE) {
        // Called when the view is shown again in the split view, invalidating the button and popover controller.
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        self.masterPopoverController = nil;
    }
}

@end
