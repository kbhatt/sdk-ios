//
//  PHAPIRequest.m
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 3/30/11.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import "PHConnectionManager.h"
#import "PHAPIRequest.h"

#import "NSObject+QueryComponents.h"
#import "PHStringUtil.h"
#import "JSON.h"
#import "UIDevice+HardwareString.h"
#import "PHNetworkUtil.h"

#ifdef PH_USE_NETWORK_FIXTURES
#import "WWURLConnection.h"
#endif

static NSString *sPlayHavenSession;
static NSString *const kSessionPasteboard = @"com.playhaven.session";
static NSString *sPlayHavenPluginIdentifier;

@interface PHAPIRequest (Private)
- (id)initWithApp:(NSString *)token secret:(NSString *)secret;
+ (NSMutableSet *)allRequests;
- (void)finish;
- (void)afterConnectionDidFinishLoading;
+ (void)setSession:(NSString *)session;
- (void)processRequestResponse:(NSDictionary *)responseData;

- (void)didSucceedWithResponse:(NSDictionary *)responseData;
- (void)didFailWithError:(NSError *)error;
@end

@implementation PHAPIRequest
@synthesize token    = _token;
@synthesize secret   = _secret;
@synthesize delegate = _delegate;
@synthesize urlPath  = _urlPath;
@synthesize hashCode = _hashCode;
@synthesize additionalParameters = _additionalParameters;

+ (void)initialize
{
    if  (self == [PHAPIRequest class]) {
        [[PHNetworkUtil sharedInstance] checkDNSResolutionForURLPath:PH_BASE_URL];
        [[PHNetworkUtil sharedInstance] checkDNSResolutionForURLPath:PH_CONTENT_ADDRESS];
#ifdef PH_USE_NETWORK_FIXTURES
        [WWURLConnection setResponsesFromFileNamed:@"dev.wwfixtures"];
#endif
    }
}

+ (NSMutableSet *)allRequests
{
    static NSMutableSet *allRequests = nil;

    if (allRequests == nil) {
        allRequests = [[NSMutableSet alloc] init];
    }

    return allRequests;
}

+ (void)cancelAllRequestsWithDelegate:(id<PHAPIRequestDelegate>)delegate
{
    NSEnumerator *allRequests = [[PHAPIRequest allRequests] objectEnumerator];
    PHAPIRequest *request = nil;

    NSMutableSet *canceledRequests = [NSMutableSet set];

    while ((request = [allRequests nextObject])) {
        if ([[request delegate] isEqual:delegate]) {
            [canceledRequests addObject:request];
        }
    }

    [canceledRequests makeObjectsPerformSelector:@selector(cancel)];
}

+ (int)cancelRequestWithHashCode:(int)hashCode
{
    PHAPIRequest *request = [self requestWithHashCode:hashCode];
    if (!!request) {
        [request cancel];

        return 1;
    }
    return 0;
}

+ (NSString *)base64SignatureWithString:(NSString *)string
{
    return [PHStringUtil b64DigestForString:string];
}

+ (NSString *)expectedSignatureValueForResponse:(NSString *)responseString nonce:(NSString *)nonce secret:(NSString *)secret
{
    const char   *cKey = [secret cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];

    CCHmacContext context;
    CCHmacInit(&context, kCCHmacAlgSHA1, cKey, strlen(cKey));

    if (nonce) {
        const char *cNonce = [nonce cStringUsingEncoding:NSUTF8StringEncoding];
        CCHmacUpdate(&context, cNonce, strlen(cNonce));
    }

    const char *cResponse = [responseString cStringUsingEncoding:NSUTF8StringEncoding];
    CCHmacUpdate(&context, cResponse, strlen(cResponse));

    CCHmacFinal(&context, &cHMAC);

    NSData *HMAC = [[[NSData alloc] initWithBytes:cHMAC
                                           length:sizeof(cHMAC)] autorelease];

    NSString *localSignature = [PHStringUtil base64EncodedStringForData:HMAC];

    // Figure out if we need to pad to multiple of 4 length
    NSUInteger length = [localSignature length];
    NSUInteger modulo = [localSignature length] % 4;
    if (modulo != 0) {
        length = length + (4 - modulo);
    }

    return [localSignature stringByPaddingToLength:length withString:@"=" startingAtIndex:0];
}

+ (NSString *)session
{
    @synchronized (self) {
        if (sPlayHavenSession == nil) {
            UIPasteboard *pasteboard = [UIPasteboard pasteboardWithName:kSessionPasteboard create:NO];
            sPlayHavenSession = [[NSString alloc] initWithString:([pasteboard string] == nil ? @"" : [pasteboard string])];
        }
    }

    return (!!sPlayHavenSession) ? sPlayHavenSession : @"";
}

+ (void)setSession:(NSString *)session
{
    @synchronized (self) {
        if (![session isEqualToString:sPlayHavenSession]) {
            UIPasteboard *pasteboard = [UIPasteboard pasteboardWithName:kSessionPasteboard create:YES];
            [pasteboard setString:((session!= nil) ? session : @"")];
            [sPlayHavenSession release];
            sPlayHavenSession = (!!session) ? [[NSString alloc] initWithString:session] : nil;
        }
    }
}

+ (BOOL)optOutStatus
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"PlayHavenOptOutStatus"];
}

+ (NSString *)pluginIdentifier
{
    @synchronized (self) {
        if (sPlayHavenPluginIdentifier == nil) {
            sPlayHavenPluginIdentifier = [[NSString alloc] initWithFormat:@"ios-%@", PH_SDK_VERSION];
        }
    }

    return sPlayHavenPluginIdentifier;
}

+ (void)setPluginIdentifier:(NSString *)identifier
{
    @synchronized (self) {
        [sPlayHavenPluginIdentifier release], sPlayHavenPluginIdentifier = [identifier copy];
    }
}

+ (void)setOptOutStatus:(BOOL)yesOrNo
{
    [[NSUserDefaults standardUserDefaults] setBool:yesOrNo forKey:@"PlayHavenOptOutStatus"];
}

+ (id)requestForApp:(NSString *)token secret:(NSString *)secret
{
    return [[[[self class] alloc] initWithApp:token secret:secret] autorelease];
}

+ (id)requestWithHashCode:(int)hashCode
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hashCode == %d", hashCode];
    NSSet       *resultSet = [[self allRequests] filteredSetUsingPredicate:predicate];

    return [resultSet anyObject];
}

- (id)initWithApp:(NSString *)token secret:(NSString *)secret
{
    self = [self init];
    if (self) {
        _token  = [token copy];
        _secret = [secret copy];
    }

    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [[PHAPIRequest allRequests] addObject:self];
    }

    return  self;
}

- (NSURL *)URL
{
    if (_URL == nil) {
        NSString *urlString = [NSString stringWithFormat:@"%@?%@",
                               [self urlPath],
                               [self signedParameterString]];
        _URL = [[NSURL alloc] initWithString:urlString];
    }

    return _URL;
}

- (NSDictionary *)signedParameters
{
    if (_signedParameters == nil) {
        CGRect  screenBounds = [[UIScreen mainScreen] applicationFrame];
        BOOL    isLandscape  = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
        CGFloat screenWidth  = (isLandscape) ? CGRectGetHeight(screenBounds) : CGRectGetWidth(screenBounds);
        CGFloat screenHeight = (!isLandscape) ? CGRectGetHeight(screenBounds) : CGRectGetWidth(screenBounds);
        CGFloat screenScale  = [[UIScreen mainScreen] scale];

        NSString *preferredLanguage = ([[NSLocale preferredLanguages] count] > 0) ?
                                            [[NSLocale preferredLanguages] objectAtIndex:0] : nil;

        NSMutableDictionary *combinedParams = [[NSMutableDictionary alloc] init];

#if PH_USE_UNIQUE_IDENTIFIER == 1
        if (![PHAPIRequest optOutStatus]) {
            NSString *device = [[UIDevice currentDevice] uniqueIdentifier];
            [combinedParams setValue:device forKey:@"device"];
        }
#endif

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        if ([ASIdentifierManager class]) {
            NSUUID   *uuid            = [[ASIdentifierManager sharedManager] advertisingIdentifier];
            NSString *uuidString      = [uuid UUIDString];
            NSNumber *trackingEnabled = [NSNumber numberWithBool:[[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]];
            [combinedParams setValue:uuidString forKey:@"d_ifa"];
            [combinedParams setValue:trackingEnabled forKey:@"tracking"];
        }
#endif
#endif

        // Adds plugin identifier
        [combinedParams setValue:[PHAPIRequest pluginIdentifier] forKey:@"plugin"];

        // This allows for unit testing of request values!
        NSBundle *mainBundle = [NSBundle bundleForClass:[self class]];

        NSString
            *nonce         = [PHStringUtil uuid],
            *session       = [PHAPIRequest session],
            *gid           = PHGID(),
            *signatureHash = [NSString stringWithFormat:@"%@:%@:%@:%@:%@",
                                    self.token, [PHAPIRequest session],
                                    PHGID(), nonce, self.secret],
            *signature     = [PHAPIRequest base64SignatureWithString:signatureHash],
            *appId         = [[mainBundle infoDictionary] objectForKey:@"CFBundleIdentifier"],
            *appVersion    = [[mainBundle infoDictionary] objectForKey:@"CFBundleVersion"],
            *hardware      = [[UIDevice currentDevice] hardware],
            *os            = [NSString stringWithFormat:@"%@ %@",
                                    [[UIDevice currentDevice] systemName],
                                    [[UIDevice currentDevice] systemVersion]],
            *languages     = preferredLanguage;

        if (!appVersion) appVersion = @"NA";

        NSNumber
            *idiom      = [NSNumber numberWithInt:(int)UI_USER_INTERFACE_IDIOM()],
            *connection = [NSNumber numberWithInt:PHNetworkStatus()],
            *width      = [NSNumber numberWithFloat:screenWidth],
            *height     = [NSNumber numberWithFloat:screenHeight],
            *scale      = [NSNumber numberWithFloat:screenScale];

        [combinedParams addEntriesFromDictionary:self.additionalParameters];

        NSDictionary *signatureParams =
             [NSDictionary dictionaryWithObjectsAndKeys:
                                 self.token,     @"token",
                                 signature,      @"signature",
                                 nonce,          @"nonce",
                                 appId,          @"app",
                                 hardware,       @"hardware",
                                 os,             @"os",
                                 idiom,          @"idiom",
                                 appVersion,     @"app_version",
                                 connection,     @"connection",
                                 PH_SDK_VERSION, @"sdk-ios",
                                 languages,      @"languages",
                                 session,        @"session",
                                 gid,            @"gid",
                                 width,          @"width",
                                 height,         @"height",
                                 scale,          @"scale", nil];

        [combinedParams addEntriesFromDictionary:signatureParams];
        _signedParameters = combinedParams;
    }

    return _signedParameters;
}

- (NSString *)signedParameterString
{
    return [[self signedParameters] stringFromQueryComponents];
}

- (void)dealloc
{
    DLog(@"");

    [_token release], _token = nil;
    [_secret release], _secret = nil;
    [_URL release], _URL = nil;
    [_signedParameters release], _signedParameters = nil;
    [_urlPath release], _urlPath = nil;
    [_additionalParameters release], _additionalParameters = nil;

    //[_connection release], _connection = nil;
    //[_connectionData release], _connectionData = nil;
    //[_response release], _response = nil; // TODO: Lilli, make sure by adding this, nothing breaks

    [super dealloc];
}

#pragma mark -
#pragma mark PHPublisherOpenRequest

- (void)send
{
    DLog(@"");

    //if (_connection == nil) { // TODO: This seems like a very bad way to stop requests from being sent twice (as _connection would
                                // really only be nil when the apirequest was first created), though that's what it's actually doing
                                // as it is never set to nil when the connection finishes. Was this prevention here intentionally?

    static BOOL theRightWayToStopTheRequestFromBeingSentTwiceIfItsActuallyNeeded = YES;
    if (theRightWayToStopTheRequestFromBeingSentTwiceIfItsActuallyNeeded)
    {
        PH_LOG(@"Sending request: %@", [self.URL absoluteString]);
        NSURLRequest *request = [NSURLRequest requestWithURL:self.URL
                                                 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                             timeoutInterval:PH_REQUEST_TIMEOUT];

        [PHConnectionManager createConnectionFromRequest:request forDelegate:self withContext:nil];

//#ifdef PH_USE_NETWORK_FIXTURES
//        _connection = [[WWURLConnection connectionWithRequest:request delegate:self] retain];
//#else
//        _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
//#endif
//        [_connection start];

    }

    theRightWayToStopTheRequestFromBeingSentTwiceIfItsActuallyNeeded = NO;

    //}
}

- (void)cancel
{
    PH_LOG(@"%@ canceled!", NSStringFromClass([self class]));
    [self finish];
}

/*
 * Internal cleanup method
 */
- (void)finish
{
    DLog(@"");

//    [_connection cancel];

    [PHConnectionManager stopConnectionsForDelegate:self];

    // REQUEST_RELEASE see REQUEST_RETAIN
    [[PHAPIRequest allRequests] removeObject:self];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate PHConnectionManagerDelegate

//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
//{
//    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
//        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
//        PH_LOG(@"Request recieved HTTP response: %d", [httpResponse statusCode]);
//    }
//
//    /* We want to get response objects for everything */
//    [_connectionData release], _connectionData = [[NSMutableData alloc] init];
//    [_response release], _response = [response retain];
//}

//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//{
//    [_connectionData appendData:data];
//}

//- (void)connectionDidFinishLoading:(NSURLConnection *)connection
- (void)connectionDidFinishLoadingWithRequest:(NSURLRequest *)request response:(NSURLResponse *)response data:(NSData *)data andContext:(id)context
{
    //PH_NOTE(@"Request finished!");

    DLog(@"");

    if ([self.delegate respondsToSelector:@selector(requestDidFinishLoading:)]) {
        [self.delegate performSelector:@selector(requestDidFinishLoading:) withObject:self withObject:nil];
    }

    NSString *responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSString *requestSignature  = [[httpResponse allHeaderFields] valueForKey:@"X-PH-DIGEST"];
        NSString *nonce             = [self.signedParameters valueForKey:@"nonce"];
        NSString *expectedSignature = [PHAPIRequest expectedSignatureValueForResponse:responseString
                                                                                nonce:nonce
                                                                               secret:self.secret];

        if (![expectedSignature isEqualToString:requestSignature]) {
            [self didFailWithError:PHCreateError(PHRequestDigestErrorType)];

            return;
        }
    }

    PH_SBJSONPARSER_CLASS *parser           = [[[PH_SBJSONPARSER_CLASS alloc] init] autorelease];
    NSDictionary          *resultDictionary = [parser objectWithString:responseString];

    [self processRequestResponse:resultDictionary];
}

- (void)afterConnectionDidFinishLoading
{

}

//- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
- (void)connectionDidFailWithError:(NSError *)error request:(NSURLRequest *)request andContext:(id)context
{
    DLog(@"");

    //PH_LOG(@"Request failed with error: %@", [error localizedDescription]);
    [self didFailWithError:error];

    // REQUEST_RELEASE see REQUEST_RETAIN
    [self finish];
}

#pragma mark -
- (void)processRequestResponse:(NSDictionary *)responseData
{
    DLog(@"");
    id errorValue = [responseData valueForKey:@"error"];
    if (!!errorValue && ![errorValue isEqual:[NSNull null]]) {
        PH_LOG(@"Error response: %@", errorValue);
        [self didFailWithError:PHCreateError(PHAPIResponseErrorType)];
    } else {
        id responseValue = [responseData valueForKey:@"response"];
        if ([responseValue isEqual:[NSNull null]]) {
            responseValue = nil;
        }

        [self didSucceedWithResponse:responseValue];
    }
}

- (void)didSucceedWithResponse:(NSDictionary *)responseData
{
    if ([self.delegate respondsToSelector:@selector(request:didSucceedWithResponse:)]) {
        [self.delegate performSelector:@selector(request:didSucceedWithResponse:) withObject:self withObject:responseData];
    }

    [self finish];
}

- (void)didFailWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(request:didFailWithError:)]) {
        [self.delegate performSelector:@selector(request:didFailWithError:) withObject:self withObject:error];
    }

    [self finish];
}
@end
