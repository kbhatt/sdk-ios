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

#import "MTWaitForCommand.h"
#import "MTCommandEvent.h"
#import "MTVerifyCommand.h"
#include <unistd.h>

@implementation MTWaitForCommand
+ (NSString*) execute:(MTCommandEvent*) ev {
	NSInteger interval = 500000;
	MTCommandEvent* verifyEvent = ev;
	if ([ev.args count] > 0) {
		NSString* arg0 = [ev.args objectAtIndex:0];
		if ([arg0 rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location==0) { // starts with a digit
			NSInteger msecs = [((NSString*)[ev.args objectAtIndex:0]) intValue];
			interval = msecs*100;
			NSMutableArray* newArgs = [NSMutableArray arrayWithArray:ev.args];
			[newArgs removeObjectAtIndex:0];
			verifyEvent = [ev copyWithZone:nil];
			verifyEvent.args = newArgs;
		}
	}
	int i = 0;
	do {
        if (i) {
            usleep(interval);
        }
        ev.lastResult = [MTVerifyCommand execute:verifyEvent isVerifyNot:NO]; 
        
        i++;
    } while (i < 10 && [ev lastResult]);
    return ev.lastResult;

}

@end
