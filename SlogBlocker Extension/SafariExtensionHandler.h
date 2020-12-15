//
//  SafariExtensionHandler.h
//  SlogBlocker Extension
//
//  Created by fubar on 2020-07-27.
//  Copyright © 2020 fubar. All rights reserved.
//

#import <SafariServices/SafariServices.h>

@interface SafariExtensionHandler : SFSafariExtensionHandler

+ (SafariExtensionHandler *) sharedHandler;

- (NSDictionary *)dictionaryWithBlockerSettings;
- (NSString *)stringWithBlockerSettings;

- (bool)updateBlockerSettingsWithString:(NSString *)string;

@end
