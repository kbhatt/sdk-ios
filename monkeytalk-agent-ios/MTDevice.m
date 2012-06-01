/*  MonkeyTalk - a cross-platform functional testing tool
    Copyright (C) 2012 Gorilla Logic, Inc.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>. */

#import "MTDevice.h"
#import "MonkeyTalk.h"
#import "MTConvertType.h"
#import "MTComponentTree.h"
#import "MTUtils.h"
#import "SBJSONMT.h"
#import "MTVerifyCommand.h"
#import "UIDevice+Hardware.h"

@implementation MTDevice

static const NSString *MT_PROPERTY_VALUE = @"value";
static const NSString *MT_PROPERTY_OS = @"os";
static const NSString *MT_PROPERTY_VERSION = @"version";
static const NSString *MT_PROPERTY_NAME = @"name";
static const NSString *MT_PROPERTY_RESOLUTION = @"resolution";
static const NSString *MT_PROPERTY_ORIENTATION = @"orientation";

static const NSString *MT_VALUE_PORTRAIT = @"portrait";
static const NSString *MT_VALUE_LANDSCAPE = @"landscape";

+ (NSString *) os {
    return @"iOS";
}

+ (NSString *) foundValue:(NSArray *)args {
    UIDevice *device = [UIDevice currentDevice];
    NSString *value = [[self class] os];
    
    if ([args count] > 1) {
        if ([[args objectAtIndex:1] rangeOfString:@"."].location == 0) {
            value = [device valueForKeyPath:[[args objectAtIndex:1] substringFromIndex:1]];
        } else if ([[args objectAtIndex:1] isEqualToString:MT_PROPERTY_OS] ||
                   [[args objectAtIndex:1] isEqualToString:MT_PROPERTY_VALUE]) {
            value = [[self class] os];
        } else if ([[args objectAtIndex:1] isEqualToString:MT_PROPERTY_VERSION]) {
            value = [device systemVersion];
        } else if ([[args objectAtIndex:1] isEqualToString:MT_PROPERTY_NAME]) {
            value = [device platformString];
        } else if ([[args objectAtIndex:1] isEqualToString:MT_PROPERTY_RESOLUTION]) {
            // Use scale and mainScreen bounds to determine resolution
            float width = [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale;
            float height = [UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale;
            value = [NSString stringWithFormat:@"%0.0fx%0.0f",width,height];
        } else if ([[args objectAtIndex:1] isEqualToString:MT_PROPERTY_ORIENTATION]) {
            // ToDo: Get orientation
            NSInteger orientation;
            
            if ([[MTUtils rootWindow] respondsToSelector:@selector(rootViewController)] && 
                [MTUtils rootWindow].rootViewController)
                // Use rootViewController orientation if available
                orientation = [[MTUtils rootWindow].rootViewController interfaceOrientation];
            else {
                // If there is no rootViewController, use statusBar orientation
                orientation = [UIApplication sharedApplication].statusBarOrientation;
            }
            
            if (orientation == UIInterfaceOrientationPortrait || 
                orientation == UIInterfaceOrientationPortraitUpsideDown)
                value = MT_VALUE_PORTRAIT;
            else
                value = MT_VALUE_LANDSCAPE;
        }
    }
    return value;
}

+ (NSMutableDictionary *) postStringForCommand:(MTCommandEvent *)nextCommandToRun andDict:(NSMutableDictionary *)jsonDict {
    SBJsonWriterMT *jsonWriter = [[SBJsonWriterMT alloc] init];
    NSString *postString = nil;
    
    if ([nextCommandToRun.command  isEqualToString:MTCommandScreenshot ignoreCase:YES]) {
        // Handle screenshot command in MonkeyTalk
        
        NSDictionary *screenshot = [NSDictionary dictionaryWithObject:[MTUtils encodedScreenshot] forKey:@"screenshot"];
        
        [jsonDict setValue:screenshot forKey:@"message"];
        [jsonDict setValue:@"OK" forKey:@"result"];
        postString = [jsonWriter stringWithObject:jsonDict];
    } else if ([nextCommandToRun.command  isEqualToString:MTCommandShake ignoreCase:YES]) {
        [MTUtils shake];
    } else if ([nextCommandToRun.command  isEqualToString:MTCommandBack ignoreCase:YES]) {
        // Handle Device * Back as back button tap
        nextCommandToRun.className = @"UINavigationItemButtonView";
        nextCommandToRun.monkeyID = @"#1";
        
        [[MonkeyTalk sharedMonkey] performSelectorOnMainThread:@selector(playbackMonkeyEvent:) 
                               withObject:nextCommandToRun waitUntilDone:YES];
    } else if ([nextCommandToRun.command  isEqualToString:MTCommandRotate ignoreCase:YES]) {
        [[MonkeyTalk sharedMonkey] performSelectorOnMainThread:@selector(rotate:) withObject:nextCommandToRun waitUntilDone:YES];
    } else if ([[nextCommandToRun.command lowercaseString] rangeOfString:@"get"].location == 0) {
//        NSString *arg = nil;        
//        if ([nextCommandToRun.args count] == 0)
//            arg = @"os";
//        else if ([nextCommandToRun.args count] == 1)
//            arg = [[nextCommandToRun.args objectAtIndex:0]];
//        else
//            NSLog(@"expected 0 or 1 args");
        NSString *value = [[self class] foundValue:nextCommandToRun.args];
         
        [jsonDict setValue:value forKey:@"message"];
    } else if ([[nextCommandToRun.command lowercaseString] rangeOfString:@"verify"].location == 0) {
        NSString *value = [[self class] foundValue:nextCommandToRun.args];
        nextCommandToRun.value = value;
        [MTVerifyCommand handleVerify:nextCommandToRun];
    }
    
    return jsonDict;
}
@end
