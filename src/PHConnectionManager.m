//
//  PHConnectionManager.m
//  playhaven-sdk-ios
//
//  Created by Lilli Szafranski on 1/31/13.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import "PHConnectionManager.h"
#import "PHConstants.h"

#ifdef PH_USE_NETWORK_FIXTURES
#import "WWURLConnection.h"
#endif



@interface PHConnectionBundle : NSObject
{
//    NSURLRequest  *_request;
//    NSMutableData *_response;
//    NSURLResponse *_fullResponse;
//    id             _context;
//
//    id<PHConnectionManagerDelegate> _delegate;
}

@property (retain)   NSURLRequest  *request;
@property (retain)   NSURLResponse *response;
@property (retain)   NSMutableData *data;
@property (readonly) id             context;
@property (readonly) id<PHConnectionManagerDelegate> delegate;
@end

@implementation PHConnectionBundle
@synthesize request  = _request;
@synthesize response = _response;
@synthesize data     = _data;
@synthesize context  = _context;
@synthesize delegate = _delegate;

- (id)initWithRequest:(NSURLRequest *)request forDelegate:(id <PHConnectionManagerDelegate>)delegate withContext:(id)context
{
    if ((self = [super init]))
    {
        _request  = [request retain];
        _context  = [context retain];

        _response = nil;
        _data     = nil;

        _delegate = [delegate retain];
    }

    return self;
}

+ (id)connectionBundleWithRequest:(NSURLRequest *)request forDelegate:(id <PHConnectionManagerDelegate>)delegate withContext:(id)context
{
    return [[[PHConnectionBundle alloc] initWithRequest:request forDelegate:delegate withContext:context] autorelease];
}

- (void)dealloc
{
//  DLog(@"");

    [_request release];
    [_response release];
    [_data release];
    [_delegate release];
    [_context release];

    [super dealloc];
}
@end

@interface PHConnectionManager ()
@property CFMutableDictionaryRef connections;
@property (retain) NSMutableSet *pendingRequests;
@property (retain) NSMutableSet *completeRequests;
@end

@implementation PHConnectionManager
@synthesize connections      = _connections;
@synthesize pendingRequests  = _pendingRequests;
@synthesize completeRequests = _completeRequests;

static PHConnectionManager *singleton = nil;

- (id)init
{
    if ((self = [super init]))
    {
        _connections = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                 &kCFTypeDictionaryKeyCallBacks,
                                                 &kCFTypeDictionaryValueCallBacks);

        _pendingRequests  = [[NSMutableSet alloc] initWithCapacity:6];
        _completeRequests = [[NSMutableSet alloc] initWithCapacity:6];
    }

    return self;
}

+ (id)sharedInstance
{
    if (singleton == nil) {
        singleton = [((PHConnectionManager *)[super allocWithZone:NULL]) init];
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

//+ (NSUInteger)openConnectionCount
//{
//    return [(NSDictionary *)[[PHConnectionManager sharedInstance] connections] count];
//}

// Here just cuz...
- (void)dealloc
{
    CFRelease(_connections);

    [_completeRequests release];
    [_pendingRequests release];

    [super dealloc];
}

+ (BOOL)createConnectionFromRequest:(NSURLRequest *)request forDelegate:(id <PHConnectionManagerDelegate>)delegate withContext:(id)context
{
    DLog(@"creating connection for url: %@", [[request URL] absoluteString]);

    PHConnectionManager *connectionManager = [PHConnectionManager sharedInstance];

    if (![NSURLConnection canHandleRequest:request])
        return NO;

    NSURLConnection *connection;

#ifdef PH_USE_NETWORK_FIXTURES // TODO: Will there be an issue with this starting before the connection bundle is created and saved? Nvm, this doesn't start it immediately... for shame...
    connection = [WWURLConnection connectionWithRequest:request delegate:self];
#else
    connection = [[[NSURLConnection alloc] initWithRequest:request
                                                  delegate:connectionManager
                                          startImmediately:NO] autorelease];
#endif

    if (!connection)
        return NO;

    PHConnectionBundle *connectionBundle = [PHConnectionBundle connectionBundleWithRequest:request
                                                                               forDelegate:delegate
                                                                               withContext:context];

    CFDictionaryAddValue(connectionManager.connections,
                         connection,
                         connectionBundle);

    [[connectionManager pendingRequests] addObject:[[request URL] absoluteString]];

//    NSRange range = [[[request URL] absoluteString] rangeOfString:@"http://media.playhaven.com/content-templates/f0452b8fb73f0dd835130f062c84dca7bacb3acc/"];
//    if (!(range.location == NSNotFound))
//        sleep(5);

    // TODO: Do we need this?
    //[connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [connection start];

    return YES;
}

+ (void)stopConnectionsForDelegate:(id<PHConnectionManagerDelegate>)delegate
{
    DLog(@"");

    PHConnectionManager *connectionManager = [PHConnectionManager sharedInstance];
    PHConnectionBundle  *connectionBundle  = nil;

    for (NSURLConnection *connection in [(NSMutableDictionary *)connectionManager.connections allKeys])
    {
        connectionBundle = [(PHConnectionBundle *) CFDictionaryGetValue(connectionManager.connections, connection) retain];

        // TODO: This code should only be called if the connection is still live, to avoid releasing the connection bundle too soon; Then remove the retain/release stuff
        if ([connectionBundle delegate] == delegate)
        {
            [connection cancel];

            [[connectionManager pendingRequests] removeObject:[[connectionBundle.request URL] absoluteString]];

            if ([delegate respondsToSelector:@selector(connectionWasStoppedWithContext:)])
                [delegate connectionWasStoppedWithContext:[connectionBundle context]];

            CFDictionaryRemoveValue(connectionManager.connections, connection);
            [connectionBundle release];
        }
    }
}

+ (BOOL)isRequestPending:(NSURLRequest *)request
{   // TODO: Make sure this is returning truthfully
    // TODO: Figure out the 'most correct' way to test for request equality
    return [[[PHConnectionManager sharedInstance] pendingRequests] containsObject:[[request URL] absoluteString]];
}

+ (BOOL)isRequestComplete:(NSURLRequest *)request
{   // TODO: Make sure this is returning truthfully
    return [[[PHConnectionManager sharedInstance] pendingRequests] containsObject:[[request URL] absoluteString]];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    DLog(@"");

    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        PH_LOG(@"Request recieved HTTP response: %d", [httpResponse statusCode]);
    }

    PHConnectionBundle *connectionBundle = (PHConnectionBundle *)CFDictionaryGetValue(self.connections, connection);

    [connectionBundle setData:[[[NSMutableData alloc] init] autorelease]];

    connectionBundle.response = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //DLog(@"");
    [[(PHConnectionBundle *)CFDictionaryGetValue(self.connections, connection) data] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    PH_NOTE(@"Request finished!");
    PHConnectionBundle *connectionBundle = [(PHConnectionBundle *) CFDictionaryGetValue(self.connections, connection) retain];

    NSURLRequest  *request  = [connectionBundle request];
    NSURLResponse *response = [connectionBundle response];
    NSData        *data     = [connectionBundle data];
    id             context  = [connectionBundle context];
    id<PHConnectionManagerDelegate> delegate = [connectionBundle delegate];

    [[self pendingRequests] removeObject:[[request URL] absoluteString]];
    [[self completeRequests] addObject:[[request URL] absoluteString]];

    DLog(@"completing connection for url: %@", [[request URL] absoluteString]);

    if ([delegate respondsToSelector:@selector(connectionDidFinishLoadingWithRequest:response:data:andContext:)])
        [delegate connectionDidFinishLoadingWithRequest:request response:response data:data andContext:context];

    DLog(@"request: %@, response: %@, data: %@", [request description], [response description], data ? @"data" : @"no data");

    [[NSNotificationCenter defaultCenter] postNotificationName:[[request URL] absoluteString]
                                                        object:nil
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                     request,  @"request",
                                                                                     response, @"response",
                                                                                     data,     @"data", nil]];

    CFDictionaryRemoveValue(self.connections, connection);
    [connectionBundle release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    DLog(@"");
    PH_LOG(@"Request failed with error: %@", [error localizedDescription]);

    PHConnectionBundle *connectionBundle = [(PHConnectionBundle *) CFDictionaryGetValue(self.connections, connection) retain];

    NSURLRequest *request  = [connectionBundle request];
    id            context  = [connectionBundle context];
    id<PHConnectionManagerDelegate> delegate = [connectionBundle delegate];

    [[self pendingRequests] removeObject:[[request URL] absoluteString]];

    if ([delegate respondsToSelector:@selector(connectionDidFailWithError:request:andContext:)])
        [delegate connectionDidFailWithError:error request:request andContext:context];

    [[NSNotificationCenter defaultCenter] postNotificationName:[[request URL] absoluteString]
                                                        object:nil
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                     request, @"request",
                                                                                     error,   @"error", nil]];

    CFDictionaryRemoveValue(self.connections, connection);
    [connectionBundle release];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request
                                                          redirectResponse:(NSURLResponse *)redirectResponse
{
    // TODO: Figure out if we should save this response or not...
    PHConnectionBundle *connectionBundle = (PHConnectionBundle *)CFDictionaryGetValue(self.connections, connection);
    connectionBundle.response = redirectResponse;

    return request;
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge  { DLog(@""); }
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge { DLog(@""); }
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse    { DLog(@""); return cachedResponse; }
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten
                                               totalBytesWritten:(NSInteger)totalBytesWritten
                                       totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{ /*DLog(@"bytesWritten: %d, totalBytesWritten: %d, totalBytesExpected: %d", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);*/ }
@end
