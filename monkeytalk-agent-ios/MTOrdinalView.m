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

#import "MTOrdinalView.h"
#import "MTUtils.h"
#import "MonkeyTalk.h"
#import "NSString+MonkeyTalk.h"
#import "MTWebViewController.h"


@implementation MTOrdinalView

+ (UIView*) buildFoundComponentsStartingFromView:(UIView*)current havingClass:(NSString *)classString {
    Class class = objc_getClass([classString UTF8String]);
    
    if (!current) {
		current =  [MTUtils rootWindow];
	}
    
    NSString *currentClassString = [NSString stringWithFormat:@"%@",[current class]];
    
    if (classString == nil) { 
        return current;
    }
    
    BOOL isButton = [MTUtils shouldRecord:classString view:current];
    
    if ([classString isEqualToString:@"mtcomponenttree" ignoreCase:YES] ||
        [current isKindOfClass:[UIWebView class]]) {
        if (![MonkeyTalk sharedMonkey].foundComponents) {
            [MonkeyTalk sharedMonkey].foundComponents = [[NSMutableArray alloc] init];
        }
        
        [[MonkeyTalk sharedMonkey].foundComponents addObject:current];
    } else if ( (classString != nil && ([current isKindOfClass:class] || isButton))) {
        //            NSLog(@"return current object: %i",[self ordinalForView:current]);
        
        // Build array with components of class looking for
        // UILabel must be exact class
        if ([currentClassString isEqualToString:classString] || 
            ![classString isEqualToString:@"UILabel"] || 
            [classString isEqualToString:@"itemselector" ignoreCase:YES] || 
            [classString isEqualToString:@"indexedselector" ignoreCase:YES]) {
            if (![MonkeyTalk sharedMonkey].foundComponents) {
                [MonkeyTalk sharedMonkey].foundComponents = [[NSMutableArray alloc] init];
            }
            
            [[MonkeyTalk sharedMonkey].foundComponents addObject:current];
        }
    }
	
	if (!current.subviews) {
		return nil;
	}
	
    for (UIView* view in [[current.subviews reverseObjectEnumerator] allObjects]) {
        //	for (UIView* view in [current.subviews allObjects]) {
		UIView* result;
		if (result = [self buildFoundComponentsStartingFromView:view havingClass:classString]) {
			return result;
		}
		
	}
    
    return nil;
}

+ (void) sortFoundComponents {
    if ([[MonkeyTalk sharedMonkey].foundComponents count] > 0) {
        [[MonkeyTalk sharedMonkey].foundComponents sortUsingComparator:  
         ^NSComparisonResult (id obj1, id obj2) {  
             UIView *view1 = (UIView *)obj1;
             UIView *view2 = (UIView *)obj2;
             CGPoint point1 = [view1 convertPoint:view1.frame.origin toView:nil];
             CGPoint point2 = [view2 convertPoint:view2.frame.origin toView:nil];  
             
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
}

+ (UIView *) viewWithOrdinal:(NSInteger)ordinal startingFromView:(UIView *)current havingClass:(NSString *)classString {
    
    // Find all components of class
    [[self class] buildFoundComponentsStartingFromView:current 
                                           havingClass:classString];
    
    // Order components based on position on screen
    [[self class] sortFoundComponents];
    
    @try {
        MTWebViewController *webDriver = nil;
        for (int i = 0; [[MonkeyTalk sharedMonkey].foundComponents count]; i++) {
            UIView *view = [[MonkeyTalk sharedMonkey].foundComponents objectAtIndex:i];
            NSInteger webCount = 0;
            if ([view isKindOfClass:[UIWebView class]]) {
                // Search for ordinal in webview
                // Search i+1
                
                UIWebView *webView = (UIWebView *)view;
                
                webDriver = (MTWebViewController *)webView.delegate;
                
                if (webDriver) {
                    webDriver.currentOrdinal = i;
                    if ([webDriver playBackCommandInWebView:[MonkeyTalk sharedMonkey].currentCommand])
                        return [[MTFoundElement alloc] init];
                }
            } else if (webDriver && i == ordinal-webDriver.currentOrdinal) {
                [MonkeyTalk sharedMonkey].currentCommand.lastResult = nil;
                return [[MonkeyTalk sharedMonkey].foundComponents objectAtIndex:i];
            } else if (ordinal > 0 && i == ordinal-1)
                return [[MonkeyTalk sharedMonkey].foundComponents objectAtIndex:i];
        }
    }
    @catch (NSException *exception) {
        // Handle error
    }
    
    return nil;
}

@end
