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

 PHEvent.h
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 2/25/14.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <Foundation/Foundation.h>

/**
 * @brief PHEvent class provides ability to create an object representing an event that happens
 * within your application. An event could be anything that is of some interest in your application,
 * e.g. when a user clicks a specific button, adds a friend, etc. You create event objects and send
 * them to PlayHaven's server by means of PHEventRequest class to track those events on your
 * dashboard.
 **/
@interface PHEvent : NSObject

/**
 * Convenience class method for creating autoreleased event object.
 **/
+ (instancetype)eventWithType:(NSString *)aType properties:(NSDictionary *)aProperties;

/**
 * Constructs an event object that encapsulates data representing an event in your application.
 * @param aType
 *   Type of the event. You are free to define any types that make sense for your application. This
 *   property must not be nil.
 * @param aProperties
 *   An optional dictionary with event properties. You are free to define what properties should be
 *   included in the event object. The only restriction is imposed on the data type of the objects
 *   that can be passed within this dictionary, in particular the keys of this dictionary as well as
 *   the keys of all nested sub-dictionaries (if any) must be strings, the values can be of any type
 *   from the following list:
 *
 *   @li NSNull
 *   @li NSString
 *   @li NSArray
 *   @li NSDictionary
 *   @li NSNumber
 *   
 *  Note, at the moment PlayHaven's server has a limitation on the size of the events that cab be
 *  passed from the SDK to the server. As of PH SDK 1.22.0 this limit is 100 KB (to be accurate
 *  102000 bytes). In most cases you should not worry about the size of the event object but if you
 *  plan to pass a lot of data within aProperties dictionary and you are unsure about the size of
 *  the event object, you can check it by writing the following code:
 *
 *  NSUInteger theSize = [[[[theEvent JSONRepresentation] stringByEncodingURLFormat]
 *  dataUsingEncoding:NSUTF8StringEncoding] length];
 *
 * @return
 *   An event object.
 **/
- (instancetype)initWithType:(NSString *)aType properties:(NSDictionary *)aProperties;

/**
 * Event type which is the same that was passed on event creation.
 **/
@property (nonatomic, retain, readonly) NSString *type;

/**
 * Event properties which are the same that were passed on event creation.
 **/
@property (nonatomic, retain, readonly) NSString *properties;

/**
 * Returns JSON representation of the event object.
 **/
@property (nonatomic, retain, readonly) NSString *JSONRepresentation;
@end
