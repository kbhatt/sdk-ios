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

#import "UIImageView+MTReady.h"
#import "MonkeyTalk.h"
#import "MTCommandEvent.h"
#import "MTDefaultProperty.h"

@implementation UIImageView (MTReady)
- (NSString *) valueForProperty:(NSString *)prop withArgs:(NSArray *)args {
    NSString* value;
    
    if ([prop isEqualToString:MTVerifyPropertyDefault]) {
        if (self.image)
            value = [NSString stringWithFormat:@"%@",self.accessibilityLabel];
        else
            value = [NSString stringWithFormat:@"No UIImage in UIImageView"];
    } else
        value = @"No value for property";
    
    return value;
}

- (void) handleMonkeyTouchEvent:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch* touch = [touches anyObject];
    CGPoint loc = [touch locationInView:self];
    
    if (touch.phase == UITouchPhaseEnded) {
        MTCommandEvent* command = [[MonkeyTalk sharedMonkey] lastCommandPosted];
        
        if ([command.command isEqualToString:MTCommandTouchMove]) {
            [MonkeyTalk recordFrom:self command:MTCommandTouchMove args:command.args];
            [[MonkeyTalk sharedMonkey].commands removeAllObjects];
        }
        
        [MonkeyTalk recordFrom:self command:MTCommandTouchUp args:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%1.0f", loc.x], 
                                                                   [NSString stringWithFormat:@"%1.0f", loc.y],
                                                                   nil]];
        
        [MonkeyTalk recordFrom:self command:MTCommandTap args:nil];
    }
}

- (void) playbackMonkeyEvent:(id)event {
    [super playbackMonkeyEvent:event];
}
@end
