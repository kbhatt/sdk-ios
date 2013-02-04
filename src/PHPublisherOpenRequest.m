//
//  PHPublisherOpenRequest.m
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 3/30/11.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import "PHPublisherOpenRequest.h"
#import "PHConstants.h"
#import "SDURLCache.h"
#import "PHTimeInGame.h"
#import "PHNetworkUtil.h"

#if PH_USE_OPENUDID == 1
#import "OpenUDID.h"
#import "PHConnectionManager.h"
#import "PHResourceCacher.h"
#endif

@interface PHAPIRequest (Private)
- (void)finish;
+ (void)setSession:(NSString *)session;
@end

@implementation PHPublisherOpenRequest
@synthesize customUDID = _customUDID;

+ (void)initialize
{
    if (self == [PHPublisherOpenRequest class]) {
        // Initializes pre-fetching and webview caching
        PH_SDURLCACHE_CLASS *urlCache = [[PH_SDURLCACHE_CLASS alloc] initWithMemoryCapacity:PH_MAX_SIZE_MEMORY_CACHE
                                                                               diskCapacity:PH_MAX_SIZE_FILESYSTEM_CACHE
                                                                                   diskPath:[PH_SDURLCACHE_CLASS defaultCachePath]];
        [NSURLCache setSharedURLCache:urlCache];
        [urlCache release];
    }
}

- (NSDictionary *)additionalParameters
{
    NSMutableDictionary *additionalParameters = [NSMutableDictionary dictionary];

    if (!!self.customUDID) {
        [additionalParameters setValue:self.customUDID forKey:@"d_custom"];
    }

#if PH_USE_OPENUDID == 1
        [additionalParameters setValue:[PH_OPENUDID_CLASS value] forKey:@"d_odid"];
#endif
#if PH_USE_MAC_ADDRESS == 1
    if (![PHAPIRequest optOutStatus]) {
        PHNetworkUtil *netUtil = [PHNetworkUtil sharedInstance];
        CFDataRef macBytes = [netUtil newMACBytes];
        if (macBytes) {
            [additionalParameters setValue:[netUtil stringForMACBytes:macBytes] forKey:@"d_mac"];
            [additionalParameters setValue:[netUtil ODIN1ForMACBytes:macBytes] forKey:@"d_odin1"];
            CFRelease(macBytes);
        }
    }
#endif

    [additionalParameters setValue:[NSNumber numberWithInt:[[PHTimeInGame getInstance] getCountSessions]]
                            forKey:@"scount"];
    [additionalParameters setValue:[NSNumber numberWithInt:(int)floor([[PHTimeInGame getInstance] getSumSessionDuration])]
                            forKey:@"ssum"];

    return  additionalParameters;
}

- (NSString *)urlPath
{
    return PH_URL(/v3/publisher/open/);
}

#pragma mark - PHAPIRequest response delegate
- (void)send
{
    [super send];
    [[PHTimeInGame getInstance] gameSessionStarted];
}

- (void)didSucceedWithResponse:(NSDictionary *)responseData
{
    NSArray *urlArray = (NSArray *)[responseData valueForKey:@"precache"];

    if ([urlArray count] == 0)
    {
        DLog(@"prefilling url array");

        urlArray = [NSArray arrayWithObjects://@"http://media.playhaven.com/content-templates/f0452b8fb73f0dd835130f062c84dca7bacb3acc/html/more-games.html.gz",
                                             //@"http://media.playhaven.com/content-templates/f0452b8fb73f0dd835130f062c84dca7bacb3acc/html/announcement.html.gz",
                                             //@"http://media.playhaven.com/content-templates/f0452b8fb73f0dd835130f062c84dca7bacb3acc/html/data-collection.html.gz",
                                             //@"http://media.playhaven.com/content-templates/f0452b8fb73f0dd835130f062c84dca7bacb3acc/html/image.html.gz",
                                             //@"http://media.playhaven.com/content-templates/f0452b8fb73f0dd835130f062c84dca7bacb3acc/html/promo.html.gz",
                                             @"http://media.playhaven.com/content-templates/f0452b8fb73f0dd835130f062c84dca7bacb3acc/html/gow.html.gz", nil];
    }

    if (!!urlArray) {

        DLog(@"starting to cache content");

        [PHResourceCacher cacherWithThingsToDownload:urlArray];

//        for (NSString *urlString in urlArray) {
//            NSURL *url = [NSURL URLWithString:urlString];
//            NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:PH_REQUEST_TIMEOUT];
//
//            if (![PHConnectionManager isRequestPending:request])
//                [PHConnectionManager createConnectionFromRequest:request forDelegate:self withContext:nil];

//            NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:nil];
//            [connection start];
//        }
    }

    NSString *session = (NSString *)[responseData valueForKey:@"session"];
    if (!!session) {
        [PHAPIRequest setSession:session];
    }

    if ([self.delegate respondsToSelector:@selector(request:didSucceedWithResponse:)]) {
        [self.delegate performSelector:@selector(request:didSucceedWithResponse:) withObject:self withObject:responseData];
    }

    // Reset time in game counters;
    [[PHTimeInGame getInstance] resetCounters];

    [self finish];
}

#pragma mark - NSObject

- (void)dealloc
{
    [_customUDID release], _customUDID = nil;
    [super dealloc];
}

#pragma mark - NSOperationQueue observer
@end
