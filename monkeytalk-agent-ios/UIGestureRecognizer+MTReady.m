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

#import "UIGestureRecognizer+MTReady.h"
#import "MonkeyTalk.h"
#import "MTCommandEvent.h"
#import "MTUtils.h"
#import <objc/runtime.h>
#import "MTUtils.h"
#import "UIView+MTReady.h"
#import "UIGestureRecognizerProxy.h"

@interface MTDefaultGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>
@end
@implementation MTDefaultGestureRecognizerDelegate
@end

@implementation UIGestureRecognizer (MTReady)
+ (void)load {
    if (self == [UIGestureRecognizer class]) {
        Method originalMethod = class_getInstanceMethod(self, @selector(initWithTarget:action:));
        Method replacedMethod = class_getInstanceMethod(self, @selector(mtinitWithTarget:action:));
        method_exchangeImplementations(originalMethod, replacedMethod);	
    }
}

- (void) mtreplaceAction:(UIGestureRecognizer *)recognizer {
    NSString *objectString = [NSString stringWithFormat:@"%@",recognizer];
    NSArray *replaceStrings = [NSArray arrayWithObjects:@"\n",@"\"",@" ",@"(",@")", nil];
    
    for (NSString *string in replaceStrings)
        objectString = [objectString stringByReplacingOccurrencesOfString:string withString:@""];
    
    
    NSArray *array = [objectString componentsSeparatedByString:@";"];
    
    for (NSString *string in array) {
        if ([string rangeOfString:@"target="].location != NSNotFound) {
            string = [string stringByReplacingOccurrencesOfString:@"=<" withString:@","];
        }
    }
    
    if ([self isKindOfClass:[UISwipeGestureRecognizer class]]) {
        UISwipeGestureRecognizer *swipeRecognizer = (UISwipeGestureRecognizer *)recognizer;
        NSLog(@"ACTION_INTERCEPTED: %i %i",swipeRecognizer.direction, UISwipeGestureRecognizerDirectionDown);
        NSString *directionString = nil;
        
        if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionUp)
            directionString = MTSwipeDirectionUp;
        else if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionDown)
            directionString = MTSwipeDirectionDown;
        else if (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionLeft)
            directionString = MTSwipeDirectionLeft;
        else
            directionString = MTSwipeDirectionRight;
        
        [MonkeyTalk recordFrom:swipeRecognizer.view 
                       command:MTCommandSwipe args:[NSArray arrayWithObject:directionString]];
    } else if ([self isKindOfClass:[UIPinchGestureRecognizer class]]) {
        UIPinchGestureRecognizer *pinchRecognizer = (UIPinchGestureRecognizer *)recognizer;
        NSString *scaleString = [NSString stringWithFormat:@"%0.2f",pinchRecognizer.scale];
        NSString *velocityString = [NSString stringWithFormat:@"%0.2f",pinchRecognizer.velocity];
        NSArray *args = [NSArray arrayWithObjects:scaleString, velocityString, nil];
        
        [MonkeyTalk recordFrom:pinchRecognizer.view 
                       command:MTCommandPinch args:[NSArray arrayWithObjects:scaleString, velocityString, nil]];
        
//        MTCommandEvent *pinchEvent = [[MTCommandEvent alloc]
//                                     init:MTCommandPinch className:[NSString stringWithUTF8String:class_getName([pinchRecognizer.view class])]
//                                     monkeyID:[pinchRecognizer.view monkeyID]
//                                     args:args];
//        
//        [MonkeyTalk buildCommand:pinchEvent];
    }
    //    [self mtreplaceAction];
}

- (id) mtinitWithTarget:(id)target action:(SEL)action {
    self = [self mtinitWithTarget:target action:action];
    
//    NSLog(@"GestureClasses: %@",[self class]);

    if ([self isKindOfClass:[UISwipeGestureRecognizer class]] ||
        [self isKindOfClass:[UIPinchGestureRecognizer class]] ||
        [self isKindOfClass:[UILongPressGestureRecognizer class]])
        [self addTarget:self action:@selector(mtreplaceAction:)];
    
    return self;
}
@end
