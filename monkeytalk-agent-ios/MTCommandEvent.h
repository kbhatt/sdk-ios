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
#import <UIKit/UIKit.h>
#import <Foundation/NSArray.h>

/**
 The MonkeyTalk command object used for recording and playback.
 */
@interface MTCommandEvent : NSObject <NSCopying> {

	UIView* source;
	NSString* command;
	NSString* className;
	NSString* monkeyID;
	NSString* playbackDelay;
    NSString* playbackTimeout;
	NSArray* args;
	NSMutableDictionary* dict;
	NSString* lastResult;
    NSString* value;
}
/**
 Create a new MTCommandEvent
*/
+ (MTCommandEvent*) command:(NSString*)cmd className:(NSString*)name monkeyID:(NSString*)id args:(NSArray*)array;
+ (MTCommandEvent*) command:(NSString*)cmd className:(NSString*)name monkeyID:(NSString*)id delay:(NSString *)playback timeout:(NSString *)timeout args:(NSArray*)array;
- (id) init:(NSString*)cmd className:(NSString*)className monkeyID:(NSString*)monkeyID args:(NSArray*)args;
- (id) init:(NSString*)cmd className:(NSString*)name monkeyID:(NSString*)id delay:(NSString *)playback timeout:(NSString *)timeout args:(NSArray*)array;
- (id) initWithDict:(NSMutableDictionary*)dict;
- (id) execute;
/**
 The component corresponding to the supplied className and monkeyID.
 */
@property (readonly) UIView* source;
@property (nonatomic, retain) NSString* command;
@property (nonatomic, retain) NSString* className;
@property (nonatomic, retain) NSString* monkeyID;
@property (nonatomic, retain) NSString* playbackDelay;
@property (nonatomic, retain) NSString* playbackTimeout;
@property (nonatomic, retain) NSString* lastResult;
@property (nonatomic, retain) NSArray* args;
@property (nonatomic, retain) NSMutableDictionary* dict;
@property (nonatomic, retain) NSString* value;
@end
