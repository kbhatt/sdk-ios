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

#import "UIWebView+Selenium.h"
#import "MTWebViewController.h"
#import <objc/runtime.h>
#import "MonkeyTalk.h"
#import "NSString+MonkeyTalk.h"
#import "MTDefaultProperty.h"


@interface MTDefaultWebViewDelegate : NSObject <UIWebViewDelegate>
@end
@implementation MTDefaultWebViewDelegate
@end

@implementation UIWebView (Selenium)
+(void) load
{
    if (self == [UIWebView class]) {
        Method originalMethod = class_getInstanceMethod(self, @selector(setDelegate:));
        Method replacedMethod = class_getInstanceMethod(self, @selector(mtSetDelegate:));
        method_exchangeImplementations(originalMethod, replacedMethod);
    }
}

- (void) mtAssureAutomationInit {
	[super mtAssureAutomationInit];
	if (!self.delegate) {
		self.delegate = [[MTDefaultWebViewDelegate alloc] init];
	}
}

- (void) mtSetDelegate:(NSObject <UIWebViewDelegate>*) del {
    
    if ([self.delegate class] != [MTWebViewController class]) {
        MTWebViewController *webController = [[[MTWebViewController alloc] init] autorelease];
        
        // Set delController to call original delegate methods from webController
        webController.delController = del;
        
        // Set webView delegate to webController
        [self mtSetDelegate:webController];
        
//        self.accessibilityLabel = @"webView";
        
        // Set webController webView to user's webView
        webController.webView = self;
    }
}

+ (NSString *) formattedUrlString:(NSString *)url {
    if ([url rangeOfString:@"http://"].location != 0 &&
        [url rangeOfString:@"https://"].location != 0 &&
        [url rangeOfString:@"file://"].location != 0)
        url = [NSString stringWithFormat:@"http://%@",url];
    
    return url;
}

- (NSString *) valueForProperty:(NSString *)prop withArgs:(NSArray *)args {
    NSString* value;
    
    if ([prop isEqualToString:MTVerifyPropertyDefault ignoreCase:YES])
        value = [NSString stringWithFormat:@"%@",self.request.URL];
    else
        [NSException raise:@"Invalid keypath" format:@"invalid keypath"];
    
    return value;
}

- (void) playbackMonkeyEvent:(id)event {
    MTCommandEvent *commandEvent = (MTCommandEvent *)event;
    
    if ([commandEvent.command isEqualToString:MTCommandOpen ignoreCase:YES]) {
        if ([commandEvent.args count] != 1) {
            commandEvent.lastResult = [NSString stringWithFormat:@"Requires 1 argument, but has %d", [commandEvent.args count]];
            return;
        }
        
        NSString *formattedUrl = [[self class] formattedUrlString:
                                  [commandEvent.args objectAtIndex:0]];
        [self loadRequest:[NSURLRequest requestWithURL:
                           [NSURL URLWithString:formattedUrl]]];
    } else if ([commandEvent.command isEqualToString:MTCommandBack ignoreCase:YES]) {
        if (self.canGoBack)
            [self goBack];
        else
            commandEvent.lastResult = @"Browser cannot go back";
    } else if ([commandEvent.command isEqualToString:MTCommandForward ignoreCase:YES]) {
        if (self.canGoForward)
            [self goForward];
        else
            commandEvent.lastResult = @"Browser cannot go forward";
    } else
        [super playbackMonkeyEvent:event];
}

@end
