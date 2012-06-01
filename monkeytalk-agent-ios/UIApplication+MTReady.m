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

#import "UIApplication+MTReady.h"
#import <objc/runtime.h>
#import "UIView+MTReady.h"
#import "MonkeyTalk.h"
#import "MTUtils.h"


@implementation UIApplication (MTReady)

+ (void)load {
	if (self == [UIApplication class]) {
		NSLog(@"Loading MonkeyTalk...");
		
        Method originalMethod = class_getInstanceMethod(self, @selector(sendEvent:));
        Method replacedMethod = class_getInstanceMethod(self, @selector(mtSendEvent:));
        method_exchangeImplementations(originalMethod, replacedMethod);
		[[NSNotificationCenter defaultCenter] addObserver:self	
												 selector:@selector(initTheMonkey:)
													 name:UIApplicationDidFinishLaunchingNotification object:nil];
	
	}
}

+ (void) initTheMonkey:(NSNotification*)notification {

	[[MonkeyTalk sharedMonkey] open];
	
	
}



- (void)mtSendEvent:(UIEvent *)event {
	[[MonkeyTalk sharedMonkey] handleEvent:event];
	
	// Call the original
	[self mtSendEvent:event];

	
}


@end
