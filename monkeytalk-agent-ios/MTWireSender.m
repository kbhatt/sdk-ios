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

#import "MTWireSender.h"
#import "MonkeyTalk.h"
#import "MTConvertType.h"

#import "SBJSONMT.h"
#import "SBJsonWriterMT.h"
#import "NSString+SBJSONMT.h"
#import "MTWireKeys.h"
#import "MTConvertType.h"
#import "MTUtils.h"


@implementation MTWireSender

+ (NSURL *)monkeyURL {
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%@/fonemonkey",
                           [MonkeyTalk sharedMonkey].recordHost,
                           [MonkeyTalk sharedMonkey].recordPort];
    NSURL *url = [NSURL URLWithString:urlString];
    
    return url;
}

#pragma mark - Post Command
+(void)sendRecordEvent:(MTCommandEvent *)command {
    SBJsonWriterMT *jsonWriter = [[SBJsonWriterMT alloc] init];
    NSMutableDictionary *jsonDict = [[NSMutableDictionary alloc] init];
    NSString *postString = nil;
    NSData *postData = nil;
    
    NSDictionary *modifiers = [NSDictionary 
                               dictionaryWithObject:command.playbackDelay 
                               forKey:MTWireThinkTimeKey];
    
    // Convert component type to universal component
    NSString *componentType = [MTConvertType 
                               convertedComponentFromString:command.className 
                               isRecording:YES];
    
//    NSString *componentType = command.className;

    NSURL *url = [[self class] monkeyURL];
    NSMutableURLRequest *request = [NSMutableURLRequest 
                                    requestWithURL:url 
                                    cachePolicy:NSURLRequestReloadIgnoringCacheData
                                    timeoutInterval:500];
    
    [request setHTTPMethod:@"POST"];
    
    // Replace monkeyID #1 with *
    // #-1 seems to be recorded on TabBar when one Tab lacks title 
    // (may need to investigate further)
    if ([command.monkeyID isEqualToString:@"#1"] ||
        [command.monkeyID isEqualToString:@"#-1"])
        command.monkeyID = @"*";
    
    // Build json dict for command event
    [jsonDict setValue:MTWireVersionValue forKey:MTWireVersionKey];
    [jsonDict setValue:MTWireCommandRecord forKey:MTWireCommandKey];
    [jsonDict setValue:componentType forKey:MTWireComponentTypeKey];
    [jsonDict setValue:command.monkeyID forKey:MTWireMonkeyIdKey];
    [jsonDict setValue:command.command forKey:MTWireActionKey];
    [jsonDict setValue:command.args forKey:MTWireArgsKey];
    
    // Eventually send think time for recorded speed
//    [jsonDict setValue:modifiers forKey:MTWireModifiersKey];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"content-type"];
    
    
    postString = [jsonWriter stringWithObject:jsonDict];
    postData = [postString 
                dataUsingEncoding:NSUTF8StringEncoding 
                allowLossyConversion:YES];
    
    [request setHTTPBody:postData];
    
//    NSLog(@"send string: %@",postString);
    
    dispatch_queue_t queue = dispatch_queue_create("com.gorillalogic.sendqueue", NULL);
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    dispatch_sync(queue, ^{
        NSError *error = nil;
        NSURLResponse *response = nil;
        
        NSData *data = [NSURLConnection 
                        sendSynchronousRequest:request 
                        returningResponse:&response 
                        error:&error];
        
        if (data) {
//            NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//            NSLog(@"Result: %@",result);
        }
    });
    
    [jsonDict release];
    [jsonWriter release];
}

@end
