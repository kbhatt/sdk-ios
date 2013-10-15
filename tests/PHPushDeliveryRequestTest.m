/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Copyright 2013 Medium Entertainment, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 PHPushRequestTest.m
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 4/25/13.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <SenTestingKit/SenTestingKit.h>
#import "PHPushDeliveryRequest.h"
#import "SenTestCase+PHAPIRequestSupport.h"

static NSString *const kTestMessageID = @"testMessageID";
static NSString *const kTestContentID = @"testContentID";

@interface PHPushDeliveryRequestTest : SenTestCase
@end

@implementation PHPushDeliveryRequestTest

- (void)testCreation
{
    PHPushDeliveryRequest *theRequest = [[[PHPushDeliveryRequest alloc] initWithApp:@"testToken"
                secret:@"testSecret" pushNotificationDeviceToken:[@"testToken" dataUsingEncoding:
                NSUTF8StringEncoding] messageID:kTestMessageID contentUnitID:@"testContentID"]
                autorelease];
    STAssertNotNil(theRequest, @"Cannot create request through designated initializer");

    theRequest = [[[PHPushDeliveryRequest alloc] initWithApp:@"testToken" secret:@"testSecret"
                pushNotificationDeviceToken:nil messageID:nil contentUnitID:@"testContentID"]
                autorelease];
    STAssertNil(theRequest, @"Request should not be created without message ID");
}

- (void)testParameters
{
    PHPushDeliveryRequest *theRequest = [PHPushDeliveryRequest requestForApp:@"testToken"
                secret:@"testSecret" pushNotificationDeviceToken:[@"testToken" dataUsingEncoding:
                NSUTF8StringEncoding] messageID:kTestMessageID contentUnitID:kTestContentID];
    STAssertNotNil(theRequest, @"Cannot create request through designated initializer");

    NSURL *theRequestURL = [self URLForRequest:theRequest];
    NSString *theRequestQuery = [theRequestURL query];
    
    STAssertTrue((0 < [theRequestQuery rangeOfString:[NSString stringWithFormat:@"message_id=%@",
                kTestMessageID]].length), @"Missed required parameter");
    STAssertTrue((0 < [theRequestQuery rangeOfString:[NSString stringWithFormat:@"content_id=%@",
                kTestContentID]].length), @"Missed required parameter");
}

@end
