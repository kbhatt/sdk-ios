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

 PHKontagentDataAccessorTest.m
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 2/3/14.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import <SenTestingKit/SenTestingKit.h>
#import "PHKontagentDataAccessor.h"
#import "PHKontagentDataAccessor+Private.h"

static NSString *const kPHTestAPIKey1 = @"f25a3b41dbcb4c13bd8d6b0b282eec32";
static NSString *const kPHTestAPIKey2 = @"d45a3b4c13bd82eec32b8d6b0b241dbc";
static NSString *const kPHTestSID1 = @"13565276206185677368";
static NSString *const kPHTestSID2 = @"12256527677368061856";

@interface PHKontagentDataAccessorTest : SenTestCase
@end

@implementation PHKontagentDataAccessorTest

- (void)setUp
{
    [super setUp];

    PHKontagentDataAccessor *theSharedAccessor = [PHKontagentDataAccessor sharedAccessor];
    STAssertNotNil(theSharedAccessor, @"");
}

- (void)tearDown
{
    [self cleanupKTLocations];
    
    PHKontagentDataAccessor *theSharedAccessor = [PHKontagentDataAccessor sharedAccessor];
    STAssertNotNil(theSharedAccessor, @"");
    
    STAssertTrue(0 == [[theSharedAccessor allAPIKeySenderIDPairs] count], @"No API key - SID pair "
                "is expected after KT locations cleanup!");

    STAssertNil([theSharedAccessor primarySenderID], @"No primary SID is expected after KT "
                "locations cleanup!");

    [super tearDown];
}

- (void)testCreation
{
    PHKontagentDataAccessor *theSharedAccessor = [PHKontagentDataAccessor sharedAccessor];
    
    STAssertEqualObjects(theSharedAccessor, [PHKontagentDataAccessor sharedAccessor], @"Singleton "
                "instance should not change!");
}

- (void)testErrorHandling
{
    STAssertNoThrow([[PHKontagentDataAccessor sharedAccessor] storePrimarySenderID:nil forAPIKey:
                nil], @"The instace should gracefully process nil input parameters");
}

- (void)testDataAccessCase1
{
    [self storeSIDInPersistentValues:kPHTestSID1 forAPIKey:kPHTestAPIKey1];
    
    PHKontagentDataAccessor *theSharedAccessor = [PHKontagentDataAccessor sharedAccessor];

    STAssertEqualObjects(@{kPHTestAPIKey1 : kPHTestSID1}, [theSharedAccessor
                allAPIKeySenderIDPairs], @"Returned pair doesn't match the expected one!");

    STAssertNil([theSharedAccessor primarySenderID], @"No primary SID is expected before it is "
                "explicitly set!");

    [self storeSIDInPersistentValues:kPHTestSID2 forAPIKey:kPHTestAPIKey2];
    
    NSDictionary *thePairs = @{kPHTestAPIKey1 : kPHTestSID1, kPHTestAPIKey2 : kPHTestSID2};
    STAssertEqualObjects(thePairs, [theSharedAccessor allAPIKeySenderIDPairs], @"Returned pairs "
                "don't match the expected one!");

    STAssertNil([theSharedAccessor primarySenderID], @"No primary SID is expected before it is "
                "explicitly set!");
    
    [theSharedAccessor storePrimarySenderID:kPHTestSID1 forAPIKey:kPHTestAPIKey1];
    STAssertEqualObjects(kPHTestSID1, [theSharedAccessor primarySenderID], @"Primary SID doesn't "
                "match the expected one!");
    
    // Check that new SID doesn't override the previous one
    [theSharedAccessor storePrimarySenderID:@"76206113565285677368" forAPIKey:kPHTestAPIKey1];
    STAssertEqualObjects(kPHTestSID1, [theSharedAccessor primarySenderID], @"Primary SID doesn't "
                "match the expected one!");
}

- (void)testDataAccessCase2
{
    [self storeSIDInUserDefaults:kPHTestSID1 forAPIKey:kPHTestAPIKey1];
    
    PHKontagentDataAccessor *theSharedAccessor = [PHKontagentDataAccessor sharedAccessor];

    STAssertEqualObjects(@{kPHTestAPIKey1 : kPHTestSID1}, [theSharedAccessor
                allAPIKeySenderIDPairs], @"Returned pair doesn't match the expected one!");

    STAssertNil([theSharedAccessor primarySenderID], @"No primary SID is expected before it is "
                "explicitly set!");

    [self storeSIDInUserDefaults:kPHTestSID2 forAPIKey:kPHTestAPIKey2];
    
    NSDictionary *thePairs = @{kPHTestAPIKey1 : kPHTestSID1, kPHTestAPIKey2 : kPHTestSID2};
    STAssertEqualObjects(thePairs, [theSharedAccessor allAPIKeySenderIDPairs], @"Returned pairs "
                "don't match the expected one!");

    STAssertNil([theSharedAccessor primarySenderID], @"No primary SID is expected before it is "
                "explicitly set!");
    
    [theSharedAccessor storePrimarySenderID:kPHTestSID1 forAPIKey:kPHTestAPIKey1];
    STAssertEqualObjects(kPHTestSID1, [theSharedAccessor primarySenderID], @"Primary SID doesn't "
                "match the expected one!");
    
    // Check that new SID doesn't override the previous one
    [theSharedAccessor storePrimarySenderID:@"76206113565285677368" forAPIKey:kPHTestAPIKey1];
    STAssertEqualObjects(kPHTestSID1, [theSharedAccessor primarySenderID], @"Primary SID doesn't "
                "match the expected one!");
}

- (void)testDataAccessCase3
{
    [self storeSIDInPersistentValues:kPHTestSID1 forAPIKey:kPHTestAPIKey1];
    
    PHKontagentDataAccessor *theSharedAccessor = [PHKontagentDataAccessor sharedAccessor];

    STAssertEqualObjects(@{kPHTestAPIKey1 : kPHTestSID1}, [theSharedAccessor
                allAPIKeySenderIDPairs], @"Returned pair doesn't match the expected one!");

    STAssertNil([theSharedAccessor primarySenderID], @"No primary SID is expected before it is "
                "explicitly set!");

    [self storeSIDInUserDefaults:kPHTestSID2 forAPIKey:kPHTestAPIKey2];
    
    NSDictionary *thePairs = @{kPHTestAPIKey1 : kPHTestSID1, kPHTestAPIKey2 : kPHTestSID2};
    STAssertEqualObjects(thePairs, [theSharedAccessor allAPIKeySenderIDPairs], @"Returned pairs "
                "don't match the expected one!");

    STAssertNil([theSharedAccessor primarySenderID], @"No primary SID is expected before it is "
                "explicitly set!");
    
    [theSharedAccessor storePrimarySenderID:kPHTestSID1 forAPIKey:kPHTestAPIKey1];
    STAssertEqualObjects(kPHTestSID1, [theSharedAccessor primarySenderID], @"Primary SID doesn't "
                "match the expected one!");
    
    // Check that new SID doesn't override the previous one
    [theSharedAccessor storePrimarySenderID:@"76206113565285677368" forAPIKey:kPHTestAPIKey1];
    STAssertEqualObjects(kPHTestSID1, [theSharedAccessor primarySenderID], @"Primary SID doesn't "
                "match the expected one!");
}

#pragma mark - Private

- (void)cleanupKTLocations
{
    // Remove PersistentValues file.
    [[NSFileManager defaultManager] removeItemAtURL:[PHKontagentDataAccessor
                persistentValuesFileURL] error:nil];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPHKontagentAPIKey];

    NSMutableDictionary *theUserDefaults = [NSMutableDictionary dictionaryWithDictionary:
                [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
    
    // Cleanup all API key - Sender ID pairs in user defaults
    for (NSString *theDefault in [theUserDefaults allKeys])
    {
        if ([theDefault hasPrefix:kPHKontagentSenderIDKeyPrefix])
        {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:theDefault];
        }
    }
}

- (void)storeSIDInPersistentValues:(NSString *)aSID forAPIKey:(NSString *)aKey
{
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSURL *thePersistentValuesURL = [PHKontagentDataAccessor persistentValuesFileURL];
    NSError *theError = nil;

    if (![theFileManager fileExistsAtPath:[thePersistentValuesURL
                URLByDeletingLastPathComponent].path isDirectory:nil])
    {
        [theFileManager createDirectoryAtURL:[thePersistentValuesURL URLByDeletingLastPathComponent]
                    withIntermediateDirectories:YES attributes:nil error:&theError];

        STAssertNil(theError, @"Couldn't create Application Support folder: %@",
                    theError.localizedDescription);
    }

    NSMutableDictionary *theStoredValues = [NSMutableDictionary dictionaryWithContentsOfURL:
                thePersistentValuesURL];
    NSDictionary *theNewValues = @{[PHKontagentDataAccessor senderIDStoreKeyWithAPIKey:aKey] :
                aSID};
    
    if (nil != theStoredValues)
    {
        [theStoredValues addEntriesFromDictionary:theNewValues];
    }
    
    BOOL theResult = [(nil != theStoredValues ? theStoredValues : theNewValues) writeToURL:
                thePersistentValuesURL atomically:YES];

    STAssertTrue(theResult, @"Cannot write file to the KT location which is needed for the test!");
}

- (void)storeSIDInUserDefaults:(NSString *)aSID forAPIKey:(NSString *)aKey
{
    [[NSUserDefaults standardUserDefaults] setObject:aSID forKey:[PHKontagentDataAccessor
                senderIDStoreKeyWithAPIKey:aKey]];
}

@end
