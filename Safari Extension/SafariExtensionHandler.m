//
//  SafariExtensionHandler.m
//  SavageLUBE Extension
//
//  Created by fubar on 2020-07-27.
//  Copyright © 2020 fubar. All rights reserved.
//

#import <Foundation/NSUserDefaults.h>
#import <SafariServices/SFSafariToolbarItem.h>
#import "SafariExtensionHandler.h"
#import "SafariExtensionViewController.h"

static SafariExtensionHandler *_sharedHandler = nil;

@interface SafariExtensionHandler ()

- (void)initBlockerSettings;

@end

@implementation SafariExtensionHandler

+ (SafariExtensionHandler *)sharedHandler {
    return _sharedHandler;
}

- (instancetype)init {
    if (self = [super init]) {
        [self initBlockerSettings];
        _sharedHandler = self;
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
        [prefs setBool:true forKey:@"addCommentLinks"];
        [prefs synchronize];
    }
}

- (NSDictionary *)dictionaryWithBlockerSettings {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return @{@"users":[prefs arrayForKey:@"users"], @"addAvatarTooltips":[NSNumber numberWithBool:[prefs boolForKey:@"addAvatarTooltips"]],  @"moveUserBylines":[NSNumber numberWithBool:[prefs boolForKey:@"moveUserBylines"]], @"addTopPagination":[NSNumber numberWithBool:[prefs boolForKey:@"addTopPagination"]],
        @"addCommentLinks":[NSNumber numberWithBool:[prefs boolForKey:@"addCommentLinks"]]
    };
}

-(NSString *)stringWithBlockerSettings {
    NSDictionary *settings = [self dictionaryWithBlockerSettings];
    NSString *settingsString;
    if (@available(macOS 10.15, *)) {
        NSError *err;
        NSData *jsonData = [NSJSONSerialization  dataWithJSONObject:settings options:NSJSONWritingWithoutEscapingSlashes error:&err];
        settingsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } else {
        settingsString = [NSString stringWithFormat:@"%@", settings];
    }
    return settingsString;
}

- (bool)updateBlockerSettingsWithAppInfo:(NSDictionary *)appInfo {
    NSString *name = [appInfo valueForKey:@"name"];
    NSString *action = [appInfo valueForKey:@"action"];
    //NSLog(@"Updating user (%@) with action (%@)", name, action);

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    BOOL prefsUpdated = false;
    
    NSMutableArray *users = [[prefs arrayForKey:@"users"] mutableCopy];
    for (NSDictionary *user in users) {
        NSMutableDictionary *update = [user mutableCopy];
        if ([name caseInsensitiveCompare:[user valueForKey:@"name"]] == NSOrderedSame ) {
            if ([action isEqualToString:@"unmute"] || [action isEqualToString:@"unbold"]) {
                //NSLog(@"(%@) unmuted", name);
                [update setValue:@"none" forKey:@"action"];
                prefsUpdated = true;
            }
            else if([action isEqualToString:@"avatar"]) {
                NSString *avatar = [appInfo valueForKey:@"avatar"];
                //NSLog(@"(%@) new avatar (%@)", name, avatar);
                if (avatar.length > 0) {
                    [update setValue:avatar forKey:@"avatar"];
                }
                else {
                    [update removeObjectForKey:@"avatar"];
                }
                prefsUpdated = true;
            }
            else {
                //NSLog(@"(%@) updated with action (%@)", name, action);
                [update setValue:action forKey:@"action"];
                prefsUpdated = true;
            }
            if (prefsUpdated) {
                [users removeObject:user];
                if (![[update valueForKey:@"action"] isEqualToString:@"none"] || ([[update valueForKey:@"avatar"] length] > 0)) {
                    [users addObject:update];
                }
                break;
            }
        }
    }
    
    if (!prefsUpdated) {
        if ([action isEqualToString:@"hide"] || [action isEqualToString:@"mute"] || [action isEqualToString:@"bold"]) {
            //NSLog(@"(%@) added with action (%@)", name, action);
            [users addObject:@{@"name":name, @"action":action}];
            prefsUpdated = true;
        }
        else if ([action isEqualToString:@"avatar"]) {
            NSString *avatar = [appInfo valueForKey:@"avatar"];
            //NSLog(@"(%@) added with avatar (%@)", name, avatar);
            if (avatar.length > 0) {
                [users addObject:@{@"name":name, @"action":@"none", @"avatar":avatar}];
                prefsUpdated = true;
            }
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

- (bool)isBoolEqualForKey:(NSString *)key inSettings:(NSUserDefaults *)prefs andDictionary:(NSDictionary *)dictionary {
    return [prefs boolForKey:key] == [[dictionary objectForKey:key] boolValue];
}

- (bool)_debug_areSettingsEqualToDictionary:(NSDictionary *)dictionary {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if (![self isBoolEqualForKey:@"addAvatarTooltips" inSettings:prefs andDictionary:dictionary]) {
        NSLog(@"addAvatarTooltips");
        return false;
    }

    if (![self isBoolEqualForKey:@"moveUserBylines" inSettings:prefs andDictionary:dictionary]) {
        NSLog(@"moveUserBylines");
        return false;
    }

    if (![self isBoolEqualForKey:@"addTopPagination" inSettings:prefs andDictionary:dictionary]) {
        NSLog(@"addTopPagination");
        return false;
    }

    if (![self isBoolEqualForKey:@"addCommentLinks" inSettings:prefs andDictionary:dictionary]) {
        NSLog(@"addCommentLinks");
        return false;
    }

    NSArray *dictUsers = [dictionary objectForKey:@"users"];
    NSArray *prefUsers = [prefs arrayForKey:@"users"];
    if (![dictUsers isEqualToArray:prefUsers]) {
        NSLog(@"users (array)");
        //return false;
    }
    
    if (dictUsers.count != prefUsers.count) {
        NSLog(@"users (count)");
        return false;
    }

    for (NSDictionary *dictUser in dictUsers) {
        NSString *name = [[dictUser objectForKey:@"name"] stringValue];
        NSUInteger index = [prefUsers indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([name isEqualToString:[obj objectForKey:@"name"]]) {
                *stop = true;
                return true;
            }
            return false;
        }];
        
        if (index == NSNotFound) {
            NSLog(@"user %@ not found", name);
            return false;
        }
        
        NSString *action = [[dictUser objectForKey:@"action"] stringValue];
        if (![action isEqualToString:[prefUsers[index] objectForKey:@"action"]]) {
            NSLog(@"user %@ (action)", name);
            return false;
        }

        NSString *avatar = [[dictUser objectForKey:@"avatar"] stringValue];
        if (![avatar isEqualToString:[prefUsers[index] objectForKey:@"avatar"]]) {
            NSLog(@"user %@ (avatar)", name);
            return true;
        }
    }

    return true;
}

- (bool)updateBlockerSettingsWithDictionary:(NSDictionary *)dictionary {
    if (![self.dictionaryWithBlockerSettings isEqualToDictionary:dictionary]) {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setBool:[[dictionary objectForKey:@"addAvatarTooltips"] boolValue] forKey:@"addAvatarTooltips"];
        [prefs setBool:[[dictionary objectForKey:@"moveUserBylines"] boolValue] forKey:@"moveUserBylines"];
        [prefs setBool:[[dictionary objectForKey:@"addTopPagination"] boolValue] forKey:@"addTopPagination"];
        [prefs setBool:[[dictionary objectForKey:@"addCommentLinks"] boolValue] forKey:@"addCommentLinks"];
        [prefs setValue:dictionary[@"users"] forKey:@"users"];
        [prefs synchronize];

        [self broadcastMessageToScriptWithName:@"settingsUpdated" userInfo:self.dictionaryWithBlockerSettings];
        return true;
    }
    return false;
}

- (bool)updateBlockerSettingsWithString:(NSString *)string
{
    NSError *err;
    NSData *jsonData =[string dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData) {
        NSDictionary *settings = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
        return [self updateBlockerSettingsWithDictionary:settings];
    }
    return false;
}

- (void)broadcastMessageToScriptWithName:(NSString *)messageName userInfo:(nullable NSDictionary<NSString *, id> *)userInfo {
    [SFSafariApplication getActiveWindowWithCompletionHandler:^(SFSafariWindow * _Nullable activeWindow) {
        [activeWindow getAllTabsWithCompletionHandler:^(NSArray<SFSafariTab *> * _Nonnull tabs) {
            for (SFSafariTab *tab in tabs) {
                [tab getActivePageWithCompletionHandler:^(SFSafariPage * _Nullable activePage) {
                    [activePage dispatchMessageToScriptWithName:messageName userInfo:userInfo];
                }];
            }
        }];
    }];
}


#pragma mark SFSafariExtensionHandling

- (void)messageReceivedWithName:(NSString *)messageName fromPage:(SFSafariPage *)page userInfo:(NSDictionary *)userInfo {
    // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
    [page getPagePropertiesWithCompletionHandler:^(SFSafariPageProperties *properties) {
        //NSLog(@"The extension received a message (%@) from a script injected into (%@) with userInfo (%@)", messageName, properties.url, userInfo);
        if ([messageName isEqualToString:@"DOMContentLoaded"]) {
            [page dispatchMessageToScriptWithName:@"filterComments" userInfo:self.dictionaryWithBlockerSettings];
        }
        else if ([messageName isEqualToString:@"blockUser"] || [messageName isEqualToString:@"changeAvatar"]) {
            [self updateBlockerSettingsWithAppInfo:userInfo];
            [page dispatchMessageToScriptWithName:@"settingsUpdated" userInfo:self.dictionaryWithBlockerSettings];
        }
    }];
}

- (SFSafariExtensionViewController *)popoverViewController {
	return [SafariExtensionViewController sharedController];
}

- (void)toolbarItemClickedInWindow:(SFSafariWindow *)window {
}

- (void)contextMenuItemSelectedWithCommand:(NSString *)command inPage:(SFSafariPage *)page userInfo:(nullable NSDictionary<NSString *, id> *)userInfo {
    if ([command caseInsensitiveCompare: @"SavageLUBESettings"] == NSOrderedSame) {
        [SFSafariApplication getActiveWindowWithCompletionHandler:^(SFSafariWindow * _Nullable activeWindow) {
            [activeWindow getToolbarItemWithCompletionHandler:^(SFSafariToolbarItem * _Nullable toolbarItem) {
                [toolbarItem showPopover];
            }];
        }];
    }
}

@end
