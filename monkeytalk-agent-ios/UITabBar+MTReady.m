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

#import "UITabBar+MTReady.h"
#import "MonkeyTalk.h"
#import "TouchSynthesis.h"

@implementation UITabBar (MTReady)

- (void) handleTabBar:(UITabBar *)tabBar {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Short delay to get the tab navigated to
        [NSThread sleepForTimeInterval:0.1];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UITabBarController *tbController = (UITabBarController *)tabBar.delegate;
            
            NSString *monkeyID = tabBar.selectedItem.title;
            NSString *command = @"";
            
            if ([monkeyID length] == 0) {
                // New changes for handling 'More navigation controller' - Kapil
                
                // monkeyID = [NSString stringWithFormat:@"%i",tbController.selectedIndex+1];
                NSUInteger test = tbController.selectedIndex;
                if(test == NSNotFound)
                {
                    if([tbController.selectedViewController isEqual:tbController.moreNavigationController] ) {
                        monkeyID = @"More";
                        command = MTCommandSelect;
                    }
                }
                else {
                    monkeyID = [NSString stringWithFormat:@"%i",tbController.selectedIndex+1];
                }
                
                if ([command length] == 0)
                    command = MTCommandSelectIndex;
            } else {
                command = MTCommandSelect;
            }
            
            NSArray *monkeyArg = [NSArray arrayWithObject:monkeyID];
            
            [MonkeyTalk recordFrom:tabBar command:command args:monkeyArg];
        }); 
    });
}

- (void) playbackTabBarEvent:(MTCommandEvent *)event {
	// We should actually call this on all components from up in the run loop
    //	[self mtAssureAutomationInit];
	
	// By default we generate a touch in the center of the view
	MTCommandEvent* ev = event;
    
    if ([[ev args] count] == 0) {
        ev.lastResult = [NSString stringWithFormat:@"Requires 1 argument, but has %d", [ev.args count]];
        return;
    }
    
    NSInteger selectIndex = -1;
    UITabBar *tabBar = (UITabBar *)self;
    UITabBarController *tbController = (UITabBarController *)tabBar.delegate;
    
    if ([[ev command] isEqualToString:MTCommandTouch] || 
        [[[ev command] lowercaseString] isEqualToString:[MTCommandSelect lowercaseString]]) {
        
        // New change regarding handling 'More navigation controller' -Kapil
        if ([[ev.args objectAtIndex:0] isEqualToString:@"More"]) {
            [tbController setSelectedViewController:tbController.moreNavigationController];
            return;
        }
        
        NSString *title = [ev.args objectAtIndex:0];
        
        
        for (int i = 0; i < [tabBar.items count]; i++) {
            UITabBarItem* item = [tabBar.items objectAtIndex:i];
            if ([title isEqualToString:item.title]) {
                selectIndex = i;
                //                [tbController setSelectedIndex:i];
            }
            //                [UIEvent performTouchInView:(UIView *)item]; 
        }
    } 
    else if ([[[ev command] lowercaseString] isEqualToString:[MTCommandSelectIndex lowercaseString]]) {
        selectIndex = [[ev.args objectAtIndex:0] integerValue]-1;
    }
    
    if (selectIndex >= 0) {
        if (selectIndex > [tabBar.items count] || selectIndex < 0) {
            ev.lastResult = [NSString stringWithFormat:@"%@ out of index range for UITabBar with monkeyID %@",[ev.args objectAtIndex:0],ev.monkeyID];
            return;
        }
        
        [tbController setSelectedIndex:selectIndex];
    }
    else
        ev.lastResult = [NSString stringWithFormat:@"Could not find %@ tab UITabBar with monkeyID %@", [ev.args objectAtIndex:0], ev.monkeyID];
}
@end
