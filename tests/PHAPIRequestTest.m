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

 PHAPIRequestTest.m
 playhaven-sdk-ios

 Created by Jesus Fernandez on 3/30/11.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <SenTestingKit/SenTestingKit.h>
#import "PHAPIRequest.h"
#import "PHConstants.h"
#import "PHStringUtil.h"
#import "PHPublisherOpenRequest.h"
#import "PHAPIRequest+Private.h"
#import "SenTestCase+PHAPIRequestSupport.h"
#import "PHKontagentDataAccessor+UnitTesting.h"

#define PUBLISHER_TOKEN @"PUBLISHER_TOKEN"
#define PUBLISHER_SECRET @"PUBLISHER_SECRET"

#define HASH_STRING  @"DEVICE_ID:PUBLISHER_TOKEN:PUBLISHER_SECRET:NONCE"
#define EXPECTED_HASH @"3L0xlrDOt02UrTDwMSnye05Awwk"

static NSString *const kPHTestAPIKey1 = @"f25a3b41dbcb4c13bd8d6b0b282eec32";
static NSString *const kPHTestAPIKey2 = @"d45a3b4c13bd82eec32b8d6b0b241dbc";
static NSString *const kPHTestSID1 = @"13565276206185677368";
static NSString *const kPHTestSID2 = @"12256527677368061856";

@interface PHAPIRequest (Private)
+ (NSMutableSet *)allRequests;
+ (void)setSession:(NSString *)session;
- (void)processRequestResponse:(NSDictionary *)response;
@end

@interface PHAPIRequestTest : SenTestCase @end
@interface PHAPIRequestResponseTest : SenTestCase <PHAPIRequestDelegate> {
    PHAPIRequest *_request;
    BOOL _didProcess;
}
@end
@interface PHAPIRequestErrorTest : SenTestCase <PHAPIRequestDelegate> {
    PHAPIRequest *_request;
    BOOL _didProcess;
}
@end
@interface PHAPIRequestByHashCodeTest : SenTestCase @end

@implementation PHAPIRequestTest

- (void)setUp
{
    [super setUp];

    // Cancel request to remove it from the cache
    [[PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET] cancel];
}

- (void)testSignatureHash
{
    NSString *signatureHash = [PHAPIRequest base64SignatureWithString:HASH_STRING];
    STAssertTrue([EXPECTED_HASH isEqualToString:signatureHash],
                 @"Hash mismatch. Expected %@ got %@",EXPECTED_HASH,signatureHash);
}

- (void)testResponseDigestVerification
{
    /*
     For this test expected digest hashes were generated using pyton's hmac library.
     */
    NSString *responseDigest, *expectedDigest;

    // Digest with nonce
    responseDigest = [PHAPIRequest expectedSignatureValueForResponse:@"response body" nonce:@"nonce" secret:PUBLISHER_SECRET];
    expectedDigest = @"rt3JHGReRAaol-xPVildr6Ev9fU=";
    STAssertTrue([responseDigest isEqualToString:expectedDigest], @"Digest mismatch. Expected %@ got %@", expectedDigest, responseDigest);

    // Digest without nonce
    responseDigest = [PHAPIRequest expectedSignatureValueForResponse:@"response body" nonce:nil secret:PUBLISHER_SECRET];
    expectedDigest = @"iNmo12xRqVAn_7quEvOSwhenEZA=";
    STAssertTrue([responseDigest isEqualToString:expectedDigest], @"Digest mismatch. Expected %@ got %@", expectedDigest, responseDigest);
}

- (void)testRequestParameters
{
    [PHAPIRequest setSession:@"test_session"];
    
    PHAPIRequest *request = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    
    NSNumber *theNetworkStatus = @(PHNetworkStatus());
    
    NSString *theRequestURL = [[self URLForRequest:request] absoluteString];
    NSDictionary *signedParameters = [request signedParameters];

    // Test for existence of parameters
    NSString
        *session   = [signedParameters valueForKey:@"session"],
        *token     = [signedParameters valueForKey:@"token"],
        *signature = [signedParameters valueForKey:@"sig4"],
        *nonce     = [signedParameters valueForKey:@"nonce"];

    STAssertEqualObjects(theNetworkStatus, signedParameters[@"connection"], @"Network status "
                "indicated by the request object doesn't match the expected one!");
    STAssertNotNil(session, @"Required session param is missing!");
    STAssertNotNil(token, @"Required token param is missing!");
    STAssertTrue(0 < [signature length], @"Required signature param is missing!");
    STAssertNotNil(nonce, @"Required nonce param is missing!");

    NSString *parameterString = [request signedParameterString];
    STAssertNotNil(parameterString, @"Parameter string is nil?");

    NSString *tokenParam = [NSString stringWithFormat:@"token=%@",token];
    STAssertFalse([parameterString rangeOfString:tokenParam].location == NSNotFound,
                  @"Token parameter not present!");

    NSString *signatureParam = [NSString stringWithFormat:@"sig4=%@",signature];
    STAssertFalse([parameterString rangeOfString:signatureParam].location == NSNotFound,
                  @"Signature parameter not present!");

    NSString *nonceParam = [NSString stringWithFormat:@"nonce=%@",nonce];
    STAssertFalse([parameterString rangeOfString:nonceParam].location == NSNotFound,
                  @"Nonce parameter not present!");

    NSString *theConnectionParam = [NSString stringWithFormat:@"connection=%@", theNetworkStatus];
    STAssertFalse([theRequestURL rangeOfString:theConnectionParam].length == 0,
                  @"Expected connection parameter is missed in the request URL!");
    
    // Test IDFV parameter

    NSString *theIDFV = signedParameters[@"idfv"];
    NSString *theIDFA = signedParameters[@"ifa"];
    NSNumber *theAdTrackingFlag = signedParameters[@"tracking"];

    if (PH_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        NSString *theExpectedIDFV = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSUUID *theUUID = [[ASIdentifierManager sharedManager] advertisingIdentifier];
        NSString *theExpectedIDFA = [theUUID UUIDString];
        NSNumber *theExpectedAdTrackingFlag = @([[ASIdentifierManager sharedManager]
                    isAdvertisingTrackingEnabled]);

        STAssertEqualObjects(theIDFV, theExpectedIDFV, @"Invalid IDFV value!");
        STAssertEqualObjects(theIDFA, theExpectedIDFA, @"Invalid IDFA value!");
        STAssertEqualObjects(theAdTrackingFlag, theExpectedAdTrackingFlag, @"Incorect Ad tracking "
                    "value");
        
        NSString *theIDFVParameter = [NSString stringWithFormat:@"idfv=%@", theIDFV];
        STAssertTrue([theRequestURL rangeOfString:theIDFVParameter].length > 0, @"IDFV is missed"
                    " from the request URL");

        NSString *theIDFAParameter = [NSString stringWithFormat:@"ifa=%@", theIDFA];
        STAssertTrue([theRequestURL rangeOfString:theIDFAParameter].length > 0, @"IDFA is missed"
                    " from the request URL");
    }
    else
    {
        STAssertNil(theIDFV, @"IDFV is not available on iOS earlier than 6.0.");
        STAssertNil(theIDFA, @"IDFA is not available on iOS earlier than 6.0.");
        STAssertNil(theAdTrackingFlag, @"Ad tracking flag isn't available on iOS earlier than 6.0");

        STAssertTrue([theRequestURL rangeOfString:@"idfv="].length == 0, @"This parameter should "
                    "be omitted on system < 6.0.");
        STAssertTrue([theRequestURL rangeOfString:@"ifa="].length == 0, @"This parameter should "
                    "be omitted on system < 6.0.");
        STAssertTrue([theRequestURL rangeOfString:@"tracking="].length == 0, @"This parameter "
                    "should be omitted on system < 6.0.");
    }
}

- (void)testMACParameterCase1
{
    // Set opt-out status to NO to get a full set of request parameters.
    [PHAPIRequest setOptOutStatus:NO];

    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];
    NSString *theMAC = [theSignedParameters objectForKey:@"mac"];

#if PH_USE_MAC_ADDRESS == 1
    // MAC should be sent on iOS 5 and earlier.
    if (PH_SYSTEM_VERSION_LESS_THAN(@"6.0"))
    {

        STAssertNotNil(theMAC, @"MAC param is missing!");
        STAssertFalse([theRequestURL rangeOfString:@"mac="].location == NSNotFound, @"MAC "
                    "param is missing: %@", theRequestURL);
    }
    else
    {
        NSString *theUnexpectedMACMessage = @"MAC should not be sent on iOS 6 and later";

        STAssertNil([theSignedParameters objectForKey:@"mac"], @"%@!", theUnexpectedMACMessage);
        STAssertTrue([theRequestURL rangeOfString:@"mac="].length == 0, @"%@: %@",
                    theUnexpectedMACMessage, theRequestURL);
    }
#else
    STAssertNil(theMAC, @"MAC param is present!");
    STAssertTrue([theRequestURL rangeOfString:@"mac="].location == NSNotFound, @"MAC param "
                "exists when it shouldn't: %@", theRequestURL);
#endif
}

- (void)testMACParameterCase2
{
    // Set opt-out status to YES to get request parameters without MAC.
    [PHAPIRequest setOptOutStatus:YES];

    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];

    NSString *theUnexpectedMACMessage = @"MAC should not be sent for opted out users";

    STAssertNil([theSignedParameters objectForKey:@"mac"], @"%@!", theUnexpectedMACMessage);
    STAssertTrue([theRequestURL rangeOfString:@"mac="].length == 0, @"%@: %@",
                theUnexpectedMACMessage, theRequestURL);
}

- (void)testIDFAParameterWithOptedInUser
{
    // User is opted in
    [PHAPIRequest setOptOutStatus:NO];
    
    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];

    NSString *theIDFA = theSignedParameters[@"ifa"];

    if (PH_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        STAssertTrue([theIDFA length] > 0, @"Invalid IDFA value: %@", theIDFA);

        NSString *theIDFAParameter = [NSString stringWithFormat:@"ifa=%@", theIDFA];
        STAssertTrue([theRequestURL rangeOfString:theIDFAParameter].length > 0, @"IDFA is missed"
                    " from the request URL");
    
    }
    else
    {
        STAssertNil(theIDFA, @"IDFA is not available on iOS earlier than 6.0.");
        STAssertTrue([theRequestURL rangeOfString:@"ifa="].length == 0, @"This parameter should "
                    "be omitted on system < 6.0.");
    }
}

- (void)testIDFAParameterWithOptedOutUser
{
    // User is opted in
    [PHAPIRequest setOptOutStatus:YES];
    
    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];

    NSString *theIDFA = theSignedParameters[@"ifa"];

    STAssertNil(theIDFA, @"IDFA should not be sent for opted out users!");
    STAssertTrue([theRequestURL rangeOfString:@"ifa="].length == 0, @"This parameter should "
                "not be sent for opted out users!");
    
    // Revert opt-out status
    [PHAPIRequest setOptOutStatus:NO];
}

- (void)testOptedInUser
{
    // User is opted-in.
    [PHAPIRequest setOptOutStatus:NO];

    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];
    
    STAssertEqualObjects(theSignedParameters[@"opt_out"], @(NO), @"Incorrect opt-out value!");
    STAssertTrue([theRequestURL rangeOfString:@"opt_out=0"].length > 0, @"Incorrect opt-out "
                "value!");
}

- (void)testOptedOutUser
{
    // User is opted-out.
    [PHAPIRequest setOptOutStatus:YES];

    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];

    STAssertEqualObjects(theSignedParameters[@"opt_out"], @(YES), @"Incorrect opt-out value!");
    STAssertTrue([theRequestURL rangeOfString:@"opt_out=1"].length > 0, @"Incorrect opt-out "
                "value!");

    // Revert out-out status.
    [PHAPIRequest setOptOutStatus:NO];
}

- (void)testCustomRequestParameters
{
    NSDictionary *signedParameters;
    PHAPIRequest *request = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];

    // Test what happens when they are not set
    NSString
        *customUDID       = [PHAPIRequest customUDID],
        *pluginIdentifier = [PHAPIRequest pluginIdentifier],
        *requestURLString = [[self URLForRequest:request] absoluteString];

    STAssertTrue([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                  @"Custom parameter exists when none should be set.");
    STAssertNil(customUDID, @"Custom UDID param is not nil!");
    STAssertNotNil(pluginIdentifier, @"Plugin identifier param is missing!");
    STAssertTrue([pluginIdentifier isEqualToString:@"ios"], @"Plugin identifier param is incorrect!");

    // Test what happens when they are set to nil
    [PHAPIRequest setCustomUDID:nil];
    [PHAPIRequest setPluginIdentifier:nil];

    request          = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    requestURLString = [[self URLForRequest:request] absoluteString];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    STAssertTrue([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                  @"Custom parameter exists when none should be set.");
    STAssertNil(customUDID, @"Custom UDID param is not nil!");
    STAssertNotNil(pluginIdentifier, @"Plugin identifier param is missing!");
    STAssertTrue([pluginIdentifier isEqualToString:@"ios"], @"Plugin identifier param is incorrect!");

    // Test what happens when they are set to empty strings
    [PHAPIRequest setCustomUDID:@""];
    [PHAPIRequest setPluginIdentifier:@""];

    request          = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    requestURLString = [[self URLForRequest:request] absoluteString];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    STAssertTrue([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                  @"Custom parameter exists when none should be set.");
    STAssertNil(customUDID, @"Custom UDID param is not nil!");
    STAssertNotNil(pluginIdentifier, @"Plugin identifier param is missing!");
    STAssertTrue([pluginIdentifier isEqualToString:@"ios"], @"Plugin identifier param is incorrect!");

    // Test what happens when they are set to [NSNull null]
    [PHAPIRequest setCustomUDID:(id)[NSNull null]];
    [PHAPIRequest setPluginIdentifier:(id)[NSNull null]];

    request          = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    requestURLString = [[self URLForRequest:request] absoluteString];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    STAssertTrue([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                  @"Custom parameter exists when none should be set.");
    STAssertNil(customUDID, @"Custom UDID param is not nil!");
    STAssertNotNil(pluginIdentifier, @"Plugin identifier param is missing!");
    STAssertTrue([pluginIdentifier isEqualToString:@"ios"], @"Plugin identifier param is incorrect!");

    // Test what happens when they are longer than the allowed amount for plugin identifier (42)
    [PHAPIRequest setCustomUDID:@"12345678911234567892123456789312345678941234567895"];
    [PHAPIRequest setPluginIdentifier:@"12345678911234567892123456789312345678941234567895"];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    STAssertTrue([customUDID isEqualToString:@"12345678911234567892123456789312345678941234567895"],
                 @"Custom UDID param is not 42 characters!"); // Stays the same...
    STAssertTrue([pluginIdentifier isEqualToString:@"123456789112345678921234567893123456789412"],
                 @"Plugin identifier param is not 42 characters!"); // Trimmed...
    STAssertTrue([pluginIdentifier length], @"Plugin identifier param is not 42 characters!");


    // Test what happens when they have mixed reserved characters
    [PHAPIRequest setCustomUDID:@"abcdefg:?#[]@/!$&'()*+,;=\"abcdefg"];
    [PHAPIRequest setPluginIdentifier:@"abcdefg:?#[]@/!$&'()*+,;=\"abcdefg"];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    STAssertTrue([customUDID isEqualToString:@"abcdefgabcdefg"],
                 @"Custom UDID param is not stripped of reserved characters properly!"); // Stripped...
    STAssertTrue([pluginIdentifier isEqualToString:@"abcdefgabcdefg"],
                 @"Plugin identifier param is not stripped of reserved characters properly!"); // Stripped...

    // Test what happens when they have mixed reserved characters and at length 42 after
    [PHAPIRequest setCustomUDID:@"1234567891123456789212345678931234567894:?#[]@/!$&'()*+,;=\"12"];
    [PHAPIRequest setPluginIdentifier:@"1234567891123456789212345678931234567894:?#[]@/!$&'()*+,;=\"12"];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    STAssertTrue([customUDID isEqualToString:@"123456789112345678921234567893123456789412"],
                 @"Custom UDID param is not stripped of reserved characters properly!");
    STAssertTrue([pluginIdentifier isEqualToString:@"123456789112345678921234567893123456789412"],
                 @"Plugin identifier param is not stripped of reserved characters properly!");

    // Test what happens when they have mixed reserved characters and over length 42 after
    [PHAPIRequest setCustomUDID:@"1234567891123456789212345678931234567894:?#[]@/!$&'()*+,;=\"1234567895"];
    [PHAPIRequest setPluginIdentifier:@"1234567891123456789212345678931234567894:?#[]@/!$&'()*+,;=\"1234567895"];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    STAssertTrue([customUDID isEqualToString:@"12345678911234567892123456789312345678941234567895"],
                 @"Custom UDID param is not stripped of reserved characters properly!"); // Stripped
    STAssertTrue([pluginIdentifier isEqualToString:@"123456789112345678921234567893123456789412"],
                 @"Plugin identifier param is not stripped of reserved characters properly!"); // Stripped and trimmed

    // Test what happens when it's only reserved characters
    [PHAPIRequest setCustomUDID:@":?#[]@/!$&'()*+,;=\""];
    [PHAPIRequest setPluginIdentifier:@":?#[]@/!$&'()*+,;=\""];

    request          = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    requestURLString = [[self URLForRequest:request] absoluteString];

    customUDID       = [PHAPIRequest customUDID];
    pluginIdentifier = [PHAPIRequest pluginIdentifier];

    STAssertTrue([requestURLString rangeOfString:@"d_custom="].location == NSNotFound,
                  @"Custom parameter exists when none should be set.");
    STAssertNil(customUDID, @"Custom UDID param is not nil!");
    STAssertNotNil(pluginIdentifier, @"Plugin identifier param is missing!");
    STAssertTrue([pluginIdentifier isEqualToString:@"ios"], @"Plugin identifier param is incorrect!");

    // Test PHPublisherOpenRequest.customUDID property and PHAPIRequest property and class methods
    PHPublisherOpenRequest *openRequest = [PHPublisherOpenRequest requestForApp:PUBLISHER_TOKEN
                                                                         secret:PUBLISHER_SECRET];

    [openRequest setCustomUDID:@"one"];

    request          = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    requestURLString = [[self URLForRequest:request] absoluteString];
    signedParameters = [request signedParameters];
    customUDID       = [signedParameters valueForKey:@"d_custom"];

    STAssertFalse([requestURLString rangeOfString:@"d_custom="].location == NSNotFound, @"Custom parameter missing when one is set.");
    STAssertTrue([customUDID isEqualToString:@"one"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be one", customUDID);

    customUDID       = [PHAPIRequest customUDID];
    STAssertTrue([customUDID isEqualToString:@"one"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be one", customUDID);

    customUDID       = [request customUDID];
    STAssertTrue([customUDID isEqualToString:@"one"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be one", customUDID);

    customUDID       = [openRequest customUDID];
    STAssertTrue([customUDID isEqualToString:@"one"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be one", customUDID);

    [PHAPIRequest setCustomUDID:@"two"];

    request          = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    requestURLString = [[self URLForRequest:request] absoluteString];
    signedParameters = [request signedParameters];
    customUDID       = [signedParameters valueForKey:@"d_custom"];

    STAssertFalse([requestURLString rangeOfString:@"d_custom="].location == NSNotFound, @"Custom parameter missing when one is set.");
    STAssertTrue([customUDID isEqualToString:@"two"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be two", customUDID);

    customUDID       = [PHAPIRequest customUDID];
    STAssertTrue([customUDID isEqualToString:@"two"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be two", customUDID);

    customUDID       = [request customUDID];
    STAssertTrue([customUDID isEqualToString:@"two"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be two", customUDID);

    customUDID       = [openRequest customUDID];
    STAssertTrue([customUDID isEqualToString:@"two"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be two", customUDID);

    [request setCustomUDID:@"three"];

    request          = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    requestURLString = [[self URLForRequest:request] absoluteString];
    signedParameters = [request signedParameters];
    customUDID       = [signedParameters valueForKey:@"d_custom"];

    STAssertFalse([requestURLString rangeOfString:@"d_custom="].location == NSNotFound, @"Custom parameter missing when one is set.");
    STAssertTrue([customUDID isEqualToString:@"three"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be three", customUDID);

    customUDID       = [PHAPIRequest customUDID];
    STAssertTrue([customUDID isEqualToString:@"three"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be three", customUDID);

    customUDID       = [request customUDID];
    STAssertTrue([customUDID isEqualToString:@"three"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be three", customUDID);

    customUDID       = [openRequest customUDID];
    STAssertTrue([customUDID isEqualToString:@"three"],
                  @"Custom UDID isn't synced between base PHAPIRequest and PHPublisherOpenRequest: is %@ and should be three", customUDID);
}

- (void)testURLProperty
{
    PHAPIRequest *request = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    NSString     *desiredURLString = @"http://thisisatesturlstring.com";

    request.urlPath = desiredURLString;
    NSURL *theRequestURL = [self URLForRequest:request];
    STAssertFalse([[theRequestURL absoluteString] rangeOfString:desiredURLString].location == NSNotFound,
                  @"urlPath not present in signed URL!");

}

- (void)testSession
{
    STAssertNoThrow([PHAPIRequest setSession:@"test_session"], @"setting a session shouldn't throw an error");
    STAssertNoThrow([PHAPIRequest setSession:nil], @"clearing a session shouldn't throw");
}

- (void)testV4Signature
{
    // Case 1: Check signature generation with arbitrary identifiers.
    NSDictionary *theIdentifiers = @{ @"device": @"1111", @"ifa" : @"2222",
                @"mac" : @"beefbeefbeef", @"odin" : @"3333"};
    
    NSString *theSignature = [PHAPIRequest v4SignatureWithIdentifiers:theIdentifiers token:
                @"app-token" nonce:@"12345" signatureKey:@"app-secret"];
    STAssertEqualObjects(theSignature, @"ULwcjDFMPwhMCsZs-78HVjyAD-s", @"Incorect signature");
    
    // Case 2: Check signature generation with empty list of identifiers.
    theIdentifiers = @{};
    theSignature = [PHAPIRequest v4SignatureWithIdentifiers:theIdentifiers token:@"app-token" nonce:
                @"12345" signatureKey:@"app-secret"];
    STAssertEqualObjects(theSignature, @"yo9XmQWA5iISpqVwE-zNgkWZ7ZI", @"Incorect signature");

    // Case 3: Check signature generation with nil identifiers.
    theSignature = [PHAPIRequest v4SignatureWithIdentifiers:nil token:@"app-token" nonce:@"12345"
                signatureKey:@"app-secret"];
    STAssertEqualObjects(theSignature, @"yo9XmQWA5iISpqVwE-zNgkWZ7ZI", @"Incorect signature");
    
    // Case 4: Check that signature is nil if required parameter is missed.
    theSignature = [PHAPIRequest v4SignatureWithIdentifiers:nil token:nil nonce:@"12345"
                signatureKey:@"app-secret"];
    STAssertNil(theSignature, @"Signature should be nil if application token is not specified.");

    // Case 5: Check that signature is nil if required parameter is missed.
    theSignature = [PHAPIRequest v4SignatureWithIdentifiers:nil token:@"app-token" nonce:nil
                signatureKey:@"app-secret"];
    STAssertNil(theSignature, @"Signature should be nil if nonce is not specified.");

    // Case 6: Check that signature is nil if required parameter is missed.
    theSignature = [PHAPIRequest v4SignatureWithIdentifiers:nil token:@"app-token" nonce:@"12345"
                signatureKey:nil];
    STAssertNil(theSignature, @"Signature should be nil if signature key is not specified.");
}

- (void)testOptOutStatus
{
    [PHAPIRequest setOptOutStatus:YES];
    STAssertTrue([PHAPIRequest optOutStatus], @"Incorrect opt-out status!");

    [PHAPIRequest setOptOutStatus:NO];
    STAssertFalse([PHAPIRequest optOutStatus], @"Incorrect opt-out status!");
}

- (void)testDefaultOptOutStatus
{
    // Clean up possible changes of the opt-out status to test default value.
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PlayHavenOptOutStatus"];

    // This check relies on the presence of the PHDefaultUserIsOptedOut key in the app info
    // dictionary.
    STAssertTrue([PHAPIRequest optOutStatus], @"Incorrect default opt-out status!");
    
    [PHAPIRequest setOptOutStatus:NO];
    STAssertFalse([PHAPIRequest optOutStatus], @"Incorrect default opt-out status!");
}

- (void)testHTTPMethod
{
    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    STAssertNotNil(theRequest, @"");
    
    STAssertEquals(PHRequestHTTPGet, theRequest.HTTPMethod, @"Default HTTPMethod doesn't match the "
                "expected one!");
}

- (void)testKTSIDParameterCase1
{
    // Cleanup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];

    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    STAssertNotNil(theRequest, @"");
    
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];

    // Check that after cleanup sid is not included in the request parameters
    STAssertNil(theSignedParameters[@"sid"], @"No sid parameter is expected after KT locations "
                "cleanup!");
    STAssertTrue(0 == [theRequestURL rangeOfString:@"sid"].length, @"No sid parameter is "
                "expected after KT locations cleanup!");
}

- (void)testKTSIDParameterCase2
{
    // Setup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];
    [PHKontagentDataAccessor storeSIDInPersistentValues:kPHTestSID1 forAPIKey:kPHTestAPIKey1];
    [PHKontagentDataAccessor storeSIDInUserDefaults:kPHTestSID2 forAPIKey:kPHTestAPIKey2];
    
    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    STAssertNotNil(theRequest, @"");
    
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];

    // Check that after cleanup sid is not included in the request parameters
    STAssertNil(theSignedParameters[@"sid"], @"No sid parameter is expected until primary SID "
                "is defined!");
    STAssertTrue(0 == [theRequestURL rangeOfString:@"sid"].length, @"No sid parameter is expected "
                "until primary SID is defined!");
}

- (void)testKTSIDParameterCase3
{
    // Setup API keys and SIDs in KT locations
    [PHKontagentDataAccessor cleanupKTLocations];
    [PHKontagentDataAccessor storeSIDInPersistentValues:kPHTestSID1 forAPIKey:kPHTestAPIKey1];
    [PHKontagentDataAccessor storeSIDInUserDefaults:kPHTestSID2 forAPIKey:kPHTestAPIKey2];
    
    [[PHKontagentDataAccessor sharedAccessor] storePrimarySenderID:kPHTestSID1 forAPIKey:
                kPHTestAPIKey1];
    
    PHAPIRequest *theRequest = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    STAssertNotNil(theRequest, @"");
    
    NSString *theRequestURL = [[self URLForRequest:theRequest] absoluteString];
    NSDictionary *theSignedParameters = [theRequest signedParameters];

    // Check that primary SID is included in the request parameters
    STAssertEqualObjects(kPHTestSID1, theSignedParameters[@"sid"] , @"Missed sid parameter!");
    STAssertTrue(0 < [theRequestURL rangeOfString:@"sid"].length, @"Missed sid parameter!");
    
    // Check that primary SID is included in the request signature
    STAssertEqualObjects(kPHTestSID1, [PHAPIRequest identifiers][@"sid"], @"Missed sid parameter!");

    NSString *theExpectedSignature = [PHAPIRequest v4SignatureWithIdentifiers:[PHAPIRequest
                identifiers] token:[theRequest signedParameters][@"token"] nonce:[theRequest
                signedParameters][@"nonce"] signatureKey:theRequest.secret];
    
    STAssertEqualObjects(theExpectedSignature, [theRequest signedParameters][@"sig4"],
                @"Request signature doesn't match the expected one!");
}

@end

@implementation PHAPIRequestResponseTest

- (void)setUp
{
    _request = [[PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET] retain];
    _request.delegate = self;
    _didProcess = NO;
}

- (void)testResponse
{
    NSDictionary *testDictionary     = [NSDictionary dictionaryWithObjectsAndKeys:
                                                            @"awesomesause", @"awesome", nil];
    NSDictionary *responseDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                            testDictionary,@"response",
                                                            [NSNull null],@"error",
                                                            [NSNull null],@"errobj", nil];
    [_request processRequestResponse:responseDictionary];
}

- (void)request:(PHAPIRequest *)request didSucceedWithResponse:(NSDictionary *)responseData
{
    STAssertNotNil(responseData, @"Expected responseData, got nil!");
    STAssertTrue([[responseData allKeys] count] == 1, @"Unexpected number of keys in response data!");
    STAssertTrue([@"awesomesause" isEqualToString:[responseData valueForKey:@"awesome"]],
                 @"Expected 'awesomesause' got %@",
                 [responseData valueForKey:@"awesome"]);
    _didProcess = YES;
}

- (void)request:(PHAPIRequest *)request didFailWithError:(NSError *)error
{
    STFail(@"Request failed with error, but it wasn't supposed to!");
}

- (void)tearDown
{
    STAssertTrue(_didProcess, @"Did not actually process request!");
}

- (void)dealloc
{
    [_request release], _request = nil;
    [super dealloc];
}
@end

@implementation PHAPIRequestErrorTest

- (void)setUp
{
    _request = [[PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET] retain];
    _request.delegate = self;
    _didProcess = NO;
}

- (void)testResponse
{
    NSDictionary *responseDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"this is awesome!",@"error", nil];
    [_request processRequestResponse:responseDictionary];
}

- (void)request:(PHAPIRequest *)request didSucceedWithResponse:(NSDictionary *)responseData
{
    STFail(@"Request failed succeeded, but it wasn't supposed to!");
}

- (void)request:(PHAPIRequest *)request didFailWithError:(NSError *)error
{
    STAssertNotNil(error, @"Expected error but got nil!");
    _didProcess = YES;
}

- (void)tearDown
{
    STAssertTrue(_didProcess, @"Did not actually process request!");
}
@end

@implementation PHAPIRequestByHashCodeTest

- (void)testRequestByHashCode
{
    int hashCode = 100;

    PHAPIRequest *request = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    request.hashCode = hashCode;

    PHAPIRequest *retrievedRequest = [PHAPIRequest requestWithHashCode:hashCode];
    STAssertTrue(request == retrievedRequest, @"Request was not able to be retrieved by hashCode.");
    STAssertNil([PHAPIRequest requestWithHashCode:hashCode+1], @"Non-existent hashCode returned a request.");

    [request cancel];
    STAssertNil([PHAPIRequest requestWithHashCode:hashCode], @"Canceled request was retrieved by hashCode");
}

- (void)testRequestCancelByHashCode
{
    int hashCode = 200;

    PHAPIRequest *request = [PHAPIRequest requestForApp:PUBLISHER_TOKEN secret:PUBLISHER_SECRET];
    request.hashCode = hashCode;

    STAssertTrue([PHAPIRequest cancelRequestWithHashCode:hashCode] == 1, @"Request was not canceled!");
    STAssertTrue([PHAPIRequest cancelRequestWithHashCode:hashCode] == 0, @"Canceled request was canceled again.");
    STAssertTrue([PHAPIRequest cancelRequestWithHashCode:hashCode+1] == 0, @"Nonexistent request was canceled.");
    STAssertFalse([[PHAPIRequest allRequests] containsObject:request], @"Request was not removed from request array!");
}
@end
