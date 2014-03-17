/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Copyright 2013-2014 Medium Entertainment, Inc.

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
#import "PHConstants.h"
#import "JSON.h"

#define EXPECTED_HASH @"3L0xlrDOt02UrTDwMSnye05Awwk"

static NSString *const kPHTestAPIKey1 = @"f25a3b41dbcb4c13bd8d6b0b282eec32";
static NSString *const kPHTestAPIKey2 = @"d45a3b4c13bd82eec32b8d6b0b241dbc";
static NSString *const kPHTestAPIKey3 = @"3bd82eed45a332b8d6b0b241dbcb4c1c";
static NSString *const kPHTestSID1 = @"13565276206185677368";
static NSString *const kPHTestSID2 = @"12256527677368061856";
static NSString *const kPHTestSID3 = @"73680618561225652767";

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

    // Make sure that sid parameter with is not included in the request parameters
    STAssertNil(theSignedParameters[@"sid"], @"sid parameter is not expected after KL locations"
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
    STAssertTrue([theSignedParameters[@"ktsids"] rangeOfString:theExpectedPair2].length == 0,
                @"The unexpected pair (%@) is found in the URL parameters", theExpectedPair2);
    
    // Check that the pairs are included in the final URL
    STAssertTrue([[theRequestURL.absoluteString stringByReplacingPercentEscapesUsingEncoding:
                NSUTF8StringEncoding] rangeOfString:theExpectedPair1].length > 0,
                @"The expected pair (%@) is not found in the URL parameters", theExpectedPair1);
    STAssertTrue([[theRequestURL.absoluteString stringByReplacingPercentEscapesUsingEncoding:
                NSUTF8StringEncoding] rangeOfString:theExpectedPair2].length == 0,
                @"The unexpected pair (%@) is found in the URL parameters", theExpectedPair2);

    // Make sure that sid parameter with is not included in the request parameters
    STAssertNil(theSignedParameters[@"sid"], @"sid parameter is not expected after KL locations"
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
    
    // Make sure that sid parameter with the primary SID is included in the request parameters
    STAssertEqualObjects(kPHTestSID1, theSignedParameters[@"sid"], @"The SID specified in the "
                "request doesn't match the expected one!");

    // Cleanup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];
}

- (void)testKTAPIKeySIDPairsCase4
{
    // Setup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];
    [PHKontagentDataAccessor storeSIDInPersistentValuesWithTypo:kPHTestSID2 forAPIKey:
                kPHTestAPIKey1];
    [PHKontagentDataAccessor storeSIDInUserDefaults:kPHTestSID1 forAPIKey:kPHTestAPIKey2];

    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    STAssertNotNil(theRequest, @"");

    NSURL *theRequestURL = [self URLForRequest:theRequest];
    NSDictionary *theSignedParameters = [theRequest signedParameters];
    
    NSString *theExpectedPair1 =
                @"{\"api\":\"f25a3b41dbcb4c13bd8d6b0b282eec32\",\"sid\":\"12256527677368061856\"}";
    NSString *theExpectedPair2 =
                @"{\"api\":\"d45a3b4c13bd82eec32b8d6b0b241dbc\",\"sid\":\"13565276206185677368\"}";

    // The expected structure of the ktsids parameter:
    // [{"api":"f25a3b41dbcb4c13bd8d6b0b282eec32","sid":"13565276206185677368"},
    // {"api":"d45a3b4c13bd82eec32b8d6b0b241dbc","sid":"12256527677368061856"}]
    
    STAssertTrue([theSignedParameters[@"ktsids"] hasPrefix:@"[{"], @"Unexpected structure of the "
                "of the 'ktsids' parameter value: %@", theSignedParameters[@"ktsids"]);
                
    STAssertTrue([theSignedParameters[@"ktsids"] rangeOfString:theExpectedPair1].length > 0,
                @"The expected pair (%@) is not found in the URL parameters", theExpectedPair1);
    STAssertTrue([theSignedParameters[@"ktsids"] rangeOfString:theExpectedPair2].length == 0,
                @"The unexpected pair (%@) is found in the URL parameters", theExpectedPair2);
    
    // Check that the pairs are included in the final URL
    STAssertTrue([[theRequestURL.absoluteString stringByReplacingPercentEscapesUsingEncoding:
                NSUTF8StringEncoding] rangeOfString:theExpectedPair1].length > 0,
                @"The expected pair (%@) is not found in the URL parameters", theExpectedPair1);
    STAssertTrue([[theRequestURL.absoluteString stringByReplacingPercentEscapesUsingEncoding:
                NSUTF8StringEncoding] rangeOfString:theExpectedPair2].length == 0,
                @"The unexpected pair (%@) is found in the URL parameters", theExpectedPair2);

    // Make sure that sid parameter with is not included in the request parameters
    STAssertNil(theSignedParameters[@"sid"], @"sid parameter is not expected after KL locations"
                " cleanup until it is set with -[PHKontagentDataAccessor "
                "storePrimarySenderID:forAPIKey:]!");
    
    // Cleanup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];
}

- (void)testKTAPIKeySIDPairsCase5
{
    // Setup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];
    [PHKontagentDataAccessor storeSIDInPersistentValues:kPHTestSID1 forAPIKey:kPHTestAPIKey1];
    [PHKontagentDataAccessor storeSIDInUserDefaults:kPHTestSID2 forAPIKey:kPHTestAPIKey2];
    [PHKontagentDataAccessor storeSIDInUserDefaults:kPHTestSID3 forAPIKey:kPHTestAPIKey3];

    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    STAssertNotNil(theRequest, @"");

    NSURL *theRequestURL = [self URLForRequest:theRequest];
    NSDictionary *theSignedParameters = [theRequest signedParameters];
    
    NSString *theExpectedPair1 =
                @"{\"api\":\"f25a3b41dbcb4c13bd8d6b0b282eec32\",\"sid\":\"13565276206185677368\"}";
    NSString *theExpectedPair2 =
                @"{\"api\":\"d45a3b4c13bd82eec32b8d6b0b241dbc\",\"sid\":\"12256527677368061856\"}";
    NSString *theExpectedPair3 =
                @"{\"api\":\"3bd82eed45a332b8d6b0b241dbcb4c1c\",\"sid\":\"73680618561225652767\"}";

    // The expected structure of the ktsids parameter:
    // [{"api":"f25a3b41dbcb4c13bd8d6b0b282eec32","sid":"13565276206185677368"},
    // {"api":"d45a3b4c13bd82eec32b8d6b0b241dbc","sid":"12256527677368061856"}]
    
    STAssertTrue([theSignedParameters[@"ktsids"] hasPrefix:@"[{"], @"Unexpected structure of the "
                "of the 'ktsids' parameter value: %@", theSignedParameters[@"ktsids"]);
                
    STAssertTrue([theSignedParameters[@"ktsids"] rangeOfString:theExpectedPair1].length > 0,
                @"The expected pair (%@) is not found in the URL parameters", theExpectedPair1);
    STAssertTrue([theSignedParameters[@"ktsids"] rangeOfString:theExpectedPair2].length == 0,
                @"The unexpected pair (%@) is found in the URL parameters", theExpectedPair2);
    STAssertTrue([theSignedParameters[@"ktsids"] rangeOfString:theExpectedPair3].length == 0,
                @"The unexpected pair (%@) is found in the URL parameters", theExpectedPair3);
    
    // Check that the pairs are included in the final URL
    STAssertTrue([[theRequestURL.absoluteString stringByReplacingPercentEscapesUsingEncoding:
                NSUTF8StringEncoding] rangeOfString:theExpectedPair1].length > 0,
                @"The expected pair (%@) is not found in the URL parameters", theExpectedPair1);
    STAssertTrue([[theRequestURL.absoluteString stringByReplacingPercentEscapesUsingEncoding:
                NSUTF8StringEncoding] rangeOfString:theExpectedPair2].length == 0,
                @"The unexpected pair (%@) is found in the URL parameters", theExpectedPair2);
    STAssertTrue([[theRequestURL.absoluteString stringByReplacingPercentEscapesUsingEncoding:
                NSUTF8StringEncoding] rangeOfString:theExpectedPair3].length == 0,
                @"The unexpected pair (%@) is found in the URL parameters", theExpectedPair3);

    // Make sure that sid parameter with is not included in the request parameters
    STAssertNil(theSignedParameters[@"sid"], @"sid parameter is not expected after KL locations"
                " cleanup until it is set with -[PHKontagentDataAccessor "
                "storePrimarySenderID:forAPIKey:]!");
    
    // Cleanup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];
}

- (void)testResponseWithNoSID
{
    // Cleanuo API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];

    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    STAssertNotNil(theRequest, @"");
    
    [theRequest didSucceedWithResponse:[self responseDictionaryWithJSONFileName:
                @"openRequestResponse"]];
    STAssertNil([[PHKontagentDataAccessor sharedAccessor] primarySenderID], @"Primary SID should "
                "not be set on response having no ktapi and ktsid key:value pairs!");
}

- (void)testResponseWithSID
{
    // Setup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];

    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    STAssertNotNil(theRequest, @"");
    
    // Expected SID should be the same as the one specified in the stub response
    NSString *theExpectedSID = @"5611190844015425273";
    [theRequest didSucceedWithResponse:[self responseDictionaryWithJSONFileName:
                @"openRequestResponseWithAPIKeyAndSID"]];
    STAssertEqualObjects(theExpectedSID,[[PHKontagentDataAccessor sharedAccessor] primarySenderID],
                @"Primary SID doesn't match the expected one specified in the in the response!");

    // Check that response without ktapi and ktsid key:value pairs doesn't discard the primary SID
    theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:kPHTestSecret];
    STAssertNotNil(theRequest, @"");
    
    [theRequest didSucceedWithResponse:[self responseDictionaryWithJSONFileName:
                @"openRequestResponse"]];
    STAssertEqualObjects(theExpectedSID,[[PHKontagentDataAccessor sharedAccessor] primarySenderID],
                @"Primary SID doesn't match the expected one specified in the in the response!");
}

- (void)testResponseWithNewAPIKey
{
    // Setup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];

    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    STAssertNotNil(theRequest, @"");
    
    // Expected SID should be the same as the one specified in the stub response
    NSString *theExpectedSID = @"5611190844015425273";
    NSDictionary *theResponseDictionary = [self responseDictionaryWithJSONFileName:
                @"openRequestResponseWithAPIKeyAndSID"];
    
    [theRequest didSucceedWithResponse:theResponseDictionary];
    STAssertEqualObjects(theExpectedSID,[[PHKontagentDataAccessor sharedAccessor] primarySenderID],
                @"Primary SID doesn't match the expected one specified in the in the response!");
    

    // Create one more request to check that new API key - SID successfully overrides the old one
    theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:kPHTestSecret];
    STAssertNotNil(theRequest, @"");
    
    NSMutableDictionary *theUpdatedResponse = [NSMutableDictionary dictionaryWithDictionary:
                theResponseDictionary];
    NSString *theNewSID = @"1140154190562527384";
    theUpdatedResponse[@"ktapi"] = @"467583e493c7895b6b5abea9c8155d4d";
    theUpdatedResponse[@"ktsid"] = theNewSID;
    
    [theRequest didSucceedWithResponse:theUpdatedResponse];
    STAssertEqualObjects(theNewSID,[[PHKontagentDataAccessor sharedAccessor] primarySenderID],
                @"Primary SID doesn't match the expected one specified in the in the response!");
}

- (void)testResponseWithMissedSID
{
    // Setup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];

    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    STAssertNotNil(theRequest, @"");
    
    NSMutableDictionary *theUpdatedResponse = [NSMutableDictionary dictionaryWithDictionary:
                [self responseDictionaryWithJSONFileName:@"openRequestResponse"]];
    theUpdatedResponse[@"ktapi"] = @"467583e493c7895b6b5abea9c8155d4d";
    
    [theRequest didSucceedWithResponse:theUpdatedResponse];
    STAssertNil([[PHKontagentDataAccessor sharedAccessor] primarySenderID], @"Primary SID should "
                "not be set on response with missed ktsid!");
}

- (void)testResponseWithMissedAPIKey
{
    // Setup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];

    PHPublisherOpenRequest *theRequest = [PHPublisherOpenRequest requestForApp:kPHTestToken secret:
                kPHTestSecret];
    STAssertNotNil(theRequest, @"");
    
    NSMutableDictionary *theUpdatedResponse = [NSMutableDictionary dictionaryWithDictionary:
                [self responseDictionaryWithJSONFileName:@"openRequestResponse"]];
    theUpdatedResponse[@"ktsid"] = @"1140154190562527384";
    
    [theRequest didSucceedWithResponse:theUpdatedResponse];
    STAssertNil([[PHKontagentDataAccessor sharedAccessor] primarySenderID], @"Primary SID should be"
                "not be set on response with missed ktapi!");
}

#pragma mark -

- (NSDictionary *)responseDictionaryWithJSONFileName:(NSString *)aFileName
{
    NSError *theError = nil;
    NSString *thetheStubResponse = [NSString stringWithContentsOfURL:[[NSBundle bundleForClass:
                [self class]] URLForResource:aFileName withExtension:@"json"] encoding:
                NSUTF8StringEncoding error:&theError];
    STAssertNotNil(thetheStubResponse, @"Cannot create data with stub response!");
    
    PH_SBJSONPARSER_CLASS *theParser = [[[PH_SBJSONPARSER_CLASS alloc] init] autorelease];
    NSDictionary *theResponseDictionary = [theParser objectWithString:thetheStubResponse];
    STAssertNotNil(thetheStubResponse, @"Cannot parse stub response!");

    return theResponseDictionary[@"response"];
}

@end
