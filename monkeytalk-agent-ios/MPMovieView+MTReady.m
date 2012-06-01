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

#import "MPMovieView+MTReady.h"
#import "MonkeyTalk.h"
#import "MTCommandEvent.h"
#import "NSString+MonkeyTalk.h"

@implementation MPMovieView (MTReady)

+ (void) load {
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(changed:) 
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    
}

+ (void) changed:(NSNotification *)notification{
    MPMoviePlayerController* controller = (MPMoviePlayerController *)[notification object];
    
    MPMovieView *mpView = (MPMovieView *)controller.view;
    
    if ([controller playbackState] == MPMoviePlaybackStatePlaying)
//        [MonkeyTalk recordFrom:mpView command:MTCommandPlayMovie args:[NSArray arrayWithObject:[NSString stringWithFormat:@"%1.3f", controller.currentPlaybackTime]]];
        [MonkeyTalk recordFrom:mpView command:MTCommandPlayMovie args:nil];
    else if ([controller playbackState] == MPMoviePlaybackStatePaused)
//        [MonkeyTalk recordFrom:mpView command:MTCommandPauseMovie args:[NSArray arrayWithObject:[NSString stringWithFormat:@"%1.3f", controller.currentPlaybackTime]]];
        [MonkeyTalk recordFrom:mpView command:MTCommandPauseMovie args:nil];
}

- (void) playbackMonkeyEvent:(MTCommandEvent*)event {
    
	if ([event.command isEqualToString:MTCommandPlayMovie ignoreCase:YES] || 
        [event.command isEqualToString:MTCommandPauseMovie ignoreCase:YES]) {
//		if ([[event args] count] == 0) {
//			event.lastResult = @"Requires 1 argument, but has %d", [event.args count];
//			return;
//		}
        
        MPMoviePlayerController *player = (MPMoviePlayerController *)self.delegate;
        
        // Set current playback time
//        NSTimeInterval time = [[event.args objectAtIndex:0] floatValue];
//        [player setCurrentPlaybackTime:time];
        
        if ([event.command isEqualToString:MTCommandPlayMovie ignoreCase:YES])
            [player pause];
        else if ([event.command isEqualToString:MTCommandPauseMovie ignoreCase:YES])
            [player pause];
	} else {
		//[super playbackMonkeyEvent:event];
	}
}

@end

@implementation MPFullScreenTransportControls (MTDisable)

- (BOOL) isMTEnabled {
	return NO;
}

@end

@implementation MPFullScreenVideoOverlay (MTDisable)

- (BOOL) isMTEnabled {
	return NO;
}

@end

@implementation MPVideoBackgroundView (MTDisable)

- (BOOL) isMTEnabled {
	return NO;
}

@end

@implementation MPSwipableView (MTDisable)

- (BOOL) isMTEnabled {
	return NO;
}

@end

@implementation MPTransportButton (MTDisable)

- (BOOL) isMTEnabled {
	return NO;
}

@end