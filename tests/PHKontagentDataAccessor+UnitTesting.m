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

 PHKontagentDataAccessor+UnitTesting.h
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 2/3/14
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "PHKontagentDataAccessor+UnitTesting.h"
#import "PHKontagentDataAccessor+Private.h"

@implementation PHKontagentDataAccessor (UnitTesting)

+ (void)cleanupKTLocations
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
    
    PHKontagentDataAccessor *theSharedAccessor = [PHKontagentDataAccessor sharedAccessor];
    
    NSAssert(0 == [[theSharedAccessor allAPIKeySenderIDPairs] count], @"%s: No API key - SID pair "
                "is expected after KT locations cleanup!", __PRETTY_FUNCTION__);

    NSAssert(nil == [theSharedAccessor primarySenderID], @"%s: No primary SID is expected after KT "
                "locations cleanup!", __PRETTY_FUNCTION__);
}

+ (void)storeSIDInPersistentValues:(NSString *)aSID forAPIKey:(NSString *)aKey
{
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSURL *thePersistentValuesURL = [PHKontagentDataAccessor persistentValuesFileURL];
    NSError *theError = nil;

    if (![theFileManager fileExistsAtPath:[thePersistentValuesURL
                URLByDeletingLastPathComponent].path isDirectory:nil])
    {
        [theFileManager createDirectoryAtURL:[thePersistentValuesURL URLByDeletingLastPathComponent]
                    withIntermediateDirectories:YES attributes:nil error:&theError];

        NSAssert(nil == theError, @"%s: Couldn't create Application Support folder: %@",
                    __PRETTY_FUNCTION__, theError.localizedDescription);
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

    NSAssert(theResult, @"%s: Cannot write file to the KT location which is needed for the test!",
                __PRETTY_FUNCTION__);
}

+ (void)storeSIDInUserDefaults:(NSString *)aSID forAPIKey:(NSString *)aKey
{
    [[NSUserDefaults standardUserDefaults] setObject:aSID forKey:[PHKontagentDataAccessor
                senderIDStoreKeyWithAPIKey:aKey]];
}

@end
