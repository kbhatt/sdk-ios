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

#define RETRIES 10
#define RETRY 500

#import "MTVerifyCommand.h"
#import "MonkeyTalk.h"
#import "MTDefaultProperty.h"
#import "MTValueFromProperty.h"
#import "NSString+MonkeyTalk.h"
#import "MTConvertType.h"

@implementation MTVerifyCommand


+ (NSDictionary *) verifyArgs:(MTCommandEvent *)ev {
    NSString* arg1 = nil;
    NSString* arg2 = nil;
    
    if ([ev.args count] == 1 || [[ev.args objectAtIndex:1] isEqualToString:@"value"]) {
        arg2 = @"value";
        arg1 = [ev.args objectAtIndex:0];
    } else {
        arg1 = [ev.args objectAtIndex:0];
        arg2 = [ev.args objectAtIndex:1];
    }
    
    if ([[arg2 substringToIndex:1] isEqualToString:@"."]) {
        arg2 = [arg2 substringFromIndex:1];
        return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:arg1, arg2, nil] forKeys:[NSArray arrayWithObjects:@"Arg1",@"InternalProperty", nil]];
    }
    
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:arg1, arg2, nil] forKeys:[NSArray arrayWithObjects:@"Arg1",@"Arg2", nil]];
}

+ (NSString *) valueFromProp:(NSString *)prop forView:(UIView *)source {
    NSString* value;
    
    if ([prop isEqualToString:MTVerifyPropertySwitch]) {
        BOOL isOn = [[source valueForKeyPath:prop] boolValue];
        
        if (isOn)
            value = @"on";
        else
            value = @"off";
    } else
        value = [source valueForKeyPath:prop];
    
    return value;
}

+ (void) handleVerify:(MTCommandEvent*) ev {
    if ([ev.command isEqualToString:MTCommandVerify ignoreCase:YES]) {
        [MTVerifyCommand execute:ev isVerifyNot:NO];
        return;
    } else if ([ev.command isEqualToString:MTCommandVerifyNot ignoreCase:YES]) {
        [MTVerifyCommand execute:ev isVerifyNot:YES];
        return;
    } else if ([ev.command isEqualToString:MTCommandVerifyRegex ignoreCase:YES]) {
        [MTVerifyCommand verifyRegex:ev isVerifyNot:NO];
        return;
    } else if ([ev.command isEqualToString:MTCommandVerifyNotRegex ignoreCase:YES]) {
        [MTVerifyCommand verifyRegex:ev isVerifyNot:YES];
        return;
    } else if ([ev.command isEqualToString:MTCommandVerifyWildcard ignoreCase:YES]) {
        [MTVerifyCommand verifyWildcard:ev isVerifyNot:NO];
        return;
    } else if ([ev.command isEqualToString:MTCommandVerifyNotWildcard ignoreCase:YES]) {
        [MTVerifyCommand verifyWildcard:ev isVerifyNot:YES];
        return;
    }
}

+ (NSString*) execute:(MTCommandEvent*) ev isVerifyNot:(BOOL)isVerifyNot {
//    NSLog(@"Verify: %@",ev.source);
	ev.lastResult = nil;
	UIView* source = nil;
    
    if (!ev.value)
        source = ev.source;
    
	if (source == nil && !ev.value) {
		ev.lastResult = [NSString 
                         stringWithFormat:@"Unable to find %@ with monkeyID %@", 
                         ev.className, ev.monkeyID];
		return ev.lastResult;
	}	
	if ([ev.args count] > 0) {
        NSDictionary *verifyArgs = [[self class] verifyArgs:ev];
        
		NSString* prop = [verifyArgs objectForKey:@"Arg2"];
		NSString* expected = [verifyArgs objectForKey:@"Arg1"];
        NSString* internal = [verifyArgs objectForKey:@"InternalProperty"];
        NSString* errorMessage = nil;
        
        if ([ev.args count] > 2)
            errorMessage = [ev.args objectAtIndex:2];
        
		NSString* value;
		@try {
            if (ev.value) {
                value = ev.value;
            }
            else {
                if (internal) {
                    if ([MTValueFromProperty shouldUseCustomValueForProp:internal onView:source])
                        value = [MTValueFromProperty valueFromProp:internal forView:source];
                    else
                        value = [source valueForKeyPath:internal];
                } else
                    value = [MTValueFromProperty valueFromProp:prop forView:source];
            }
		} @catch (NSException* e)
		{
            if ([[e reason] isEqualToString:@"invalid property"])
                ev.lastResult = [NSString 
                                 stringWithFormat: @"\"%@\" is not a valid MonkeyTalk property for %@ (prefix property arg with . to use internal keypaths)", 
                                 prop, [MTConvertType convertedComponentFromString:ev.className isRecording:YES]];
            else
                ev.lastResult = [NSString 
                             stringWithFormat: @"\"%@\" is not a valid keypath for %@\"", 
                             internal, ev.className];
			return ev.lastResult;
		}
		
        value = [NSString stringWithFormat:@"%@", value];
        
//        NSLog(@"Value: %@",value);
		if ([expected isEqualToString:value]) {
            if (isVerifyNot) {
                ev.lastResult = [NSString 
                                     stringWithFormat: @"Expected \"%@\" and found \"%@\"", 
                                     expected, value];
                
                if (errorMessage)
                    // Use provided error message
                    ev.lastResult = [ev.lastResult stringByAppendingFormat:@": %@",errorMessage];
            } else
                return nil;
		} else {
            if (isVerifyNot)
                return nil;
            else {
                ev.lastResult = [NSString 
                                     stringWithFormat: @"Expected \"%@\", but found \"%@\"", 
                                     expected, value];
                
                if (errorMessage)
                    // Use provided error message
                    ev.lastResult = [ev.lastResult stringByAppendingFormat:@": %@",errorMessage];
            }
                
		}
	} 
	return ev.lastResult;
}

+ (NSString*) verifyRegex:(MTCommandEvent*) ev isVerifyNot:(BOOL)isVerifyNot {
	ev.lastResult = nil;
	UIView* source = nil;
    
    if (!ev.value)
        source = ev.source;
    
	if (source == nil && !ev.value) {
		ev.lastResult = [NSString 
                         stringWithFormat:@"Unable to find %@ with monkeyID %@", 
                         ev.className, ev.monkeyID];
		return ev.lastResult;
	}	
	if ([ev.args count] > 0) {
        NSDictionary *verifyArgs = [[self class] verifyArgs:ev];
        NSString* regexString = [verifyArgs objectForKey:@"Arg1"];
        NSString* prop = [verifyArgs objectForKey:@"Arg2"];
        NSString* internal = [verifyArgs objectForKey:@"InternalProperty"];
        
        NSString* errorMessage = nil;
        
        if ([ev.args count] > 2)
            errorMessage = [ev.args objectAtIndex:2];
        
        NSError *error = nil;
        NSRegularExpression *regex = [[NSRegularExpression alloc] 
                                      initWithPattern:regexString 
                                      options:NSRegularExpressionCaseInsensitive error:&error];
        
        if (error) {
            ev.lastResult = [NSString 
                             stringWithFormat: @"Error with regular expression syntax \"%@\".", 
                             regexString];
			return ev.lastResult;
        }
        
		NSString* value;
		@try {
            if (internal) {
                if ([MTValueFromProperty shouldUseCustomValueForProp:internal onView:source])
                    value = [MTValueFromProperty valueFromProp:internal forView:source];
                else
                    value = [source valueForKeyPath:internal];
            } else
                value = [MTValueFromProperty valueFromProp:prop forView:source];		
		} @catch (NSException* e)
		{
			if ([[e reason] isEqualToString:@"invalid property"])
                ev.lastResult = [NSString 
                                 stringWithFormat: @"\"%@\" is not a valid MonkeyTalk property for %@ (prefix property arg with . to use internal keypaths)", 
                                 prop, [MTConvertType convertedComponentFromString:ev.className isRecording:YES]];
            else
                ev.lastResult = [NSString 
                                 stringWithFormat: @"\"%@\" is not a valid keypath for %@\"", 
                                 internal, ev.className];
			return ev.lastResult;
		}
		
        value = [NSString stringWithFormat:@"%@", value];
        
        NSArray* regexResults = [regex matchesInString:value options:0 
                                                 range:NSMakeRange(0, [value length])];
        
        NSString* foundRegex = nil;
        
        for (NSTextCheckingResult* b in regexResults)
        {
            foundRegex = [value substringWithRange:b.range];
        }
        
        if (foundRegex) {
            if (isVerifyNot) {
                ev.lastResult = [NSString 
                                     stringWithFormat: @"Regex \"%@\" found in \"%@\"", 
                                     regexString, value];
                
                if (errorMessage)
                    // Use provided error message
                    ev.lastResult = [ev.lastResult stringByAppendingFormat:@": %@",errorMessage];
            } else
                return nil;
        }
        else {
            if (isVerifyNot)
                return nil;
            else {
                ev.lastResult = [NSString 
                                 stringWithFormat: @"Regex \"%@\" not found in \"%@\"", 
                                 regexString, value];
                
                if (errorMessage)
                    // Use provided error message
                    ev.lastResult = [ev.lastResult stringByAppendingFormat:@": %@",errorMessage];
            }
        }
        
        [regex release];
	} 
	return ev.lastResult;
}

+ (NSString*) verifyWildcard:(MTCommandEvent*) ev isVerifyNot:(BOOL)isVerifyNot {
	ev.lastResult = nil;
	UIView* source = nil;
    
    if (!ev.value)
        source = ev.source;
    
	if (source == nil && !ev.value) {
		ev.lastResult = [NSString 
                         stringWithFormat:@"Unable to find %@ with monkeyID %@", 
                         ev.className, ev.monkeyID];
		return ev.lastResult;
	}	
	if ([ev.args count] == 2) {
        NSDictionary *verifyArgs = [[self class] verifyArgs:ev];
        NSString* originalString = [verifyArgs objectForKey:@"Arg1"];
        NSString* prop = [verifyArgs objectForKey:@"Arg2"];
        NSString* internal = [verifyArgs objectForKey:@"InternalProperty"];
        
        NSString* errorMessage = nil;
        
        if ([ev.args count] > 2)
            errorMessage = [ev.args objectAtIndex:2];
        
        NSString* regexString = [originalString 
                                 stringByReplacingOccurrencesOfString:@"*" withString:@"[^\s]*"];
        
        NSError *error = nil;
        NSRegularExpression *regex = [[NSRegularExpression alloc] 
                                      initWithPattern:regexString 
                                      options:NSRegularExpressionCaseInsensitive error:&error];
        
        if (error) {
            ev.lastResult = [NSString 
                             stringWithFormat: @"Error with regular expression syntax \"%@\".", 
                             regexString];
			return ev.lastResult;
        }
        
		NSString* value;
		@try {
            if (internal) {
                if ([MTValueFromProperty shouldUseCustomValueForProp:internal onView:source])
                    value = [MTValueFromProperty valueFromProp:internal forView:source];
                else
                    value = [source valueForKeyPath:internal];
            } else
                value = [MTValueFromProperty valueFromProp:prop forView:source];		
		} @catch (NSException* e)
		{
			if ([[e reason] isEqualToString:@"invalid property"])
                ev.lastResult = [NSString 
                                 stringWithFormat: @"\"%@\" is not a valid MonkeyTalk property for %@ (prefix property arg with . to use internal keypaths)", 
                                 prop, [MTConvertType convertedComponentFromString:ev.className isRecording:YES]];
            else
                ev.lastResult = [NSString 
                                 stringWithFormat: @"\"%@\" is not a valid keypath for %@\"", 
                                 internal, ev.className];
			return ev.lastResult;
		}
		
        value = [NSString stringWithFormat:@"%@", value];
        
        NSArray* regexResults = [regex matchesInString:value 
                                               options:0 range:NSMakeRange(0, [value length])];
        
        NSString* foundRegex = nil;
        
        for (NSTextCheckingResult* b in regexResults)
        {
            foundRegex = [value substringWithRange:b.range];
        }
        
        if (foundRegex) {
            if (isVerifyNot) {
                ev.lastResult = [NSString 
                                     stringWithFormat: @"Wildcard string \"%@\" found in \"%@\"", 
                                     originalString, value];
                
                if (errorMessage)
                    // Use provided error message
                    ev.lastResult = [ev.lastResult stringByAppendingFormat:@": %@",errorMessage];
            } else
                return nil;
        }
        else {
            if (isVerifyNot)
                return nil;
            else {
                ev.lastResult = [NSString 
                                     stringWithFormat: @"Wildcard string \"%@\" not found in \"%@\"", 
                                     originalString, value];
                
                if (errorMessage)
                    // Use provided error message
                    ev.lastResult = [ev.lastResult stringByAppendingFormat:@": %@",errorMessage];
            }
        }
        
        [regex release];
	} 
	return ev.lastResult;
}
@end
