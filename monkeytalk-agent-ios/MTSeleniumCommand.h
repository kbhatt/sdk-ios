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

#import <Foundation/Foundation.h>
#import "MTCommandEvent.h"


@interface MTSeleniumCommand : NSObject {
    MTCommandEvent *mtEvent;
    NSString *xPath;
    NSString *alternateID;
    NSString *command;
    NSDictionary *args;
    NSInteger currentOrdinal;
    NSString *htmlTag;
}

@property (nonatomic, retain) MTCommandEvent *mtEvent;
@property (nonatomic, retain) NSString *xPath;
@property (nonatomic, retain) NSString *alternateID;
@property (nonatomic, retain) NSString *command;
@property (nonatomic, retain) NSDictionary *args;
@property (nonatomic, readwrite) NSInteger currentOrdinal;
@property (nonatomic, retain) NSString *htmlTag;

- (id) initWithMTCommandEvent:(MTCommandEvent *)event;
+ (NSString *)convertedFromCommand:(MTCommandEvent *)event;

@end
