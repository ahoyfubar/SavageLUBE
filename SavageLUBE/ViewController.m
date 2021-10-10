//
//  ViewController.m
//  SavageLUBE
//
//  Created by fubar on 2020-07-27.
//  Copyright © 2020 fubar. All rights reserved.
//

#import "ViewController.h"
#import <SafariServices/SFSafariApplication.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"Load SavageLUBE View");
    self.appNameLabel.stringValue = @"SavageLUBE";
}

- (IBAction)openSafariExtensionPreferences:(id)sender {
    NSLog(@"Open Safari Extension Preferences for SavageLUBE...");
    [SFSafariApplication showPreferencesForExtensionWithIdentifier:@"com.fubar.SavageLUBE-Extension" completionHandler:^(NSError * _Nullable error) {
        if (error) {
            // Insert code to inform the user something went wrong.
            NSLog(@"Failed to open Safari Extension Preferences: %@", error);
        }
    }];
}

@end
