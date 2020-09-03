//
//  SafariExtensionHandler.m
//  SlogBlocker Extension
//
//  Created by fubar on 2020-07-27.
//  Copyright © 2020 fubar. All rights reserved.
//

#import "SafariExtensionHandler.h"
#import <Foundation/NSUserDefaults.h>

@interface SafariExtensionHandler ()

- (void)initBlockerSettings;
- (NSDictionary *)dictionaryWithBlockerSettings;

@end

@implementation SafariExtensionHandler

- (instancetype)init {
    if (self = [super init]) {
        [self initBlockerSettings];
    }
    return self;
}

- (void)initBlockerSettings {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSArray *users = [prefs arrayForKey:@"users"];
    if (users == nil) {
        [prefs setValue:[[NSArray alloc] init] forKey:@"users"];
        [prefs setBool:false forKey:@"addAvatarTooltips"];
        [prefs setBool:true forKey:@"moveUserBylines"];
        [prefs setBool:true forKey:@"addTopPagination"];
        [prefs synchronize];
    }
    [prefs setBool:true forKey:@"addCommentLinks"];
    [prefs synchronize];
}

- (NSDictionary *)dictionaryWithBlockerSettings {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return @{@"users":[prefs arrayForKey:@"users"], @"addAvatarTooltips":[NSNumber numberWithBool:[prefs boolForKey:@"addAvatarTooltips"]],  @"moveUserBylines":[NSNumber numberWithBool:[prefs boolForKey:@"moveUserBylines"]], @"addTopPagination":[NSNumber numberWithBool:[prefs boolForKey:@"addTopPagination"]]
    };
}

- (bool)updateBlockerSettingsWithUserInfo:(NSDictionary *)userInfo {
    NSString *name = [userInfo valueForKey:@"name"];
    NSString *action = [userInfo valueForKey:@"action"];
    NSLog(@"Updating user (%@) with action (%@)", name, action);

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    BOOL prefsUpdated = false;
    
    NSMutableArray *users = [[prefs arrayForKey:@"users"] mutableCopy];
    for (NSDictionary *user in users) {
        NSDictionary *update = [user mutableCopy];
        if ([name caseInsensitiveCompare:[user valueForKey:@"name"]] == NSOrderedSame ) {
            if ([action isEqualToString:@"unmute"]) {
                NSLog(@"(%@) unmuted", name);
                [update setValue:@"none" forKey:@"action"];
                prefsUpdated = true;
            }
            else if([action isEqualToString:@"avatar"]) {
                NSString *avatar = [userInfo valueForKey:@"avatar"];
                //NSLog(@"(%@) new avatar (%@)", name, avatar);
                [update setValue:avatar forKey:@"avatar"];
                prefsUpdated = true;
            }
            else {
                //NSLog(@"(%@) updated with action (%@)", name, action);
                [update setValue:action forKey:@"action"];
                prefsUpdated = true;
            }
            if (prefsUpdated) {
                [users removeObject:user];
                [users addObject:update];
                break;
            }
        }
    }
    
    if (!prefsUpdated) {
        if ([action isEqualToString:@"hide"] || [action isEqualToString:@"mute"]) {
            NSLog(@"(%@) added with action (%@)", name, action);
            [users addObject:@{@"name":name, @"action":action}];
            prefsUpdated = true;
        }
        else if ([action isEqualToString:@"avatar"]) {
            NSString *avatar = [userInfo valueForKey:@"avatar"];
            //NSLog(@"(%@) added with avatar (%@)", name, avatar);
            [users addObject:@{@"name":name, @"action":@"none", @"avatar":avatar}];
            prefsUpdated = true;
        }
    }

    if (prefsUpdated) {
        //NSLog(@"Update and synchronize preferences");
        [prefs setValue:users forKey:@"users"];
        [prefs synchronize];
        return true;
    }
    return false;
}

- (void)messageReceivedWithName:(NSString *)messageName fromPage:(SFSafariPage *)page userInfo:(NSDictionary *)userInfo {
    // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
    [page getPagePropertiesWithCompletionHandler:^(SFSafariPageProperties *properties) {
        NSLog(@"The extension received a message (%@) from a script injected into (%@) with userInfo (%@)", messageName, properties.url, userInfo);
        if ([messageName isEqualToString:@"DOMContentLoaded"]) {
            [page dispatchMessageToScriptWithName:@"filterComments" userInfo:self.dictionaryWithBlockerSettings];
        }
        else if ([messageName isEqualToString:@"blockUser"] || [messageName isEqualToString:@"changeAvatar"]) {
            [self updateBlockerSettingsWithUserInfo:userInfo];
            [page dispatchMessageToScriptWithName:@"settingsUpdated" userInfo:self.dictionaryWithBlockerSettings];
        }
    }];
}

@end
