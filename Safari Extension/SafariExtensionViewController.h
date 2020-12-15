//
//  SafariExtensionViewController.h
//  The Actual Extension
//
//  Created by fubar on 2020-12-14.
//  Copyright © 2020 fubar. All rights reserved.
//

#import <SafariServices/SafariServices.h>
#import <WebKit/WebKit.h>

@interface SafariExtensionViewController : SFSafariExtensionViewController

+ (SafariExtensionViewController *)sharedController;

@property WKWebView *webView;

@end
