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

#import "UISwitch+MTReady.h"
#import "MonkeyTalk.h"
#import "MTUtils.h"
#import "MTCommandEvent.h"
#import "MTDefaultProperty.h"
#import "MTVerifyCommand.h"
#import "NSString+MonkeyTalk.h"

@implementation UISwitch (MTReady) 

- (NSString *) valueForProperty:(NSString *)prop withArgs:(NSArray *)args {
    NSString* value;
    
    BOOL isOn = [[self valueForKeyPath:MTVerifyPropertySwitch] boolValue];
    
    if (isOn)
        value = @"on";
    else
        value = @"off";
    
    return value;
}

- (void) handleSwitchTouchEvent:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch* touch = [touches anyObject];
    NSString *command = MTCommandOff;
    
    if (!self.on)
        command = MTCommandOn;
    
    if (touch.phase == UITouchPhaseEnded)
        [MonkeyTalk recordFrom:self command:command];
        
}

- (void) playbackSwitchEvent:(id)event {
	// toggles
    NSString* command = ((MTCommandEvent*)event).command;
    BOOL turnOn = NO;
    BOOL hasAction = YES;
    
    if ([[command lowercaseString] rangeOfString:@"verify"].location != NSNotFound) 
        [MTVerifyCommand handleVerify:event];
    else if ([command isEqualToString:MTCommandOn ignoreCase:YES])
        turnOn = YES;
    else if ([command isEqualToString:MTCommandOff ignoreCase:YES])
        turnOn = NO;
    else
        hasAction = NO;
    
//    // Do not toggle switch on verify command
//    else if (![command isEqualToString:MTCommandVerify ignoreCase:YES]) {
//        [self setOn:!self.on animated:NO];
//        [self sendActionsForControlEvents:UIControlEventValueChanged];
//    }
    
    if (hasAction) {
        [self setOn:turnOn animated:NO];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void) playbackMonkeyEvent:(id)event {
	// toggles
    [self playbackSwitchEvent:event];
}

+ (NSString*) uiAutomationCommand:(MTCommandEvent*)command {
	
	if ([command.command isEqualToString:MTCommandSwitch]) {
		return [NSString stringWithFormat:@"MonkeyTalk.toggleSwitch(\"%@\"); // UIASwitch", 
				[MTUtils stringByJsEscapingQuotesAndNewlines:command.monkeyID]];
	}
	
	return [super uiAutomationCommand:command];
	
}
@end
