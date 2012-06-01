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

#import "UIScrollView+MTReady.h"
#import "MTUtils.h"
#import <objc/runtime.h>
#import "MonkeyTalk.h"
#import "MTCommandEvent.h"
#import "UIView+MTReady.h"
#import "UITableView+MTReady.h"
#import "NSString+MonkeyTalk.h"

#pragma mark UIScrollView delegate methods
@interface MTReadyUIScrollViewDelegate : NSObject <UIScrollViewDelegate> {
}
@end

@implementation MTReadyUIScrollViewDelegate
- (void)scrollViewWillBeginDragging_defaultImp:(UIScrollView *)scrollView {}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self scrollViewWillBeginDragging_defaultImp:scrollView];
}
- (void)scrollViewDidEndDragging_defaultImp:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[self scrollViewDidEndDragging_defaultImp:scrollView willDecelerate:decelerate];
}
@end
#pragma mark -

@implementation UIScrollView (MTReady)

- (BOOL) isMTEnabled {
	return YES;
}

+ (void)load {
    if (self == [UIScrollView class]) {
		//[self interceptMethod:@selector(setDelegate:) withClass:self types:"v@:@"];
        Method originalMethod = class_getInstanceMethod(self, @selector(setContentOffset:));
        Method replacedMethod = class_getInstanceMethod(self, @selector(mtSetContentOffset:));
        method_exchangeImplementations(originalMethod, replacedMethod);		
		
//		originalMethod = class_getInstanceMethod(self, @selector(setDelegate:));
//        replacedMethod = class_getInstanceMethod(self, @selector(mtSetDelegate:));
//        method_exchangeImplementations(originalMethod, replacedMethod);		
		
    }
}

//- (void) mt_setDelegate:(id <UIScrollViewDelegate>) del {
//	[self orig_setDelegate:del];
//}

-(void) assureDelegate {
	if (self.delegate==nil) { 
		MTReadyUIScrollViewDelegate* del= [[MTReadyUIScrollViewDelegate alloc]init];
		self.delegate=del;
	}
}

- (void)mtSetContentOffset:(CGPoint)offset {
	//[self assureDelegate];
	
	if (!self.dragging || (offset.x == self.contentOffset.x && offset.y == self.contentOffset.y)) {
		[self mtSetContentOffset:offset];
		return;
	}
	
	// offsets are apparently stored as whole-valued floats. We round so that direction determination (up, down, left, right) works
	offset.x = round(offset.x);
	offset.y = round(offset.y);
//	NSLog(@"new:%d,%d prev:%d,%d",offset.x,offset.y,self.contentOffset.x, self.contentOffset.y);	
	// Bouncing screws up delta checking so we're disabling and we'll see if anybody cares
    
//	if (self.bounces) {
//		self.bounces = NO;
//	}
    
    // Do not record scroll on UIPickerTableView
    if ([self isKindOfClass:objc_getClass("UIPickerTableView")] ||
        [self.superview isKindOfClass:[UIWebView class]]) {
        [self mtSetContentOffset:offset];
        return;
    }

	
	// Since it's unclear exactly how to do this in a subclass (override a swapped method), we do it here instead (sorry)
	if ([self isKindOfClass:[UITableView class]]) {
		[self mtSetContentOffset:offset];		
		UITableView* table = (UITableView*) self;
		NSArray* cells = [table visibleCells];
        
        // Handle pull to refresh behavior by recording scroll on table view
        // if the y offset is negative, otherwise record scroll to row
        if (offset.y >= 0) {
            if ([cells count]) {
                UITableViewCell *topCell = (UITableViewCell *)[cells objectAtIndex:0];
                NSIndexPath* indexPath = [table indexPathForCell:topCell];
                NSArray *recordArray = [NSArray 
                                        arrayWithObjects:
                                        [NSString stringWithFormat:@"%d", indexPath.row+1], 
                                        indexPath.section == 0 ? nil : [NSString stringWithFormat:@"%d", indexPath.section], nil];
                
                // Record index path and not text label for now
//                if ([topCell.textLabel.text length] > 0)
//                    recordArray = [NSArray arrayWithObject:topCell.textLabel.text];
//                else
//                    recordArray = [NSArray 
//                                   arrayWithObjects:
//                                   [NSString stringWithFormat:@"%d", indexPath.row+1], 
//                                   indexPath.section == 0 ? nil : [NSString stringWithFormat:@"%d", indexPath.section], nil];
                
                // Record table view scroll to row
                [[MonkeyTalk sharedMonkey] postCommandFrom:self 
                                                   command:MTCommandScrollToRow 
                                                      args:recordArray];		
                return;
            }
        }
	}
	
	
//	if (offset.x == self.contentOffset.x) {
//		if (offset.y >  self.contentOffset.y) {		
//			cmd = MTCommandScrollDown;
//		} else {			
//			cmd = MTCommandScrollUp;
//		}
//		[[MonkeyTalk sharedMonkey] postCommandFrom:self 
//										   command:cmd 
//											  args:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%1.0f", offset.y], nil]];		
//	} else if (offset.y == self.contentOffset.y) {
//		if (offset.x >  self.contentOffset.x) {
//			cmd = MTCommandScrollRight;
//		} else {
//			cmd = MTCommandScrollLeft;
//		}
//		[[MonkeyTalk sharedMonkey] postCommandFrom:self 
//										   command:cmd 
//											  args:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%1.0f", offset.x], nil]];		
//	} else {
	
		UIView* currentItem = [self subviewAtContentOffset:offset];
		NSString* elementMonkeyID = nil;
        NSString* elementAccID = nil;
		if (currentItem!=nil) {
			elementMonkeyID = currentItem.accessibilityLabel;
            
            // Make sure accessibilityIdentifier available selector
            if ([currentItem respondsToSelector:@selector(accessibilityIdentifier)])
                elementAccID = [currentItem accessibilityIdentifier];
            
			if (elementAccID==nil || elementAccID.length==0){
                elementAccID = currentItem.monkeyID;
            } else if (elementMonkeyID==nil || elementMonkeyID.length==0) { 
				elementMonkeyID = currentItem.monkeyID;
			}
		}
		[[MonkeyTalk sharedMonkey] postCommandFrom:self 
										   command:MTCommandScroll 
											  args:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%1.0f", offset.x], 
																			[NSString stringWithFormat:@"%1.0f", offset.y],
																			nil]];
	
//	}
	[self mtSetContentOffset:offset];

}

- (void) playbackMonkeyEvent:(MTCommandEvent*)event {
	CGPoint offset = [self contentOffset];
	if ([event.command isEqualToString:MTCommandScroll ignoreCase:YES]) {
		if ([event.args count] < 2) {
			event.lastResult = @"Requires 2 arguments, but has %d", [event.args count];
		}
		offset.x = [[[event args] objectAtIndex:0] floatValue];	
		offset.y = [[[event args] objectAtIndex:1] floatValue];	
	} else {
		[super playbackMonkeyEvent:event];
		return;
	}
    
    if ([self.delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)])
        [self.delegate scrollViewWillBeginDragging:self];
    
    [MonkeyTalk sharedMonkey].isAnimating = YES;
	[self setContentOffset:offset animated:YES];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Sleep while setContentOffset is animating
        [NSThread sleepForTimeInterval:0.33];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MonkeyTalk sharedMonkey].isAnimating = NO;
            if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
                [self.delegate scrollViewDidEndDragging:self willDecelerate:NO];
            
            if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)])
                [self.delegate scrollViewDidEndDecelerating:self];
            
            if ([self.delegate respondsToSelector:@selector(scrollViewDidScroll:)])
                [self.delegate scrollViewDidScroll:self];
        }); 
    });
}

+ (NSString*) uiAutomationCommand:(MTCommandEvent*)command {
	NSMutableString* string = [[NSMutableString alloc] init];
	if ([command.command isEqualToString:MTCommandScroll]) {
		NSString* x = [command.args count] < 1 ? @"0" : [command.args objectAtIndex:0];
		NSString* y = [command.args count] < 2 ? @"0" : [command.args objectAtIndex:1];
		//NSString* hitTestViewName = [command.args count] < 3 ? @"" : [command.args objectAtIndex:2];
		// handle this with drag...
		[string appendFormat:@" // Scroll \"%@\" to (%d,%d) - MonkeyTalk cannot yet generate the corresponding UIAutomation command. You must manually create the necessary scrolling command.", 
				[MTUtils stringByJsEscapingQuotesAndNewlines:command.monkeyID], 
				[MTUtils stringByJsEscapingQuotesAndNewlines:x],
				[MTUtils stringByJsEscapingQuotesAndNewlines:y]
		 //,[MTUtils stringByJsEscapingQuotesAndNewlines:hitTestViewName]
		 ];
		
	} else {
		[string appendString:[super uiAutomationCommand:command]];
	}
	return string;
}

- (BOOL) shouldRecordMonkeyTouch:(UITouch*)touch {
	return NO;
}
								
- (UIView*) subviewAtContentOffset:(CGPoint) offset {
	return [self subviewAtContentOffset:offset inView:self];
}

- (UIView*) subviewAtContentOffset:(CGPoint)offset inView:(UIView*)view {
	/*
	UIView* rez=nil;
	NSArray* kids=view.subviews;
	NSLog(@"testing content offset at %f, %f", offset.x, offset.y);	
	NSLog(@"found %d kids", kids.count);
	int i=0;
	for (UIView * kid in kids) {
		i++;
		NSLog(@"kid %d is a %@ with frame x=%f y=%f w=%f h=%f", i, NSStringFromClass([kid class]), kid.frame.origin.x, kid.frame.origin.y, kid.frame.size.width, kid.frame.size.height );
		if (!kid.hidden && [kid pointInside:offset withEvent:nil]) {
			rez=kid;
			CGPoint newOffset;
			newOffset.x = offset.x - rez.frame.origin.x;
			newOffset.y = offset.y - rez.frame.origin.y;
			UIView* nestedRez = [self subviewAtContentOffset:newOffset inView:rez];
			if (nestedRez != nil) {
				rez=nestedRez;
			}
		}
    }
	return rez;
	 */
	UIView* rez = [view hitTest:offset withEvent:nil];;
	// NSLog(@"testing content offset at %f, %f", offset.x, offset.y);	
	if (rez!=nil) {
		// NSLog(@"it's a %@ with frame x=%f y=%f w=%f h=%f",NSStringFromClass([rez class]), rez.frame.origin.x, rez.frame.origin.y, rez.frame.size.width, rez.frame.size.height );
	} else {
		// NSLog(@"it's nil");
	}
	return rez;
}

- (id <UIScrollViewDelegate>)mtReadyZapDelegate:(id <UIScrollViewDelegate>)del {
	Class clazz = [del class];
	
	SEL targetSelector = @selector(scrollViewWillBeginDragging:);
	Method replacementMethod = class_getInstanceMethod([self class],@selector(mtScrollViewWillBeginDragging:));
	SEL saveOriginalAs = @selector(mtOrigScrollViewWillBeginDragging:);
	Method defaultMethod = class_getInstanceMethod([MTReadyUIScrollViewDelegate class], @selector(scrollViewWillBeginDragging_defaultImp:));
	[self zapInstanceMethodForClass:clazz 
									targetSelector:targetSelector
									withReplacement:replacementMethod
									saveOriginalAs:saveOriginalAs
									defaultIfNotFound:defaultMethod];

	targetSelector = @selector(scrollViewDidEndDragging:willDecelerate:);
	replacementMethod = class_getInstanceMethod([self class],@selector(mtScrollViewDidEndDragging:willDecelerate:));
	saveOriginalAs = @selector(mtOrigScrollViewDidEndDragging:willDecelerate:);
	defaultMethod = class_getInstanceMethod([MTReadyUIScrollViewDelegate class], @selector(scrollViewDidEndDragging_defaultImp:willDecelerate:));
	[self zapInstanceMethodForClass:clazz 
					 targetSelector:targetSelector
					withReplacement:replacementMethod
					 saveOriginalAs:saveOriginalAs
				  defaultIfNotFound:defaultMethod];
	return del;
}


- (void)zapInstanceMethodForClass:(Class)clazz targetSelector:(SEL)targetSelector withReplacement:(Method)replacedMethod 
				   saveOriginalAs:(SEL)saveAsSelector defaultIfNotFound:(Method)defaultMethod {
	Method saveAsMethod = class_getInstanceMethod(clazz, saveAsSelector);
	if (!saveAsMethod) {
		IMP replImp = method_getImplementation(replacedMethod);		
		Method originalMethod = class_getInstanceMethod(clazz,targetSelector);
		if (originalMethod) {
//			NSLog(@"-- --- -- - ------ -- - zapping method in class %@", NSStringFromClass(clazz));	
			const char* typeEncoding = method_getTypeEncoding(originalMethod);
			IMP origImp = method_getImplementation(originalMethod);
			
			if (origImp != replImp) {
				method_setImplementation(originalMethod, replImp);
				
				class_addMethod(clazz, saveAsSelector, origImp, typeEncoding);
			}
		} else {
//			NSLog(@"-- --- -- - ------ -- - original method not found in class %@", NSStringFromClass(clazz));	
			if (defaultMethod) {
//				NSLog(@"-- --- -- - ------ -- - using default method");	
				IMP defaultImp = method_getImplementation(defaultMethod);
				const char* typeEncoding = method_getTypeEncoding(originalMethod);
				class_addMethod(clazz, targetSelector, replImp, typeEncoding);
				class_addMethod(clazz, saveAsSelector, defaultImp, typeEncoding);
			}
		}
	} else {
//		NSLog(@"-- --- -- - ------ -- - had already zapped class %@", NSStringFromClass(clazz));	
	}
}

- (void)mtScrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// NSLog(@" ### AAA ### ### ### ### ### ### ### ### UIScrollView+MTReady::mtScrollViewWillBeginDragging called");
//	[MTUtils setShouldRecordMonkeyTouch:YES forView:scrollView];
	[self mtOrigScrollViewWillBeginDragging:scrollView];
}
- (void)mtScrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	// NSLog(@" ### BBB ### ### ### ### ### ### ### ### UIScrollView+MTReady::mtScrollViewDidEndDragging called");
//	[MTUtils setShouldRecordMonkeyTouch:NO forView:self];
	[self mtOrigScrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void) mtSetDelegate:(id <UIScrollViewDelegate>) del {
	[self mtReadyZapDelegate:del];
	[self mtSetDelegate:del];
}

@end
