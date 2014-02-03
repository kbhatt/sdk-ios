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

 PHKontagentDataAccessor.m
 playhaven-sdk-ios

 Created by Anton Fedorchenko on 1/31/14.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "PHKontagentDataAccessor.h"

static NSString *const kPHKontagentAPIKey = @"PHKontagentAPIKey";
static NSString *const kPHpersistentValuesFileName = @"PersistentValues";
static NSString *const kPHKontagentSenderIDKeyPrefix = @"com.kontagent.lib.SENDER_ID";

static PHKontagentDataAccessor *sSharedDataAccessor = nil;

@implementation PHKontagentDataAccessor

+ (instancetype)sharedAccessor
{
    @synchronized (self)
    {
        if (nil == sSharedDataAccessor)
        {
            sSharedDataAccessor = [PHKontagentDataAccessor new];
        }
    }
    
    return sSharedDataAccessor;
}

- (NSString *)primarySenderID
{
    NSString *theKTAPIKey = [[NSUserDefaults standardUserDefaults] stringForKey:kPHKontagentAPIKey];

    return nil == theKTAPIKey ? nil : [self senderIDForAPIKey:theKTAPIKey];
}

- (NSDictionary *)allAPIKeySenderIDPairs
{
    NSMutableDictionary *theCombinedPreferences = [NSMutableDictionary dictionaryWithDictionary:
                [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
    NSString *theAPIKeyPrefix = [NSString stringWithFormat:@"%@.", kPHKontagentSenderIDKeyPrefix];
    NSMutableDictionary *theAPIKeySIDPairs = [NSMutableDictionary dictionary];
    
    // API keys from PersistentValues override the ones stored in NSUserDefaults
    [theCombinedPreferences addEntriesFromDictionary:[self persistentValues]];
    
    for (NSString *theDefault in [theCombinedPreferences allKeys])
    {
        if ([theDefault isKindOfClass:[NSString class]] && [theDefault hasPrefix:theAPIKeyPrefix])
        {
            NSRange thePrefixRange = [theDefault rangeOfString:theAPIKeyPrefix];
            NSString *theAPIKey = [theDefault substringFromIndex:thePrefixRange.location +
                        thePrefixRange.length];
            
            theAPIKeySIDPairs[theAPIKey] = theCombinedPreferences[theDefault];
        }
    }
    
    return theAPIKeySIDPairs;
}

- (void)storePrimarySenderID:(NSString *)aSenderID forAPIKey:(NSString *)anAPIKey
{
    if (nil == aSenderID || nil == anAPIKey)
    {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:anAPIKey forKey:kPHKontagentAPIKey];

    // Do not override sender ID for the given API key.
    NSString *theStoredSenderID = [self senderIDForAPIKey:anAPIKey];
    if (nil == theStoredSenderID)
    {
        NSString *theSenderIDStoreKey = [self senderIDStoreKeyWithAPIKey:anAPIKey];
        [[NSUserDefaults standardUserDefaults] setObject:aSenderID forKey:theSenderIDStoreKey];
    }
}

#pragma mark -

- (NSDictionary *)persistentValues
{
    NSURL *theStoreURL = [[[[NSFileManager defaultManager] URLsForDirectory:
                NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject]
                URLByAppendingPathComponent:kPHpersistentValuesFileName];

    return [NSDictionary dictionaryWithContentsOfURL:theStoreURL];
}

- (NSString *)senderIDStoreKeyWithAPIKey:(NSString *)anAPIKey
{
    return [NSString stringWithFormat:@"%@.%@", kPHKontagentSenderIDKeyPrefix, anAPIKey];
}

- (NSString *)senderIDForAPIKey:(NSString *)anAPIKey
{
    NSDictionary *thePersistentValues = [self persistentValues];
    NSString *theSenderIDStoreKey = [self senderIDStoreKeyWithAPIKey:anAPIKey];
    NSString *theSenderID = thePersistentValues[theSenderIDStoreKey];
    
    if (nil == theSenderID)
    {
        // Look up in the NSUserDefauls as a fallback
        theSenderID = [[NSUserDefaults standardUserDefaults] stringForKey:theSenderIDStoreKey];
    }
    
    return theSenderID;
}

@end
