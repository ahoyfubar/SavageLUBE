//
//  ViewController.m
//  SlogBlocker
//
//  Created by fubar on 2020-07-27.
//  Copyright © 2020 fubar. All rights reserved.
//

#import "ViewController.h"
#import <SafariServices/SFSafariApplication.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"Load SlogBlocker View");
    self.appNameLabel.stringValue = @"SlogBlocker";
}

- (IBAction)openSafariExtensionPreferences:(id)sender {
    NSLog(@"Open Safari Extension Preferences for SlogBlocker...");
    [SFSafariApplication showPreferencesForExtensionWithIdentifier:@"com.fubar.SlogBlocker-Extension" completionHandler:^(NSError * _Nullable error) {
        if (error) {
            // Insert code to inform the user something went wrong.
            NSLog(@"Failed to open Safari Extension Preferences: %@", error);
        }
    }];
}

@end
