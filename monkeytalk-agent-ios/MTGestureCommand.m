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

#import "MTGestureCommand.h"
#import "MonkeyTalk.h"
#import "UIGestureRecognizerProxy.h"
#import "UIGestureRecognizerTargetProxy.h"
#import "UIPinchGestureRecognizerProxy.h"
#import "NSString+MonkeyTalk.h"

@implementation MTGestureCommand
+ (void) handleSwipe:(MTCommandEvent *)ev {
    UIView *swipeView = ev.source;
    NSString *directionString = MTSwipeDirectionRight;
    
    if ([ev.args count] > 0)
        // If no args — default to Right swipe
        directionString = [ev.args objectAtIndex:0];
    
    
    for (UIGestureRecognizer* gr in swipeView.gestureRecognizers) {
        if ([gr isKindOfClass:[UISwipeGestureRecognizer class]]) {
            UIGestureRecognizerProxy *grProxy = (UIGestureRecognizerProxy *)gr;
            UISwipeGestureRecognizer *swipe = (UISwipeGestureRecognizer *)gr;
            NSString *foundSwipe;
            
            if (swipe.direction == UISwipeGestureRecognizerDirectionUp)
                foundSwipe = MTSwipeDirectionUp;
            else if (swipe.direction == UISwipeGestureRecognizerDirectionDown)
                foundSwipe = MTSwipeDirectionDown;
            else if (swipe.direction == UISwipeGestureRecognizerDirectionLeft)
                foundSwipe = MTSwipeDirectionLeft;
            else
                foundSwipe = MTSwipeDirectionRight;
            
            if ([foundSwipe isEqualToString:directionString ignoreCase:YES]) {
                for (int i = 0; i < [grProxy->_targets count]; i++) {
                    UIGestureRecognizerTargetProxy *targetProxy = [grProxy->_targets objectAtIndex:i];
                    
                    id target = targetProxy->_target;
                    SEL selector = targetProxy->_action;
                    
                    [target performSelectorOnMainThread:selector withObject:nil waitUntilDone:NO];
                }
            }
        }
    }
}

+ (void) handlePinch:(MTCommandEvent *)ev {
    UIView *pinchView = ev.source;
    
    if ([ev.args count] < 2) {
        // If no args — default to Right swipe
        ev.lastResult = @"Pinch action requires 2 args (scale | velocity)";
        return;
    }
    
    
    for (UIGestureRecognizer* gr in pinchView.gestureRecognizers) {
        if ([gr isKindOfClass:[UIPinchGestureRecognizer class]]) {
            UIGestureRecognizerProxy *grProxy = (UIGestureRecognizerProxy *)gr;
            UIPinchGestureRecognizerProxy *pinch = [[UIPinchGestureRecognizerProxy alloc] initWithVelocity:[[ev.args objectAtIndex:1] floatValue] forGesture:gr];
            
            pinch.scale = [[ev.args objectAtIndex:0] floatValue];
//            pinch.velocity = [[ev.args objectAtIndex:1] floatValue];
            
            for (int i = 0; i < [grProxy->_targets count]; i++) {
                UIGestureRecognizerTargetProxy *targetProxy = [grProxy->_targets objectAtIndex:i];
                
                id target = targetProxy->_target;
                SEL selector = targetProxy->_action;
                
                [target performSelectorOnMainThread:selector withObject:pinch waitUntilDone:NO];
            }
        }
    }
}
@end
