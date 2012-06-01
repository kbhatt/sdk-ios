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

#import "UIView+MTReady.h"
#import "UISwitch+MTReady.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "MTCommandEvent.h"
#import "MonkeyTalk.h"
#import "UIControl+MTready.h"
#import "TouchSynthesis.h"
#import "MTUtils.h"
#import "UITabBarButtonProxy.h"
#import "UIToolbarTextButtonProxy.h"
#import "UIPushButtonProxy.h"
#import "UISegmentedControlProxy.h"
#import "UITableViewCellContentViewProxy.h"
#import "MTVerifyCommand.h"
#import "MTGestureCommand.h"
#import "NSString+MonkeyTalk.h"
#import "MTGetVariableCommand.h"

@implementation UIView (MonkeyTalk) 
static NSArray* privateClasses;
+ (void)load {
	if (self == [UIView class]) {
		// These are private classes that receive UI events, but the corresponding public class is a superclass. We'll record the event on the first superclass that's public.
		// This might be a config file someday
		privateClasses = [[NSArray alloc] initWithObjects:@"UIPickerTable", @"UITableViewCellContentView", 
						  @"UITableViewCellDeleteConfirmationControl", @"UITableViewCellEditControl", @"UIAutocorrectInlinePrompt", nil];
		
        Method originalMethod = class_getInstanceMethod(self, @selector(initWithFrame:));
        Method replacedMethod = class_getInstanceMethod(self, @selector(mtInitWithFrame:));
        method_exchangeImplementations(originalMethod, replacedMethod);	
	}
}

- (void) mtAssureAutomationInit {
	
}

- (id)mtInitWithFrame:(CGRect)aRect {
	
	// Should be able to move this whole thing into mtAssureAutomationInit
	
	// This is actually for UIControl, but UIControl inherits this method
	// Calls original initWithFrame (that we swapped in load method)
	if ((self = [self mtInitWithFrame:aRect])) {	
		if ([self isKindOfClass:[UIControl class]]) {
			[(UIControl*)self performSelector:@selector(subscribeToMonkeyEvents)];
		}
	}
	
	// Calls original (that we swapped in load method)
//	if (self = [self mtInit]) {	
//
//	}
	
	return self;	
	
}

- (void) handleMonkeyTouchEvent:(NSSet*)touches withEvent:(UIEvent*)event {
	// Test for special UI classes that require special handling of record
    
    // Ignore web view scrollview's subviews
    if ([self.superview isKindOfClass:objc_getClass("_UIWebViewScrollView")])
        return;
    
    if ([self isKindOfClass:[UIButton class]] &&
        [self.superview isKindOfClass:[UITableViewCell class]]) {
        // Is an accessory button to be handled by UITableView
        UITouch* touch = [touches anyObject];
        UITableViewCell *cell = (UITableViewCell *)self.superview;
        UITableView *tableView = (UITableView *)cell.superview;
        NSString *row = [NSString stringWithFormat:@"%i",[tableView indexPathForCell:cell].row +1];
        NSString *section = [NSString stringWithFormat:@"%i",[tableView indexPathForCell:cell].section +1];
        NSMutableArray *args = [[NSMutableArray alloc] init];
        
        [args addObject:row];
        
        if ([tableView indexPathForCell:cell].section > 0)
            [args addObject:section];
        
        if (touch.phase == UITouchPhaseEnded)
            [MonkeyTalk recordFrom:tableView command:MTCommandSelectIndicator args:args];
        
        [args release];
        return;
    }else if ([self isKindOfClass:objc_getClass("UITableViewCellReorderControl")]) {
        // Do not record tap on reorder control component
        return;
    } else if ([self isKindOfClass:objc_getClass("UISegmentedControl")]) {
        // UISegmentedControl
        UITouch* touch = [touches anyObject];
		UISegmentedControlProxy *tmp = (UISegmentedControlProxy *)self;
		int index = tmp.selectedSegmentIndex;
		if (index < 0) {
			return;
		}	
		NSString* title = [tmp titleForSegmentAtIndex:index];
        NSString* command = MTCommandSelect;
		
		if (title == nil) {
			title = [NSString stringWithFormat:@"%d", index+1];
            command = MTCommandSelectIndex;
		}
        
        if (touch.phase == UITouchPhaseEnded)
            [MonkeyTalk recordFrom:self command:command args:[NSArray arrayWithObject:title]];
	} else {
		// DEFAULT
		// By default we simply record that they touched the view
		UITouch* touch = [touches anyObject];
//        NSLog(@"Touch: %i",touch.phase);
		if (touch.phase == UITouchPhaseMoved) {
			CGPoint loc = [touch locationInView:self];
			MTCommandEvent* command = [[MonkeyTalk sharedMonkey] lastCommandPosted];
			if (([command.command isEqualToString:MTCommandMove ignoreCase:YES]  ||
                [command.command isEqualToString:MTCommandTouchMove ignoreCase:YES])
                && [command.monkeyID isEqualToString:[self monkeyID]]) {
				[[MonkeyTalk sharedMonkey] deleteCommand:[[MonkeyTalk sharedMonkey] commandCount] - 1];
				NSMutableArray* args = [NSMutableArray arrayWithArray:command.args];
				[args addObjectsFromArray:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%1.0f", loc.x], 
										   [NSString stringWithFormat:@"%1.0f", loc.y],
										   nil]];
                
                MTCommandEvent *moveEvent = [[MTCommandEvent alloc]
                                             init:MTCommandTouchMove className:[NSString stringWithUTF8String:class_getName([self class])]
                                             monkeyID:[self monkeyID]
                                             args:args];
                
                [MonkeyTalk buildCommand:moveEvent];
                
//				[MonkeyTalk recordFrom:self command:MTCommandTouchMove args:args];
				return;
			} else {
//				[MonkeyTalk recordFrom:self command:MTCommandTouchMove args:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%1.0f", loc.x], 
//																		[NSString stringWithFormat:@"%1.0f", loc.y],
//																		nil]];
                
                NSMutableArray* args = [NSMutableArray arrayWithArray:command.args];
				[args addObjectsFromArray:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%1.0f", loc.x], 
										   [NSString stringWithFormat:@"%1.0f", loc.y],
										   nil]];
                
                MTCommandEvent *moveEvent = [[MTCommandEvent alloc]
                                             init:MTCommandTouchMove className:[NSString stringWithUTF8String:class_getName([self class])]
                                             monkeyID:[self monkeyID]
                                             args:args];
                
                [MonkeyTalk buildCommand:moveEvent];
				return;
			}
		} else if (touch.phase == UITouchPhaseBegan) {
//            NSLog(@"TouchBegan: %i",touch.phase);
            CGPoint loc = [touch locationInView:self];
            if (![self isKindOfClass:objc_getClass("UITabBarButton")])
                [MonkeyTalk recordFrom:self command:MTCommandTouchDown args:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%1.0f", loc.x], 
                                                                         [NSString stringWithFormat:@"%1.0f", loc.y],
                                                                         nil]];
            return;
        } else if (touch.phase == UITouchPhaseEnded) {
            CGPoint loc = [touch locationInView:self];
            
            
            // Handle Tap
            // MT6: No coordinates for tap
            NSMutableArray* args = nil;
            if (touch.tapCount >1) {
                args = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%1.0d", touch.tapCount]];
            }
            
            
            if ([self isKindOfClass:objc_getClass("UITabBarButton")]) {
                UITabBarButtonProxy* but = (UITabBarButtonProxy *)self;
                NSString* label = nil;
                
                // Fixes error in iOS5+ caused by UITabBarSwappableImageView
                if ([but->_label respondsToSelector:@selector(text)])
                    label = [but->_label text];
                else {
                    for (UILabel *foundLabel in [but subviews]) {
                        //                    NSLog(@"found: %@",foundLabel);
                        if ([foundLabel isKindOfClass:objc_getClass("UITabBarButtonLabel")])
                            label = foundLabel.text;
                    }
                }
                
                UITabBar *tabBar = (UITabBar *)self.superview;
                
                if ([tabBar isKindOfClass:[UITabBar class]]) {
                    [tabBar handleTabBar:tabBar];
                    return;
                }
            } else if ([self isKindOfClass:objc_getClass("UISwitch")] ||
                       [self isKindOfClass:objc_getClass("_UISwitchInternalView")]) {
                UISwitch *aSwitch = nil;
                
                if ([self isKindOfClass:objc_getClass("_UISwitchInternalView")])
                    aSwitch = (UISwitch *)self.superview;
                else
                    aSwitch = (UISwitch *)self;
                
                [aSwitch handleSwitchTouchEvent:touches withEvent:event];
            } else {
                MTCommandEvent* command = [[MonkeyTalk sharedMonkey] lastCommandPosted];
                
                if ([command.command isEqualToString:MTCommandTouchMove]) {
                    [MonkeyTalk recordFrom:self command:MTCommandTouchMove args:command.args];
                    [[MonkeyTalk sharedMonkey].commands removeAllObjects];
                }
                
                [MonkeyTalk recordFrom:self command:MTCommandTouchUp args:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%1.0f", loc.x], 
                                                                           [NSString stringWithFormat:@"%1.0f", loc.y],
                                                                           nil]];
                
                [MonkeyTalk recordFrom:self command:MTCommandTap args:args];
            }
            
            return;
        }
		CGPoint loc = [touch locationInView:self];	
//		NSMutableArray* args = [NSMutableArray arrayWithObjects:
//                                [NSString stringWithFormat:@"%1.0f", loc.x], 
//								[NSString stringWithFormat:@"%1.0f", loc.y],
//								nil];
        
	} //End Default record operations
}

- (void) handleMonkeyMotionEvent:(UIEvent*)event {
	[MonkeyTalk recordFrom:nil command:MTCommandShake];
}

- (BOOL) shouldRecordMonkeyTouch:(UITouch*)touch {
	// By default, we only record TouchEnded	
//	return (touch.phase == UITouchPhaseEnded);
    return YES;
}

- (void) playbackMonkeyEvent:(id)event {
	// We should actually call this on all components from up in the run loop
	[self mtAssureAutomationInit];
	
	// By default we generate a touch in the center of the view
	MTCommandEvent* ev = event;
    
    if (([self isKindOfClass:objc_getClass("UISegmentedControl")]) && 
        ([[ev command] isEqualToString:MTCommandTouch] || 
         [[ev command] isEqualToString:MTCommandSelectIndex ignoreCase:YES] ||
         [[ev command] isEqualToString:MTCommandSelect ignoreCase:YES])) {
		UISegmentedControlProxy *tmp = (UISegmentedControlProxy *)self;
		if ([[ev args] count] == 0) {
			ev.lastResult = @"Requires 1 argument, but has %d", [ev.args count];
			return;
		}	
		int index;
		int i;
		NSString* title =(NSString*) [ev.args objectAtIndex:0];
		for (i = 0; i < [tmp numberOfSegments]; i++) {
			
			NSString* t = [tmp titleForSegmentAtIndex:i];

			if (t == nil)  {
                // MT6: ToDo Fix to handle with no title (iOS5)
				index = [title intValue]-1;
				// Need to use undocumented property that contains array of "segments" (subviews that are the buttons)	
                
                
                if ([MTUtils isOs5Up]) {
                    NSMutableArray *segmentsArray = [NSMutableArray arrayWithArray:[tmp subviews]];
                    if ([segmentsArray count] > 0) {
                        [segmentsArray sortUsingComparator:  
                         ^NSComparisonResult (id obj1, id obj2) {  
                             UIView *view1 = (UIView *)obj1;
                             UIView *view2 = (UIView *)obj2;
                             CGPoint point1 = view1.frame.origin;
                             CGPoint point2 = view2.frame.origin;  
                             
                             if (point1.y > point2.y)  
                                 return NSOrderedDescending;  
                             else if (point1.y < point2.y)  
                                 return NSOrderedAscending;
                             else if (point1.x > point2.x)  
                                 return NSOrderedDescending;  
                             else if (point1.x < point2.x)  
                                 return NSOrderedAscending; 
                             else  
                                 return NSOrderedSame;  
                         }  
                         ];
                    }
                    
                    for (int i = 0; i < [segmentsArray count]; i++) {
                        id segment = [segmentsArray objectAtIndex:i];
                        if (i == index) {
                            [UIEvent performTouchInView:(UIView *)segment];
                            break;
                        }
                    }
                } else
                    [UIEvent performTouchInView:(UIView*) [tmp->_segments objectAtIndex:index]]; 
				return;
			}
			if ([t isEqualToString:title]) {
				// Need to use undocumented property that contains array of "segments" (subviews that are the buttons)
                
                if ([MTUtils isOs5Up]) {
                    for (id segment in [tmp subviews]) {
                        NSString *foundTitle = (NSString *)[segment infoName];
                        
                        if ([title isEqualToString:foundTitle])
                            [UIEvent performTouchInView:(UIView *)segment];
                    }
                } else
                    [UIEvent performTouchInView:(UIView*) [tmp->_segments objectAtIndex:i]]; 
                
				return;
			}
			
		}
		NSLog(@"Unable to find %@ in UISegmentedControl", title);
	} else {
		// DEFAULT
        if ([[ev.command lowercaseString] rangeOfString:@"verify"].location != NSNotFound) {
            [MTVerifyCommand handleVerify:ev];
            return;
        } else if ([ev.command isEqualToString:MTCommandGet ignoreCase:YES]) {
            [MTGetVariableCommand execute:ev];
            return;
        }
		
		if ([ev.command isEqualToString:MTCommandMove ignoreCase:YES] ||
            [ev.command isEqualToString:MTCommandTouchMove ignoreCase:YES]) {
			int i;
			CGPoint prevPoint;
			for (i = 0; i < ([ev.args count]); i += 2) {
				CGPoint point;
				point.x = [[ev.args objectAtIndex:i] floatValue];
				point.y = [[ev.args objectAtIndex:i+1] floatValue];
				if (i == 0) {
					prevPoint = point;
					//				[UIEvent performTouchDownInView:self at:point];
				} 
				//			else if (i == ([ev.args count]/2 - 2)) {
				//				[UIEvent performTouchUpInView:self at:point];
				//			} else {
				[UIEvent performMoveInView:self from:prevPoint to:point];
				
				//			}			
				prevPoint = point;
			}
			return;
		} else if ([ev.command isEqualToString:MTCommandTouchDown ignoreCase:YES]) {
            CGPoint point;
            point.x = [[ev.args objectAtIndex:0] floatValue];
            point.y = [[ev.args objectAtIndex:1] floatValue];
            [UIEvent performTouchBeganInView:self atPoint:point];
            
			return;
		} else if ([ev.command isEqualToString:MTCommandTouchUp ignoreCase:YES]) {
            CGPoint point;
            point.x = [[ev.args objectAtIndex:0] floatValue];
            point.y = [[ev.args objectAtIndex:1] floatValue];
            [UIEvent performTouchUpInView:self at:point];
            
			return;
		} else if ([ev.command isEqualToString:MTCommandSwipe ignoreCase:YES]) {
            [MTGestureCommand handleSwipe:ev];
			return;
        } else if ([ev.command isEqualToString:MTCommandPinch ignoreCase:YES]) {
            [MTGestureCommand handlePinch:ev];
			return;
        } else if ([self isKindOfClass:objc_getClass("UITabBarButton")] || 
                   [self isKindOfClass:objc_getClass("UITabBar")]) {
            UITabBar *tabBar = nil;
            
            if ([self isKindOfClass:objc_getClass("UITabBar")])
                tabBar = (UITabBar *)self;
            else
                tabBar = (UITabBar *)self.superview;
            
            if ([tabBar isKindOfClass:[UITabBar class]]) {
                [tabBar playbackTabBarEvent:event];
            }
            
            return;
        }
//        NSLog(@"Class: %@",[self class]);
//        else if ([[ev.command isEqualToString:MTCommandSet ignoreCase:YES]) {
//            NSLog(@"set: %@ -------------",self);
//            if ([self isKindOfClass:objc_getClass("UISwitch")] ||
//                [self isKindOfClass:objc_getClass("_UISwitchInternalView")]) {
//                UISwitch *aSwitch = nil;
//                
//                if ([self isKindOfClass:objc_getClass("_UISwitchInternalView")])
//                    aSwitch = (UISwitch *)self.superview;
//                else
//                    aSwitch = (UISwitch *)self;
//                
//                [aSwitch playbackSwitchEvent:event];
//            }
//            
//            return;
//        }
		
		CGPoint point;
		if ([ev.args count] >= 2) { 
			point.x = [[ev.args objectAtIndex:0] floatValue];
			point.y = [[ev.args objectAtIndex:1] floatValue];
			if ([ev.args count] == 3) {
				[UIEvent performTouchInView:self at:point withCount:[[ev.args objectAtIndex:2] intValue]];
			} else {
				[UIEvent performTouchInView:self at:point];
			}
		} else {
			[UIEvent performTouchInView:self];
		}
	} // End DEFAULT
}

- (BOOL) isMTEnabled {
	
	// Don't record private classes
	for (NSString* className in privateClasses) {
		if ([self isKindOfClass:objc_getClass([className UTF8String])]) {
			return NO;
		}
	}
	
	// Don't record containers		
	return ![self isMemberOfClass:[UIView class]] && ![MTUtils isKeyboard:self];
}

- (NSString*) monkeyID {
	
	if ([self isKindOfClass:objc_getClass("UITabBarButton")]) {
		UITabBarButtonProxy* but = (UITabBarButtonProxy *)self;
		NSString* label = nil;
        
        // Fixes error in iOS5+ caused by UITabBarSwappableImageView
        if ([but->_label respondsToSelector:@selector(text)])
            label = [but->_label text];
        else {
            for (UILabel *foundLabel in [but subviews]) {
//                NSLog(@"found: %@",foundLabel);
                if ([foundLabel isKindOfClass:objc_getClass("UITabBarButtonLabel")])
                    label = foundLabel.text;
            }
        }
		if (label != nil) {
			return label;
		}	
	} else if ([self isKindOfClass:objc_getClass("UIToolbarTextButton")]) {
		UIToolbarTextButtonProxy* but = (UIToolbarTextButtonProxy *)self;
		NSString* label = but->_title;
        
        // _info doesn't seem to be available in iOS5+
		if (![MTUtils isOs5Up] && [but->_info isKindOfClass:objc_getClass("UIPushButton")]) {
			label = [(UIPushButtonProxy *)but->_info title];
		}
		if (label != nil) {
			return label;
		}	
	} else if ([self isKindOfClass:objc_getClass("UITableViewCellContentViewProxy")]) {
		UISegmentedControlProxy *but = (UISegmentedControlProxy *)self;
		NSMutableString* label = [[[NSMutableString alloc] init] autorelease];
		int i;
		for (i = 0; i < [but numberOfSegments]; i++) {
			NSString* title = [but titleForSegmentAtIndex:i];
			if (title == nil) {
				goto use_default;
			}
			[label appendString:title];
		}
		return label;
	}
	//	else if ([self isKindOfClass:objc_getClass("UITableViewCellContentView")]) {
	//		UITableViewCellContentViewProxy *view = (UITableViewCellContentViewProxy *)self;
	//		UITableViewCell* cell = [view _cell];
	//		NSString* label = cell.textLabel.text;
	//		if (label != nil) {
	//			return label;
	//		} else {
	//			return [cell monkeyID];
	//		}
	//	}
	
use_default:;
    
    if ([self respondsToSelector:@selector(accessibilityIdentifier)] && 
        self.accessibilityIdentifier != nil && [self.accessibilityIdentifier length] > 0)
        return [self accessibilityIdentifier] ? [self accessibilityIdentifier] :
        self.tag < 0 ? [NSString stringWithFormat:@"%ld",(long)self.tag] :
        [[MonkeyTalk sharedMonkey] monkeyIDfor:self];
    
	return [self accessibilityLabel] ? [self accessibilityLabel] :
	self.tag < 0 ? [NSString stringWithFormat:@"%ld",(long)self.tag] :
	[[MonkeyTalk sharedMonkey] monkeyIDfor:self];
}

- (BOOL) swapsWith:(NSString*)className {
	if ([self isKindOfClass:objc_getClass("UIToolbarTextButton")] && [className isEqualToString:@"UINavigationButton"]) {
		return YES;
	}
	
	if ([self isKindOfClass:objc_getClass("UINavigationButton")] && [className isEqualToString:@"UIToolbarTextButton"]) {
		return YES;
	}	
	
	return NO;
	
}

+ (NSString*) uiAutomationCommand:(MTCommandEvent*)command {
	NSMutableString* string = [[[NSMutableString alloc] init] autorelease];
	if ([command.command isEqualToString:MTCommandTouch]) {
		[string appendFormat:@"MonkeyTalk.elementNamed(\"%@\").tap();", command.monkeyID];
	} else if ([command.command isEqualToString:MTCommandVerify ignoreCase:YES]) {
		[string appendString:[self uiAutomationVerifyCommand:command withTimeout:0]];
	} else 	if ([command.command isEqualToString:MTCommandPause ignoreCase:YES]) {
		if ([command.args count] > 0) {
			NSString* arg0 = [command.args objectAtIndex:0];
			int interval = [arg0 intValue]/1000;
			if (interval==0) {interval=1;}
			[string appendFormat:@"UIATarget.localTarget.delay(%d);   // MTPauseCommand", interval];
		}
	} else 	if ([command.command isEqualToString:MTCommandWaitFor]) {
		MTCommandEvent* verifyEvent = command;
		int interval=5; // default timeout is 5 seconds
		if ([command.args count] > 0) {
			NSString* arg0 = [command.args objectAtIndex:0];	
			if ([arg0 rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location==0) { // is it's numeric
				NSInteger msecs = [arg0 intValue];
				interval = msecs/1000;  
				if (interval==0) {interval=1;}
				NSMutableArray* newArgs = [NSMutableArray arrayWithArray:command.args];
				[newArgs removeObjectAtIndex:0];
				verifyEvent = [command copyWithZone:nil];
				verifyEvent.args = newArgs;
			}
		}
		[string appendString:[self uiAutomationVerifyCommand:verifyEvent withTimeout:interval]];
	} else if ([command.command isEqualToString:MTCommandShake ignoreCase:YES]) {
		string = @"UIATarget.localTarget().shake();";
	} else if ([command.command isEqualToString:MTCommandRotate ignoreCase:YES]) {
		NSString* orientation = [command.args count] ? [command.args objectAtIndex:0] : @"0";
		string = [NSString stringWithFormat:@"UIATarget.localTarget().setDeviceOrientation(%@);", orientation];
	} else {
		string = [NSString stringWithFormat:@"// UIView doesn't know how to write UIAutomation command %@ for: %@", command.command, command.className];
	}
	return string;
}

+ (NSString*) uiAutomationVerifyCommand:(MTCommandEvent*)command withTimeout:(int)timeout {
	NSMutableString* string = [[[NSMutableString alloc] init] autorelease];
	
	// [string appendFormat:@"// Verify command with timeout of %d sec\n", timeout];
	// [string appendFormat:@"UIATarget.localTarget().pushTimeout(%d);\n", timeout];
	
	if ([command.args count] > 1) {
		// NSString* prop = @"value"; // = [command.args objectAtIndex:0];
		NSString* expected = [command.args objectAtIndex:1];
		[string appendFormat:@"MonkeyTalk.assertElementValue(\"%@\", \"%@\", %d);\n",
		 [MTUtils stringByJsEscapingQuotesAndNewlines:command.monkeyID], 
		 [MTUtils stringByJsEscapingQuotesAndNewlines:[MTUtils stringByOcEscapingQuotesAndNewlines:expected]],
		 timeout];
	} else {
		[string appendFormat:@"MonkeyTalk.assertElement(\"%@\", %d);\n",
		 [MTUtils stringByJsEscapingQuotesAndNewlines:command.monkeyID],
		 timeout];
	}
	
	[string appendFormat:@"UIATarget.localTarget().popTimeout();\n"];
	
	return string;
}

+ (NSString*) objcCommandEvent:(MTCommandEvent*)command {
	
	NSMutableString* args = [[NSMutableString alloc] init];
	if (!command.args) {
		[args setString:@"nil"];
	} else {
		[args setString:@"[NSArray arrayWithObjects:"];
		NSString* arg;
		for (arg in command.args) {
			[args appendFormat:@"@\"%@\", ", [MTUtils stringByOcEscapingQuotesAndNewlines:arg]]; 
		}
		[args appendString:@"nil]"]; 
	}
	
	return [NSString stringWithFormat:@"[MTCommandEvent command:@\"%@\" className:@\"%@\" monkeyID:@\"%@\" delay:@\"%@\" timeout:@\"%@\" args:%@]", command.command, command.className, command.monkeyID, command.playbackDelay, command.playbackTimeout, args];
	
}

+ (NSString*) qunitCommandEvent:(MTCommandEvent*)command {
	
	NSMutableString* args = [[NSMutableString alloc] init];
	if (!command.args) {
		[args setString:@"null"];
	} else {
		//[args setString:@"["];
        for (int i = 0; i < [command.args count]; i++) {
            if (i == [command.args count]-1)
                [args appendFormat:@"\"%@\"", [MTUtils stringByOcEscapingQuotesAndNewlines:[command.args objectAtIndex:i]]];
            else
                [args appendFormat:@"\"%@\", ", [MTUtils stringByOcEscapingQuotesAndNewlines:[command.args objectAtIndex:i]]];
        }
		//[args appendString:@"]"]; 
	}
    
    if ([args length] == 0)
        [args appendString:@"null"];
	
	return [NSString stringWithFormat:@"\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", %@", command.command, command.className, command.monkeyID, command.playbackDelay, command.playbackTimeout, args];
	
}

//- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    [super touchesBegan:touches withEvent:event];
//
//    UITouch* touch = [touches anyObject];
//    CGPoint loc = [touch locationInView:self];
//    
//    // MT6: Record touch down (console does filtering)
//    [MonkeyTalk recordFrom:self command:MTCommandTouchDown args:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%1.0f", loc.x], 
//                                                                 [NSString stringWithFormat:@"%1.0f", loc.y],
//                                                                 nil]];
//}
//
//- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//    [super touchesEnded:touches withEvent:event];
//    
//    UITouch* touch = [touches anyObject];
//    CGPoint loc = [touch locationInView:self];
//    
//    // MT6: Record touch up (console does filtering)
//    [MonkeyTalk recordFrom:self command:MTCommandTouchUp args:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%1.0f", loc.x], 
//                                                                 [NSString stringWithFormat:@"%1.0f", loc.y],
//                                                                 nil]];
//}


@end
