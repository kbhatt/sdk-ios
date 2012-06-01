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

#import "MTCommandEvent.h"
#import "MTUtils.h"

@implementation MTCommandEvent

//@synthesize source, command, className, monkeyID, args, dict;
@synthesize dict;

- (id) init {
	if (self = [super init]) {
		dict = [[NSMutableDictionary alloc] initWithCapacity:6];
		[self setCommand:@"Verify"];
		[self setMonkeyID:@""];
        [self setPlaybackDelay:@""];
        [self setPlaybackTimeout:@""];
		[self setClassName:@""];
		[self setArgs:[NSMutableArray arrayWithCapacity:1]];
	}
	
	return self;
}


- (id) init:(NSString*)cmd className:(NSString*)name monkeyID:(NSString*)id args:(NSArray*)array {
	self = [self init];
	self.command = cmd;
	self.className = name;
	self.monkeyID = id;
    self.playbackDelay = [NSString stringWithFormat:@"%g",MT_DEFAULT_THINKTIME];
    self.playbackTimeout = [NSString stringWithFormat:@"%i",MT_DEFAULT_TIMEOUT];
	self.args = array;
	return self;
}

- (id) init:(NSString*)cmd className:(NSString*)name monkeyID:(NSString*)id delay:(NSString *)playback timeout:(NSString *)timeout args:(NSArray*)array {
	self = [self init];
    
	self.command = cmd;
	self.className = name;
	self.monkeyID = id;
    self.value = nil;
    
    if (playback)
        self.playbackDelay = playback;
    else
        self.playbackDelay = [NSString stringWithFormat:@"%i",MT_DEFAULT_THINKTIME];
    
    if (timeout)
        self.playbackTimeout = timeout;
    else
        self.playbackTimeout = [NSString stringWithFormat:@"%i",MT_DEFAULT_TIMEOUT];
    
	self.args = array;
	return self;
}

+ (MTCommandEvent*) command:(NSString*)cmd className:(NSString*)name monkeyID:(NSString*)id args:(NSArray*)array {
	return [[[MTCommandEvent alloc] init:cmd className:name monkeyID:id args:array] autorelease];
}

+ (MTCommandEvent*) command:(NSString*)cmd className:(NSString*)name monkeyID:(NSString*)id delay:(NSString *)playback timeout:(NSString *)timeout args:(NSArray*)array {
	return [[[MTCommandEvent alloc] init:cmd className:name monkeyID:id delay:playback timeout:timeout args:array] autorelease];
}

// protocl NSCopying
- (id) copyWithZone:(NSZone*)zone {
	return [MTCommandEvent command:self.command className:self.className monkeyID:self.monkeyID args:self.args];
}

- (id) initWithDict:(NSMutableDictionary*)dictionary {
	if (self = [super init]) {
		self.dict = dictionary;
	}

	return self;
}

- (UIView*) source {
    NSString *sourceClass = self.className;
    NSString *sourceId = self.monkeyID;
    
    if ([sourceClass isEqualToString:@"Script"]) {
        NSString *argsString = [self.args componentsJoinedByString:@" "];
        if ([argsString hasSuffix:@".html"])
            sourceClass = @"UIWebView";
    } 
    
	UIView* v = [MTUtils viewWithCommandEvent:self];
	if (v) {
		return v;
	}
	// Search again considering classes that can be swapped with the supplied class (ie, UIToolbarTextButton and UINavigationButton)
	return [MTUtils viewWithMonkeyID:sourceId startingFromView:nil havingClass:NSClassFromString(sourceClass) swapsOK:YES];
}

- (void) set:(NSString*)key value:(NSObject*)value {
	if (value == nil) {
		[dict removeObjectForKey:key];
		return;
	}
	[dict setObject:value forKey:key];
}

- (NSString*) command {
	return [dict objectForKey:@"command"];
}

- (void) setCommand:(NSString*)value {
	[self set:@"command" value:value];
}

- (NSString*) monkeyID {
	return [dict objectForKey:@"monkeyID"];

}
- (void) setMonkeyID:(NSString*)value {
	[self set:@"monkeyID" value:value];
}

- (NSString*) playbackDelay {
	return [dict objectForKey:@"playbackDelay"];
    
}
- (void) setPlaybackDelay:(NSString*)value {
	[self set:@"playbackDelay" value:value];
}

- (NSString*) playbackTimeout {
	return [dict objectForKey:@"playbackTimeout"];
    
}
- (void) setPlaybackTimeout:(NSString*)value {
	[self set:@"playbackTimeout" value:value];
}


- (NSString*) className {
	return [dict objectForKey:@"className"];
}

- (void) setClassName:(NSString*)value {
	[self set:@"className" value:value];
}


- (NSArray*) args {
	return [dict objectForKey:@"args"];
}
	
- (void) setArgs:(NSArray*)value {
	[self set:@"args" value:value];
}

- (NSString*) lastResult {
	return [dict objectForKey:@"lastResult"];
}

- (void) setLastResult:(NSString*)value {
	[self set:@"lastResult" value:value];
}

- (id) execute {
	return nil;
}

- (NSString*) value {
	return [dict objectForKey:@"value"];
}

- (void) setValue:(NSString*)value {
	[self set:@"value" value:value];
}



- (void) dealloc {
//	[source release];
//	[command release];
//	[monkeyID release];
//	[className release];
//	[args release];
	[dict release];
	[super dealloc];
}

@end
