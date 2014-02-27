/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Copyright 2014 Medium Entertainment, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 PHEvent.m
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 2/25/14.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "PHEvent.h"
#import "PHConstants.h"
#import "JSON.h"

static NSString *const kPHEventTypeKey = @"type";
static NSString *const kPHEventTimestampKey = @"timestamp";
static NSString *const kPHEventDataKey = @"data";

@interface PHEvent ()
@property (nonatomic, assign, readonly) NSTimeInterval timestamp;
@property (nonatomic, retain, readonly) NSDictionary *eventDictionary;
@end

@implementation PHEvent
@synthesize eventDictionary = _eventDictionary;

+ (id)eventWithType:(NSString *)aType properties:(NSDictionary *)aProperties
{
    return [[[self alloc] initWithType:aType properties:aProperties] autorelease];
}

- (instancetype)initWithType:(NSString *)aType properties:(NSDictionary *)aProperties
{
    if (nil == aType)
    {
        PH_LOG(@"%s[ERROR]: Cannot create event object with nil type!", __PRETTY_FUNCTION__);
        [self release];
        return nil;
    }
    else if (![[self class] isPropertiesValid:aProperties])
    {
        [self release];
        return nil;
    }
    
    self = [super init];
    if (nil != self)
    {
        NSMutableDictionary *theEventDictionary = [NSMutableDictionary new];
        theEventDictionary[kPHEventTypeKey] = aType;
        theEventDictionary[kPHEventTimestampKey] = @((NSInteger)[[NSDate date]
                    timeIntervalSince1970]);

        if (nil != aProperties)
        {
            theEventDictionary[kPHEventDataKey] = aProperties;
        }

        _eventDictionary = theEventDictionary;
    }
    
    return self;
}

- (void)dealloc
{
    [_eventDictionary release];
    
    [super dealloc];
}

- (NSString *)type
{
    return self.eventDictionary[kPHEventTypeKey];
}

- (NSString *)properties
{
    return self.eventDictionary[kPHEventDataKey];
}

- (NSString *)JSONRepresentation
{
    NSError *theError = nil;
    NSString *theJSONRepresentation = [[self class] JSONStringFromDictionary:self.eventDictionary
                error:&theError];
    
    if (nil == theJSONRepresentation)
    {
        PH_LOG(@"%s[ERROR] Cannot get JSON representation of the event: error - %@;\nevent - %@",
                    __PRETTY_FUNCTION__, theError, self.eventDictionary);
        return nil;
    }
    
    return theJSONRepresentation;
}

#pragma mark - Private

+ (BOOL)isPropertiesValid:(NSDictionary *)aProperties
{
    NSError *theError = nil;
    
    if (nil != aProperties && nil == [[self class] JSONStringFromDictionary:aProperties error:
                &theError])
    {
        PH_LOG(@"%s[ERROR] aProperties object cannot be converted into JSON string: %@",
                    __PRETTY_FUNCTION__, theError);
        return NO;
    }
    
    return YES;
}

+ (NSString *)JSONStringFromDictionary:(NSDictionary *)aDictionary error:(NSError **)aoError
{
    if (NULL != aoError)
    {
        *aoError = nil;
    }
    
    if (nil == aDictionary)
    {
        return nil;
    }
    
    PH_SBJSONWRITER_CLASS *theJSONWriter = [PH_SBJSONWRITER_CLASS new];
    NSString *theJSONString = [theJSONWriter stringWithObject:aDictionary error:aoError];

    [theJSONWriter release];
    
    return theJSONString;
}

@end
