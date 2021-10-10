//
//  ViewController.h
//  SavageLUBE
//
//  Created by fubar on 2020-07-27.
//  Copyright © 2020 fubar. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (weak, nonatomic) IBOutlet NSTextField * appNameLabel;

- (IBAction)openSafariExtensionPreferences:(id)sender;

@end

