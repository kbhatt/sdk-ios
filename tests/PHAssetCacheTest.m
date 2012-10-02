//
//  PHAssetCacheTest.m
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 10/2/12.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import <Foundation/Foundation.h>
#import "PHAssetCache.h"
@interface PHAssetCacheTest : SenTestCase
@end

@implementation PHAssetCacheTest
-(void)testAsset{
    NSString *dataString = @"data";
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:@"http://playhaven.com"];
    NSURLResponse *response = [[NSURLResponse alloc]
                               initWithURL:url
                               MIMEType:@"text/html"
                               expectedContentLength:[dataString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]
                               textEncodingName:@"UTF8"];
    NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc]
                                           initWithResponse:response
                                           data:data
                                           userInfo:nil
                                           storagePolicy:NSURLCacheStorageAllowed];
    PHAsset *asset = [PHAsset assetFromNSCachedURLResponse:cachedResponse];
    STAssertEqualObjects(asset.data, data, @"NSCachedURLConversion");
    STAssertEqualObjects(asset.MIMEType, @"text/html", @"NSCachedURLConversion");
    STAssertEqualObjects(asset.textEncodingName, @"UTF8", @"NSCachedURLConversion");
    STAssertEqualObjects(asset.URL, url, @"NSCachedURLConversion");
    
    [response release];
    [cachedResponse release];
}


-(void)testAssetCache{
    PHAssetCache *cache = [PHAssetCache sharedAssetCache];
    STAssertNotNil(cache, @"Cache factory method creates an instance.");
    
    PHAssetCache *singletonTest = [PHAssetCache sharedAssetCache];
    STAssertEquals(cache, singletonTest, @"Cache factory method creates a singleton.");

    NSURL *url = [NSURL URLWithString:@"http://playhaven.com"];
    STAssertTrue([cache precacheAssetAtURL:url], @"Cache preloads a valid URL");
    STAssertFalse([cache precacheAssetAtURL:url], @"Cache prevents multiple preloads of the same URL");
    
    [cache stopPrecaching];
    STAssertTrue([cache precacheAssetAtURL:url], @"Cache preloads a valid URL after stopped");
}


@end
