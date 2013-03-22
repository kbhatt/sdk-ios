//
//  PHResourceCacher.h
//  playhaven-sdk-ios
//
//  Created by Lilli Szafranski on 1/31/13.
//  Copyright 2013 Playhaven. All rights reserved.
//

#import "PHConnectionManager.h"
#import "PHResourceCacher.h"
#import "PHConstants.h"
#import "PlayHavenSDK.h"
#import "PHContent.h"

@interface NSMutableArray (PushPopObject)
- (id)popObjectAtIndex:(NSUInteger)index;
- (void)pushObjectToFront:(id)object;
- (void)pushObjectToBack:(id)object;
@end

@implementation NSMutableArray (PopObject)
- (id)popObjectAtIndex:(NSUInteger)index
{
    id object = [[[self objectAtIndex:index] retain] autorelease];

    [self removeObjectAtIndex:index];

    return object;
}

- (void)pushObjectToFront:(id)object
{
    [self insertObject:object atIndex:0];
}

- (void)pushObjectToBack:(id)object
{
    [self insertObject:object atIndex:[self count]];
}
@end

@interface PHResourceCacher ()
@property (retain) NSMutableArray *cacherQueue;
@property (retain) NSDictionary   *pendingObject;
@property (retain) NSString       *pendingObjectUrl;
@property (retain) PHPublisherContentRequest *pendingPlacement;
@property (retain) NSMutableSet   *precachedPlacements;
@property (retain) NSString *token;
@property (retain) NSString *secret;
@end

@implementation PHResourceCacher
@synthesize webView = _webView;
@synthesize cacherQueue         = _cacherQueue;
@synthesize pendingObject       = _pendingObject;
@synthesize pendingObjectUrl    = _pendingObjectUrl;
@synthesize pendingPlacement    = _pendingPlacement;
@synthesize precachedPlacements = _precachedPlacements;
@synthesize token  = _token;
@synthesize secret = _secret;


static PHResourceCacher *singleton = nil;

- (id)init
{
    if ((self = [super init]))
    {
        _precachedPlacements = [[NSMutableSet alloc] initWithCapacity:6];

        _cacherQueue = [[NSMutableArray alloc] initWithCapacity:6];
    }

    return self;
}

+ (id)sharedInstance
{
    if (singleton == nil) {
        singleton = [((PHResourceCacher *)[super allocWithZone:NULL]) init];
    }

    return singleton;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedInstance] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;
}

- (oneway void)release { }

- (id)autorelease
{
    return self;
}

//- (id)initWithThingsToDownload:(id)things
//{
//    DLog(@"things: %@", [things description]);
//
//    self = [super init];
//    if (self)
//    {
//        for (NSString *urlString in things)
//        {
//            DLog(@"");
//
//            NSURL *url = [NSURL URLWithString:urlString];
//
//            // TODO: Perhaps these need to match?
////            NSURLRequest *request = [NSURLRequest requestWithURL:url
////                                                     cachePolicy:NSURLRequestReturnCacheDataElseLoad
////                                                 timeoutInterval:PH_REQUEST_TIMEOUT + 10];
//
//            NSURLRequest *request = [NSURLRequest requestWithURL:url
//                                                     cachePolicy:NSURLRequestReturnCacheDataElseLoad
//                                                 timeoutInterval:PH_REQUEST_TIMEOUT + 10];
//
//            DLog(@"caching content for url: %@", [[request URL] absoluteString]);
//
//
////            if (!self.webView) {
////                self.webView = [[[UIWebView alloc] initWithFrame:CGRectMake(300, 300, 100, 100)] autorelease];
////                self.webView.delegate = [self retain];
////
////                UIWindow *window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
////                [window addSubview:self.webView];
////            }
////
////            if ([urlString hasSuffix:@"jpg"])
////                [self.webView loadRequest:request];
////            else
//            if (![PHConnectionManager isRequestPending:request])
//                [PHConnectionManager createConnectionFromRequest:request forDelegate:self withContext:nil];
//        }
//    }
//
//    return self;
//}
//
//+ (id)cacherWithThingsToDownload:(id)things
//{
//    return [[[PHResourceCacher alloc] initWithThingsToDownload:things] autorelease];
//}

+ (void)setToken:(NSString *)token andSecret:(NSString *)secret
{
    [[PHResourceCacher sharedInstance] setToken:token];
    [[PHResourceCacher sharedInstance] setSecret:secret];
}

+ (BOOL)isRequestPending:(NSURLRequest *)request
{   // TODO: Make sure this is returning truthfully
    // TODO: Figure out the 'most correct' way to test for request equality
    //return [[[PHResourceCacher sharedInstance] pendingRequests] containsObject:[[request URL] absoluteString]];

    return ([[[request URL] absoluteString] isEqualToString:[[PHResourceCacher sharedInstance] pendingObjectUrl]]);
}

//+ (BOOL)isRequestComplete:(NSURLRequest *)request
//{   // TODO: Make sure this is returning truthfully
//    return [[[PHResourceCacher  sharedInstance] pendingRequests] containsObject:[[request URL] absoluteString]];
//}

- (NSURLRequest *)requestForObject:(NSDictionary *)object
{
    NSURL *url = [NSURL URLWithString:[object objectForKey:@"url"]];

    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                         timeoutInterval:PH_REQUEST_TIMEOUT + 10];

    return request;
}

- (void)startDownloadingObject:(NSDictionary *)object
{
    NSString *type = [object objectForKey:@"type"];

    self.pendingObject = object;

    if ([type isEqualToString:@"template"] || [type isEqualToString:@"url"])
    {
        [PHConnectionManager createConnectionFromRequest:[self requestForObject:object]
                                             forDelegate:self
                                             withContext:nil];

    } else if ([type isEqualToString:@"placement"]) {
        PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:self.token
                                                                               secret:self.secret
                                                                            placement:[object objectForKey:@"placement_id"]
                                                                             delegate:self];

        self.pendingPlacement = request;
//        [self.precachedPlacements addObject:request];

        [request preload];
    }
}

- (void)pause
{
    if ([[self.pendingObject objectForKey:@"type"] isEqualToString:@"url"] ||
        [[self.pendingObject objectForKey:@"type"] isEqualToString:@"template"])
            [PHConnectionManager stopConnectionsForDelegate:self];
    else if ([[self.pendingObject objectForKey:@"type"] isEqualToString:@"placement_id"])
            [self.pendingPlacement cancel];

    [self.cacherQueue pushObjectToFront:self.pendingObject];

    self.pendingObject    = nil;
    self.pendingObjectUrl = nil;
    self.pendingPlacement = nil;}

+ (void)pause
{
    [[PHResourceCacher sharedInstance] pause];
}

- (void)resume
{
    if ([self.cacherQueue count] && !self.pendingObject)
        [self startDownloadingObject:[self.cacherQueue popObjectAtIndex:0]];
}

+ (void)resume
{
    [[PHResourceCacher sharedInstance] resume];
}

+ (void)cacheObject:(NSDictionary *)object withPriority:(PHCacherPriority)priority
{
    PHResourceCacher *cacher = [PHResourceCacher sharedInstance];

    if (priority == PHPriorityStartImmediately) {
        [cacher pause];

        [cacher.cacherQueue pushObjectToFront:object];

    } else if (priority == PHPriorityStartNext) {
        [cacher.cacherQueue pushObjectToFront:object];

    } else if (priority == PHPriorityStartLater) {
        [cacher.cacherQueue pushObjectToBack:object];
    }

    [cacher resume];
}

- (void)connectionDidFailWithError:(NSError *)error request:(NSURLRequest *)request andContext:(id)context
{
    DLog(@"");

    [[NSNotificationCenter defaultCenter] postNotificationName:[[request URL] absoluteString]
                                                        object:nil
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                     request, @"request",
                                                                                     error,   @"error", nil]];

    self.pendingObject = nil;
    self.pendingObjectUrl = nil;

    if ([self.cacherQueue count])
        [self startDownloadingObject:[self.cacherQueue popObjectAtIndex:0]];
}

- (void)connectionDidFinishLoadingWithRequest:(NSURLRequest *)request response:(NSURLResponse *)response data:(NSData *)data andContext:(id)context
{
    DLog(@"");

    [[NSNotificationCenter defaultCenter] postNotificationName:[[request URL] absoluteString]
                                                        object:nil
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                     request,  @"request",
                                                                                     response, @"response",
                                                                                     data,     @"data", nil]];

    self.pendingObject = nil;
    self.pendingObjectUrl = nil;

    if ([self.cacherQueue count])
        [self startDownloadingObject:[self.cacherQueue popObjectAtIndex:0]];
}

- (void)connectionWasStoppedWithContext:(id)context
{
    self.pendingObject = nil;
    self.pendingObjectUrl = nil;
}

- (void)requestWillGetContent:(PHPublisherContentRequest *)request
{
    DLog(@"");
}

- (void)requestDidGetContent:(PHPublisherContentRequest *)request
{
    DLog(@"");

    [self.precachedPlacements addObject:self.pendingPlacement];

    self.pendingObject = nil;
    self.pendingPlacement = nil;

    if ([self.cacherQueue count])
        [self startDownloadingObject:[self.cacherQueue popObjectAtIndex:0]];
}

- (void)request:(PHPublisherContentRequest *)request didFailWithError:(NSError *)error
{
    DLog(@"");

    self.pendingObject = nil;
    self.pendingPlacement = nil;

    if ([self.cacherQueue count])
        [self startDownloadingObject:[self.cacherQueue popObjectAtIndex:0]];
}

- (void)request:(PHPublisherContentRequest *)request contentDidFailWithError:(NSError *)error
{
    DLog(@"");

    self.pendingObject = nil;
    self.pendingPlacement = nil;
}

- (void)request:(PHPublisherContentRequest *)request contentDidDismissWithType:(PHPublisherContentDismissType *)type
{
    DLog(@"");

    self.pendingObject = nil;
    self.pendingPlacement = nil;
}

- (void)requestContentDidDismiss:(PHPublisherContentRequest *)request
{
    DLog(@"");

    self.pendingObject = nil;
    self.pendingPlacement = nil;
}


//- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
//{
//    DLog(@"");
//}
//
//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
//{
//    DLog(@"");
//
//
//    NSMutableDictionary *newHeaders = [NSMutableDictionary dictionaryWithDictionary:[request allHTTPHeaderFields]];
//
//    DLog(@"headers: %@", [newHeaders description]);
//
//    return YES;
//}
//
//- (void)webViewDidFinishLoad:(UIWebView *)webView
//{
//    DLog(@"");
//    //self.webView = nil;
//    //[self release];
//}
//
//- (void)webViewDidStartLoad:(UIWebView *)webView
//{
//    DLog(@"");
//}

- (void)dealloc
{
    [_webView release];
    [_cacherQueue release];
    [_token release];
    [_secret release];
    [_pendingObject release];
    [_precachedPlacements release];
    [_pendingObjectUrl release];
    [_pendingPlacement release];
    [super dealloc];
}
@end
