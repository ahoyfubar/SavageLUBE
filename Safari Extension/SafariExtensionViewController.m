//
//  SafariExtensionViewController.m
//  The Actual Extension
//
//  Created by fubar on 2020-12-14.
//  Copyright © 2020 fubar. All rights reserved.
//

#import "SafariExtensionViewController.h"
#import "SafariExtensionHandler.h"

static int webViewKVOContext = -1;

@interface SafariExtensionViewController () <WKNavigationDelegate, WKUIDelegate>

@end

@implementation SafariExtensionViewController

+ (SafariExtensionViewController *)sharedController {
	static SafariExtensionViewController *sharedController = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedController = [[SafariExtensionViewController alloc] init];
	});
	return sharedController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.preferredContentSize = NSMakeSize(380,380);
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    [self.webView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
    [self.webView setNavigationDelegate: self];
    [self.webView setUIDelegate: self];
    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:&webViewKVOContext];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"options" withExtension:@"html"];
    [self.webView loadFileURL:url allowingReadAccessToURL:url.URLByDeletingLastPathComponent];
    
    [self.view addSubview:self.webView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &webViewKVOContext) {
        if (!self.webView.loading) {
            [self applySettingsToWebView];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)viewWillAppear {
    [super viewWillAppear];
    //NSLog(@"viewWillAppear");
    if (!self.webView.loading) {
        [self applySettingsToWebView];
    }
}

- (void)viewDidDisappear {
    [super viewDidDisappear];
    //NSLog(@"viewDidDisappear");
    if (!self.webView.loading) {
        [self retrieveSettingsFromWebView];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    NSLog(@"%@", message);
    completionHandler();
}

- (void)applySettingsToWebView {
    NSString *settings = [[SafariExtensionHandler sharedHandler] stringWithBlockerSettings];
    if (settings) {
        NSString *script = [NSString stringWithFormat:@"applySettings('%@');", settings];
        [self.webView evaluateJavaScript:script completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (error) {
                NSLog(@"evaluateJavaScript %@", error);
            }
        }];
    }
}

- (void)retrieveSettingsFromWebView {
    NSString *settings = [[SafariExtensionHandler sharedHandler] stringWithBlockerSettings];
    if (settings) {
        NSString *script = [NSString stringWithFormat:@"retrieveSettings('%@');", settings];
        [self.webView evaluateJavaScript:script completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (result) {
                [[SafariExtensionHandler sharedHandler] updateBlockerSettingsWithString:result];
            }
            if (error) {
                NSLog(@"evaluateJavaScript %@", error);
            }
        }];
    }
}

@end
