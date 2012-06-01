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

#import "MTWireResponder.h"
#import "MonkeyTalk.h"
#import "MTCommandEvent.h"
#import "MTConvertType.h"

#import "SBJSONMT.h"
#import "SBJsonWriterMT.h"
#import "NSString+SBJSONMT.h"
#import "MTWireKeys.h"
#import "MTUtils.h"
#import "MTComponentTree.h"

@implementation MTWireResponder
MonkeyTalk* theMonkey;

+ (NSDictionary *) replaceStarInDict:(NSDictionary *)dict {
    for (NSString *key in [dict allKeys]) {
        if ([[dict objectForKey:key] respondsToSelector:@selector(isEqualToString:)] && [[dict objectForKey:key] isEqualToString:@"*"] && ![key isEqualToString:MTWireArgsKey])
            [dict setValue:@"#1" forKey:key];
    }
    
    return dict;
}

#pragma mark - Handle/Respond to JSON
+ (NSObject<MTHTTPResponse> *) wireResponseFromQuery:(NSString *)query 
                                          withData:(NSData *)data {
    
    NSString *jsonString = [[[NSString alloc] 
                            initWithData:data 
                            encoding:NSUTF8StringEncoding] autorelease];
    
    NSDictionary *jsonDictionary = [jsonString JSONValue];
    NSString *command = [jsonDictionary objectForKey:MTWireCommandKey];
    
    id<MTHTTPResponse,NSObject> response = nil;
    NSString *postString = nil;
    NSData *postData = nil;
    
    // Log string coming across wire
//    NSLog(@"data: '%@'", dataString);
    
    if ([command isEqualToString:MTWireCommandDumpTree]) {
        SBJsonWriterMT *jsonWriter = [[SBJsonWriterMT alloc] init];
        NSMutableDictionary *jsonDict = [[NSMutableDictionary alloc] init];
        [jsonDict setValue:@"OK" forKey:@"result"];
        [jsonDict setValue:[[MTComponentTree componentTree] objectAtIndex:0] forKey:@"message"];
        postString = [jsonWriter stringWithObject:jsonDict];
        
        postData = [postString 
                    dataUsingEncoding:NSUTF8StringEncoding 
                    allowLossyConversion:YES];
        
        response = [[MTHTTPDataResponse alloc] initWithData:postData];
    } else if ([command isEqualToString:MTWireCommandPlay]) {
        SBJsonWriterMT *jsonWriter = [[SBJsonWriterMT alloc] init];
        NSMutableDictionary *jsonDict = [[NSMutableDictionary alloc] init];
        jsonDictionary = [[self class] replaceStarInDict:jsonDictionary];
        NSString *action = [jsonDictionary objectForKey:MTWireActionKey];
        NSString *type = [jsonDictionary objectForKey:MTWireComponentTypeKey];
        NSString *monkeyID = [jsonDictionary objectForKey:MTWireMonkeyIdKey];
        NSArray *args = (NSArray *)[jsonDictionary objectForKey:MTWireArgsKey];
        NSDictionary *modifiers = (NSDictionary *)[jsonDictionary 
                                                   objectForKey:MTWireModifiersKey];

        NSString *timeout = nil;
        NSString *thinkTime = nil;
        
        if (modifiers) {
            timeout = [modifiers objectForKey:MTWireTimeoutKey];
            thinkTime = [modifiers objectForKey:MTWireThinkTimeKey];
        }
        
        if (thinkTime == nil)
            thinkTime = [NSString stringWithFormat:@"%i",MT_DEFAULT_THINKTIME];
        if (timeout == nil)
            timeout = [NSString stringWithFormat:@"%i",MT_DEFAULT_TIMEOUT];
        
        // Set args to nil if there is no args coming across wire
        if ([args count] == 0)
            args = nil;
        
        // Convert the action/component to ObjC
        NSString *originalType = [NSString stringWithFormat:@"%@",type];
        type = [MTConvertType convertedComponentFromString:type isRecording:NO];
        
        // Play the event
        if (type)
            postString = [[MonkeyTalk sharedMonkey] playAndRespond:[MTCommandEvent command:action className:type monkeyID:monkeyID delay:thinkTime timeout:timeout args:args]];
        else if ([originalType isEqualToString:@"(null)"]) {
            // It's a comment — send back OK
            [jsonDict setValue:@"OK" forKey:@"result"];
            
            postString = [jsonWriter stringWithObject:jsonDict];
        } else {
            NSString *failure = [NSString stringWithFormat:@"%@ is not a MonkeyTalk component — prefix it with a \".\" to use as custom component (.%@)",
                                 originalType,originalType];
            SBJsonWriterMT *jsonWriter = [[SBJsonWriterMT alloc] init];
            NSMutableDictionary *jsonDict = [[NSMutableDictionary alloc] init];
            // Command failed
            [jsonDict setValue:@"FAILURE" forKey:@"result"];
            [jsonDict setValue:failure forKey:@"message"];
            
            postString = [jsonWriter stringWithObject:jsonDict];
            NSLog(@"MonkeyTalk Script Failure: %@\n", failure);
        }
        
        [jsonDict release];
        [jsonWriter release];
        
        postData = [postString 
                    dataUsingEncoding:NSUTF8StringEncoding 
                    allowLossyConversion:YES];
        
        response = [[MTHTTPDataResponse alloc] initWithData:postData];
    } else if ([command isEqualToString:MTWireCommandPing]) {
        
        SBJsonWriterMT *jsonWriter = [[SBJsonWriterMT alloc] init];
        NSMutableDictionary *jsonDict = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
        
        // Add os to metadata
        [metadata setValue:MTWireMetadataOsValue forKey:MTWireMetadataOsKey];
        
        NSString *recordString = [jsonDictionary objectForKey:[MTWireCommandRecord lowercaseString]];
        
        // Set isWireRecording flag based on record key
        if ([recordString isEqualToString:@"ON"]) {
            [MonkeyTalk sharedMonkey].recordHost = [jsonDictionary objectForKey:[MTWireRecordHost lowercaseString]];
            [MonkeyTalk sharedMonkey].recordPort = [jsonDictionary objectForKey:[MTWireRecordPort lowercaseString]];
            
            [MonkeyTalk sharedMonkey].isWireRecording = YES;
            [theMonkey record];
        } else {
            [MonkeyTalk sharedMonkey].isWireRecording = NO;
            [theMonkey pause];
        }
        
        // Add to response dictionary
        [jsonDict setValue:MTWireSuccessValue forKey:MTWireResultKey];
        [jsonDict setValue:metadata forKey:MTWireMessageKey];
//        [jsonDict setValue:metadata forKey:MTWireMetadataKey];
//        [jsonDict setValue:MTWireMetadataOsValue forKey:MTWireMetadataOsKey];
        
        postString = [jsonWriter stringWithObject:jsonDict];
        postData = [postString 
                    dataUsingEncoding:NSUTF8StringEncoding 
                    allowLossyConversion:YES];
        
//        NSLog(@"Post String: %@",postString);
        
        response = [[MTHTTPDataResponse alloc] initWithData:postData];
        
        [jsonWriter release];
        [jsonDict release];
        [metadata release];
    }
    
    return response;
//    return nil;
}

@end
