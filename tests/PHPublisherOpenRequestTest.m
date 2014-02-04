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

 PHPublisherOpenRequestTest.m
 playhaven-sdk-ios

 Created by Jesus Fernandez on 3/30/11.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <SenTestingKit/SenTestingKit.h>
#import "PHPublisherOpenRequest.h"
#import "PHConstants.h"
#import "SenTestCase+PHAPIRequestSupport.h"
#import "PHAPIRequest+Private.h"
#import "PHKontagentDataAccessor.h"
#import "PHKontagentDataAccessor+UnitTesting.h"

#define EXPECTED_HASH @"3L0xlrDOt02UrTDwMSnye05Awwk"

static NSString *const kPHTestAPIKey1 = @"f25a3b41dbcb4c13bd8d6b0b282eec32";
static NSString *const kPHTestAPIKey2 = @"d45a3b4c13bd82eec32b8d6b0b241dbc";
static NSString *const kPHTestSID1 = @"13565276206185677368";
static NSString *const kPHTestSID2 = @"12256527677368061856";

static NSString *const kPHTestToken  = @"PUBLISHER_TOKEN";
static NSString *const kPHTestSecret = @"PUBLISHER_SECRET";

@interface PHPublisherOpenRequestTest : SenTestCase
@end

@implementation PHPublisherOpenRequestTest

- (void)setUp
{
    [super setUp];

    // Cancel the request to remove it from the cache
    [[PHPublisherOpenRequest requestForApp:kPHTestToken secret:kPHTestSecret] cancel];
}

- (void)testInstance
{
    NSString *token  = @"PUBLISHER_TOKEN",
             *secret = @"PUBLISHER_SECRET";
    PHPublisherOpenRequest *request = [PHPublisherOpenRequest requestForApp:(NSString *)token secret:(NSString *)secret];
    NSURL *theRequestURL = [self URLForRequest:request];
    NSString *requestURLString = [theRequestURL absoluteString];

    STAssertNotNil(requestURLString, @"Parameter string is nil?");
    STAssertFalse([requestURLString rangeOfString:@"token="].location == NSNotFound,
                  @"Token parameter not present!");
    STAssertFalse([requestURLString rangeOfString:@"nonce="].location == NSNotFound,
                  @"Nonce parameter not present!");
    STAssertFalse([requestURLString rangeOfString:@"sig4="].location == NSNotFound,
                  @"Secret parameter not present!");

    STAssertTrue([request respondsToSelector:@selector(send)], @"Send method not implemented!");
}

- (void)testRequestParameters
{
    NSString *token  = @"PUBLISHER_TOKEN",
             *secret = @"PUBLISHER_SECRET";

    [PHAPIRequest setCustomUDID:nil];

    PHPublisherOpenRequest *request = [PHPublisherOpenRequest requestForApp:token secret:secret];
    NSURL *theRequestURL = [self URLForRequest:request];

    NSDictionary *signedParameters  = [request signedParameters];
    NSString     *requestURLString  = [theRequestURL absoluteString];

//#define PH_USE_MAC_ADDRESS 1
#if PH_USE_MAC_ADDRESS == 1
    if (PH_SYSTEM_VERSION_LESS_THAN(@"6.0"))
    {
        NSString *mac   = [signedParameters valueForKey:@"mac"];
        STAssertNotNil(mac, @"MAC param is missing!");
        STAssertFalse([requestURLString rangeOfString:@"mac="].location == NSNotFound, @"MAC param is missing: %@", requestURLString);
    }
#else
    NSString *mac   = [signedParameters valueForKey:@"mac"];
    STAssertNil(mac, @"MAC param is present!");
    STAssertTrue([requestURLString rangeOfString:@"mac="].location == NSNotFound, @"MAC param exists when it shouldn't: %@", requestURLString);
#endif
}

- (void)testCustomUDID
{
    NSString *token  = @"PUBLISHER_TOKEN",
             *secret = @"PUBLISHER_SECRET";

    [PHAPIRequest setCustomUDID:nil];

    PHPublisherOpenRequest *request = [PHPublisherOpenRequest requestForApp:token secret:secret];
    NSURL *theRequestURL = [self URLForRequest:request];
    NSString *requestURLString = [theRequestURL absoluteString];

    STAssertNotNil(requestURLString, @"Parameter string is nil?");
    STAssertTrue([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                  @"Custom parameter exists when none is set.");

    PHPublisherOpenRequest *request2 = [PHPublisherOpenRequest requestForApp:token secret:secret];
    request2.customUDID = @"CUSTOM_UDID";
    theRequestURL = [self URLForRequest:request2];
    requestURLString = [theRequestURL absoluteString];
    STAssertFalse([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                 @"Custom parameter missing when one is set.");
}

- (void)testTimeZoneParameter
{
    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    NSURL *theRequestURL = [self URLForRequest:theRequest];
    
    STAssertNotNil([theRequest.additionalParameters objectForKey:@"tz"], @"Missed time zone!");
    STAssertTrue(0 < [[theRequestURL absoluteString] rangeOfString:@"tz="].length, @"Missed time "
                "zone!");

    NSScanner *theTimeZoneScanner = [NSScanner scannerWithString:[theRequestURL absoluteString]];

    STAssertTrue([theTimeZoneScanner scanUpToString:@"tz=" intoString:NULL], @"Missed time zone!");
    STAssertTrue([theTimeZoneScanner scanString:@"tz=" intoString:NULL], @"Missed time zone!");
    
    float theTimeOffset = 0;
    STAssertTrue([theTimeZoneScanner scanFloat:&theTimeOffset], @"Missed time zone!");
    
    STAssertTrue(- 11 <= theTimeOffset && theTimeOffset <= 14, @"Incorrect time zone offset");
}

- (void)testHTTPMethod
{
    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    STAssertNotNil(theRequest, @"");
    
    STAssertEquals(PHRequestHTTPPost, theRequest.HTTPMethod, @"HTTPMethod of the request doesn't "
                "match the expected one!");
}


- (void)testKTAPIKeySIDPairsCase1
{
    // Cleanup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];

    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    STAssertNotNil(theRequest, @"");

    NSURL *theRequestURL = [self URLForRequest:theRequest];
    NSDictionary *theSignedParameters = [theRequest signedParameters];
    
    STAssertNil(theSignedParameters[@"ktsids"], @"ktsids parameter should be nil after KT locations"
                " cleanup!");
    STAssertTrue(0 == [theRequestURL.absoluteString rangeOfString:@"ktsids"].length, @"");

    // Make sure that ktsid parameter with is not included in the request parameters
    STAssertNil(theSignedParameters[@"ktsid"], @"ktsid parameter is not expected after KL locations"
                " cleanup!");
}

- (void)testKTAPIKeySIDPairsCase2
{
    // Setup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];
    [PHKontagentDataAccessor storeSIDInPersistentValues:kPHTestSID1 forAPIKey:kPHTestAPIKey1];
    [PHKontagentDataAccessor storeSIDInUserDefaults:kPHTestSID2 forAPIKey:kPHTestAPIKey2];

    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    STAssertNotNil(theRequest, @"");

    NSURL *theRequestURL = [self URLForRequest:theRequest];
    NSDictionary *theSignedParameters = [theRequest signedParameters];
    
    NSString *theExpectedPair1 =
                @"{\"api\":\"f25a3b41dbcb4c13bd8d6b0b282eec32\",\"sid\":\"13565276206185677368\"}";
    NSString *theExpectedPair2 =
                @"{\"api\":\"d45a3b4c13bd82eec32b8d6b0b241dbc\",\"sid\":\"12256527677368061856\"}";

    // The expected structure of the ktsids parameter:
    // [{"api":"f25a3b41dbcb4c13bd8d6b0b282eec32","sid":"13565276206185677368"},
    // {"api":"d45a3b4c13bd82eec32b8d6b0b241dbc","sid":"12256527677368061856"}]
    
    STAssertTrue([theSignedParameters[@"ktsids"] hasPrefix:@"[{"], @"Unexpected structure of the "
                "of the 'ktsids' parameter value: %@", theSignedParameters[@"ktsids"]);
                
    STAssertTrue([theSignedParameters[@"ktsids"] rangeOfString:theExpectedPair1].length > 0,
                @"The expected pair (%@) is not found in the URL parameters", theExpectedPair1);
    STAssertTrue([theSignedParameters[@"ktsids"] rangeOfString:theExpectedPair2].length > 0,
                @"The expected pair (%@) is not found in the URL parameters", theExpectedPair2);
    
    // Check that the pairs are included in the final URL
    STAssertTrue([[theRequestURL.absoluteString stringByReplacingPercentEscapesUsingEncoding:
                NSUTF8StringEncoding] rangeOfString:theExpectedPair1].length > 0,
                @"The expected pair (%@) is not found in the URL parameters", theExpectedPair1);
    STAssertTrue([[theRequestURL.absoluteString stringByReplacingPercentEscapesUsingEncoding:
                NSUTF8StringEncoding] rangeOfString:theExpectedPair2].length > 0,
                @"The expected pair (%@) is not found in the URL parameters", theExpectedPair2);

    // Make sure that ktsid parameter with is not included in the request parameters
    STAssertNil(theSignedParameters[@"ktsid"], @"ktsid parameter is not expected after KL locations"
                " cleanup until it is set with -[PHKontagentDataAccessor "
                "storePrimarySenderID:forAPIKey:]!");
    
    // Cleanup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];
}

- (void)testKTAPIKeySIDPairsCase3
{
    // Setup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];
    [[PHKontagentDataAccessor sharedAccessor] storePrimarySenderID:kPHTestSID1 forAPIKey:
                kPHTestAPIKey1];
    
    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    STAssertNotNil(theRequest, @"");

    NSURL *theRequestURL = [self URLForRequest:theRequest];
    NSDictionary *theSignedParameters = [theRequest signedParameters];
    
    // Make sure that a list of API keys and SIDs is not sent once primary ID is defined
    STAssertNil(theSignedParameters[@"ktsids"], @"ktsids parameter should be nil after KT locations"
                " cleanup!");
    STAssertTrue(0 == [theRequestURL.absoluteString rangeOfString:@"ktsids"].length, @"");
    
    // Make sure that ktsid parameter with the primary SID is included in the request parameters
    STAssertEqualObjects(kPHTestSID1, theSignedParameters[@"ktsid"], @"The SID specified in the "
                "request doesn't match the expected one!");

    // Cleanup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];
}

@end
