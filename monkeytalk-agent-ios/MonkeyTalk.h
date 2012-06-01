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

#import "MTConstants.h"



#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MTCommandEvent;
@class SenTestSuite;

//@interface MonkeyTalk : UIApplication {

typedef enum  {
	MTStateSuspended,
	MTStatePaused,
	MTStateRecording,
	MTStatePlaying
} MTState;

@interface MonkeyTalk : NSObject {	

	NSTimeInterval runTimeout;
	MTState state;
	NSMutableArray* commands;
	NSMutableDictionary* session;
    NSArray* csvData;
    NSInteger csvIndex;
    NSDate* previousTime;
    NSMutableDictionary *replaceVars;
    BOOL isDriving;
    int retryCount;
    NSString *commandSpeed;
    BOOL isWireRecording;
    NSString *recordHost;
    NSString *recordPort;
    NSMutableArray *foundComponents;
    Boolean isAnimating;
    MTCommandEvent *currentCommand;
}	

+ (MonkeyTalk*) sharedMonkey;
- (void) play;
- (NSString*) playAndWait;
- (NSString*) runScript:(NSString*)script;
- (void) record;
- (void) continueMonitoring;
- (void) clear;
- (void) pause;	
- (void) suspend;
- (void) handleEvent:(UIEvent*) event;
+ (void) recordFrom:(UIView*)source command:(NSString*)command;
+ (void) recordFrom:(UIView*)source command:(NSString*)command args:(NSArray*)args;
- (void) postCommandFrom:(UIView*)sender command:(NSString*)command args:(NSArray*)args;
- (MTCommandEvent*)commandAt:(NSInteger)index;
- (NSUInteger) commandCount;
- (void) deleteCommand:(NSInteger) index;
- (void) insertCommand:(NSInteger) index;
- (MTCommandEvent*) lastCommand;
- (void) save:(NSString*)file;
- (void) delete:(NSString*)file;
- (void) open:(NSString*)file;
- (NSArray*) scripts;
- (NSInteger) firstErrorIndex;
- (void) moveCommand:(NSInteger)from to:(NSInteger)to;
- (MTCommandEvent*) lastCommandPosted;
- (MTCommandEvent*) popCommand;
- (NSString*) monkeyIDfor:(UIView*)view;
- (void) openConsole;
- (void) loadCommands:(NSArray*) cmds;
- (void) receivedRotate: (NSNotification*) notification;
+ (void) recordEvent:(MTCommandEvent*)event;
+ (BOOL) isRecording;
- (void) recordFrom:(UIView*)source command:(NSString*)command args:(NSArray*)args post:(BOOL)post;
@property (nonatomic, retain) NSMutableArray* commands;
@property (nonatomic, retain) NSMutableDictionary* session;
@property (nonatomic, retain) NSArray* csvData;
@property (nonatomic, retain) NSDate* previousTime;
@property NSTimeInterval runTimeout;
@property (readonly) MTState state;
@property (nonatomic, retain) NSString *commandSpeed;
@property (nonatomic, readwrite) BOOL isWireRecording;

@property (nonatomic, retain) NSString *recordHost;
@property (nonatomic, retain) NSString *recordPort;
@property (nonatomic, retain) NSMutableArray *foundComponents;
@property (nonatomic, readwrite) UIDeviceOrientation currentOrientation;
@property (nonatomic, readwrite) Boolean isAnimating;
@property (nonatomic, retain) MTCommandEvent *currentCommand;

- (void) saveOCScript:(NSString* ) filename;
- (void) saveUIAutomationScript:(NSString* ) filename;
- (void) saveQUnitScript:(NSString* ) filename;
- (void) playFrom:(NSUInteger)index;
- (NSString *) liveDelay;

- (void) playCommandFromJs:(MTCommandEvent*)command;
- (void) playingDone;

- (NSString *) playAndRespond:(MTCommandEvent*)nextCommandToRun;
+ (void) buildCommand:(MTCommandEvent*)event;
@end

