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

#import "UIDatePicker+MTReady.h"
#import "MTCommandEvent.h"
#import "MTUtils.h"
#import <objc/runtime.h>
#import "MonkeyTalk.h"
#import "NSString+MonkeyTalk.h"

@implementation UIDatePicker (MTReady)

+ (void)load {
    if (self == [UIDatePicker class]) {

        Method originalInitFrame = class_getInstanceMethod(self, @selector(initWithFrame:));
        Method replacedInitFrame = class_getInstanceMethod(self, @selector(mtinitWithFrame:));
        Method originalInitCoder = class_getInstanceMethod(self, @selector(initWithCoder:));
        Method replacedInitCoder = class_getInstanceMethod(self, @selector(mtinitWithCoder:));

        method_exchangeImplementations(originalInitFrame, replacedInitFrame);
        method_exchangeImplementations(originalInitCoder, replacedInitCoder);
    }
}

- (void) playbackMonkeyEvent:(MTCommandEvent*)event {
    if ([event.command isEqualToString:MTCommandEnterDate ignoreCase:YES]) {
        if ([event.args count] == 0) {
            event.lastResult = @"EnterDate requires 1 arg (\"YYYY-MM-DD\")";
            return;
        }
        
        @try {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd"];
//            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            NSDate *date = [dateFormatter dateFromString:[event.args objectAtIndex:0]];
            [self setDate:date animated:YES];
            [dateFormatter release];
        }
        @catch (NSException *exception) {
            event.lastResult = @"Error entering date (check the format: \"YYYY-MM-DD\")";
            return;
        }
    }
}

- (void) mtDateChanged {
//    NSLog(@"Date: %@\nCountDownDuration: %f\n MinInterval: %i\nMode: %i", self.date, 
//          self.countDownDuration, self.minuteInterval,self.datePickerMode);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
//    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    // For now only record date picker with Month/Day/Year
    if (self.datePickerMode = UIDatePickerModeDate)
        [[MonkeyTalk sharedMonkey] postCommandFrom:self 
                                       command:MTCommandEnterDate 
                                          args:[NSArray arrayWithObject:[dateFormatter stringFromDate:self.date]]];
    
    [dateFormatter release];
}

- (void) mtsetDate:(NSDate *)date animated:(BOOL)animated {
    [self mtsetDate:date animated:animated];
}

- (id) mtinitWithFrame:(CGRect)frame {
    self = [self mtinitWithFrame:frame];
    [self addTarget:self action:@selector(mtDateChanged) forControlEvents:UIControlEventValueChanged];
    return self;
}

- (id) mtinitWithCoder:(NSCoder *)aDecoder {
    self = [self mtinitWithCoder:aDecoder];
    [self addTarget:self action:@selector(mtDateChanged) forControlEvents:UIControlEventValueChanged];
    return self;
}

@end
