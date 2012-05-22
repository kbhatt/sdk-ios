//
//  PHAPIRequest.m
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 3/30/11.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import "PHAPIRequest.h"

#import "NSObject+QueryComponents.h"
#import "PHStringUtil.h"
#import "SBJson.h"
#import "UIDevice+HardwareString.h"
#import "PHConstants.h"
#import "OpenUDID.h"
#import "PHNetworkUtil.h"

#ifdef PH_USE_NETWORK_FIXTURES
#import "WWURLConnection.h"
#endif

static NSString *sPlayHavenSession;
static NSString *const kSessionPasteboard = @"com.playhaven.session"; 

@interface PHAPIRequest(Private)
-(id)initWithApp:(NSString *)token secret:(NSString *)secret;
+(NSMutableSet *)allRequests;
-(void)finish;
-(void)afterConnectionDidFinishLoading;
+(void)setSession:(NSString *)session;
@end

@implementation PHAPIRequest

+(void)initialize{
    if  (self == [PHAPIRequest class]){        
        [[PHNetworkUtil sharedInstance] checkDNSResolutionForURLPath:PH_BASE_URL];
        [[PHNetworkUtil sharedInstance] checkDNSResolutionForURLPath:PH_CONTENT_ADDRESS];
#ifdef PH_USE_NETWORK_FIXTURES
        [WWURLConnection setResponsesFromFileNamed:@"dev.wwfixtures"];
#endif
    }
}

+(NSMutableSet *)allRequests{
    static NSMutableSet *allRequests = nil;
    
    if (allRequests == nil) {
        allRequests = [[NSMutableSet alloc] init];
    }
    
    return allRequests;
}

+(void)cancelAllRequestsWithDelegate:(id)delegate{
    NSEnumerator *allRequests = [[PHAPIRequest allRequests] objectEnumerator];
    PHAPIRequest *request = nil;
    
    NSMutableSet *canceledRequests = [NSMutableSet set];
    
    while (request = [allRequests nextObject]){
        if ([[request delegate] isEqual:delegate]) {
            [canceledRequests addObject:request];
        }
    }
    
    [canceledRequests makeObjectsPerformSelector:@selector(cancel)];
}

+(int)cancelRequestWithHashCode:(int)hashCode{
    PHAPIRequest *request = [self requestWithHashCode:hashCode];
    if (!!request) {
        [request cancel];
        return 1;
    } 
    return 0;
}

+(NSString *) base64SignatureWithString:(NSString *)string{
    return [PHStringUtil b64DigestForString:string];
}

+(NSString *)session{
    @synchronized(self){
        if (sPlayHavenSession == nil) {
            UIPasteboard *pasteboard = [UIPasteboard pasteboardWithName:kSessionPasteboard create:NO];
            sPlayHavenSession = [[NSString alloc] initWithString:[pasteboard string] == nil?@"":[pasteboard string]];
        }
    }
    
    return (!!sPlayHavenSession)? sPlayHavenSession : @"";
}

+(void)setSession:(NSString *)session{
    @synchronized(self){
        if (![session isEqualToString:sPlayHavenSession]) {
            UIPasteboard *pasteboard = [UIPasteboard pasteboardWithName:kSessionPasteboard create:YES];
            [pasteboard setString:session];
            [sPlayHavenSession release];
            sPlayHavenSession = (!!session)?[[NSString alloc] initWithString:session]: nil;
        }
    }
}

+(BOOL)optOutStatus{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"PlayHavenOptOutStatus"];
}

+(void)setOptOutStatus:(BOOL)yesOrNo{
    [[NSUserDefaults standardUserDefaults] setBool:yesOrNo forKey:@"PlayHavenOptOutStatus"];
}

+(id) requestForApp:(NSString *)token secret:(NSString *)secret{
    return [[[[self class] alloc] initWithApp:token secret:secret] autorelease];
}

+(id)requestWithHashCode:(int)hashCode{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hashCode == %d",hashCode];
    NSSet *resultSet = [[self allRequests] filteredSetUsingPredicate:predicate];
    return [resultSet anyObject];
}

-(id) initWithApp:(NSString *)token secret:(NSString *)secret{
    self = [self init];
    if (self) {
        _token = [token copy];
        _secret = [secret copy];
    }
    
    return self;
}

-(id)init{
    self = [super init];
    if (self) {
        [[PHAPIRequest allRequests] addObject:self];
    }
    
    return  self;
}

@synthesize token = _token, secret = _secret;
@synthesize delegate = _delegate;
@synthesize urlPath = _urlPath;
@synthesize additionalParameters = _additionalParameters;
@synthesize hashCode = _hashCode;

-(NSURL *) URL{
    if (_URL == nil) {
        NSString *urlString = [NSString stringWithFormat:@"%@?%@",
                               [self urlPath],
                               [self signedParameterString]];
        _URL = [[NSURL alloc] initWithString:urlString]; 
    }
    
    return _URL;
}

-(NSDictionary *) signedParameters{
    if (_signedParameters == nil) {

        //limits the number of preferred languages to 5.
        NSArray *preferredLanguages = [NSLocale preferredLanguages];
        if ([preferredLanguages count] > 5) {
            NSRange range = NSMakeRange(0, 5);
            preferredLanguages = [preferredLanguages subarrayWithRange:range];
        }

        NSMutableDictionary *combinedParams = [[NSMutableDictionary alloc] init];
        
#if PH_USE_UNIQUE_IDENTIFIER==1
        if (![PHAPIRequest optOutStatus]) {
            NSString *device = [[UIDevice currentDevice] uniqueIdentifier];
            [combinedParams setValue:device forKey:@"device"];
        }
#endif
        //This allows for unit testing of request values!
        NSBundle *mainBundle = [NSBundle bundleForClass:[self class]];
        
        NSString
        *nonce = [PHStringUtil uuid],
        *session = [PHAPIRequest session],
        *gid = PHGID(),
        *signatureHash = [NSString stringWithFormat:@"%@:%@:%@:%@:%@", self.token, [PHAPIRequest session], PHGID(), nonce, self.secret],
        *signature = [PHAPIRequest base64SignatureWithString:signatureHash],
        *appId = [[mainBundle infoDictionary] objectForKey:@"CFBundleIdentifier"],
        *appVersion = [[mainBundle infoDictionary] objectForKey:@"CFBundleVersion"],
        *hardware = [[UIDevice currentDevice] hardware],
        *os = [NSString stringWithFormat:@"%@ %@",
               [[UIDevice currentDevice] systemName],
               [[UIDevice currentDevice] systemVersion]],
        *languages = [preferredLanguages componentsJoinedByString:@","];
        if(!appVersion) appVersion = @"NA";
        
        NSNumber 
        *idiom = [NSNumber numberWithInt:(int)UI_USER_INTERFACE_IDIOM()],
        *connection = [NSNumber numberWithInt:PHNetworkStatus()];
        
        [combinedParams addEntriesFromDictionary:self.additionalParameters];  
        NSDictionary *signatureParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                         self.token, @"token",
                                         signature, @"signature",
                                         nonce, @"nonce",
                                         appId, @"app",
                                         hardware,@"hardware",
                                         os,@"os",
                                         idiom,@"idiom",
                                         appVersion, @"app_version",
                                         connection,@"connection",
                                         PH_SDK_VERSION, @"sdk-ios",
                                         languages,@"languages",
                                         session, @"session",
                                         gid, @"gid",
                                         nil];
        
        [combinedParams addEntriesFromDictionary:signatureParams];
        _signedParameters = combinedParams;
    }
    
    return _signedParameters;       
}

-(NSString *) signedParameterString{
    return [[self signedParameters] stringFromQueryComponents];
}

-(void) dealloc{
    [_token release], _token = nil;
    [_secret release], _secret = nil;
    [_URL release], _URL = nil;
    [_connection release], _connection = nil;
    [_signedParameters release], _signedParameters = nil;
    [_connectionData release], _connectionData = nil;
    [_urlPath release], _urlPath = nil;
    [_additionalParameters release], _additionalParameters = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark PHPublisherOpenRequest

-(void) send{
    if (_connection == nil) {
        PH_LOG(@"Sending request: %@", [self.URL absoluteString]);
        NSURLRequest *request = [NSURLRequest requestWithURL:self.URL 
                                                 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
                                             timeoutInterval:PH_REQUEST_TIMEOUT];
        
#ifdef PH_USE_NETWORK_FIXTURES
        _connection = [[WWURLConnection connectionWithRequest:request delegate:self] retain];
#else
        _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
#endif
        [_connection start];
    }
}

-(void)cancel{
    PH_LOG(@"%@ canceled!", NSStringFromClass([self class]));
    [self finish];
}

/*
 * Internal cleanup method
 */
-(void)finish{
    [_connection cancel];
    
    //REQUEST_RELEASE see REQUEST_RETAIN
    [[PHAPIRequest allRequests] removeObject:self];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        PH_LOG(@"Request recieved HTTP response: %d", [httpResponse statusCode]);
    }
    
    /* We want to get response objects for everything */
    [_connectionData release], _connectionData = [[NSMutableData alloc] init];
    [_response release], _response = nil;
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    
    [_connectionData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    PH_NOTE(@"Request finished!");
    if ([self.delegate respondsToSelector:@selector(requestDidFinishLoading:)]) {
        [self.delegate performSelector:@selector(requestDidFinishLoading:) withObject:self withObject:nil];
    }
    
    NSString *responseString = [[NSString alloc] initWithData:_connectionData encoding:NSUTF8StringEncoding];    
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    NSDictionary* resultDictionary = [parser objectWithString:responseString];
    [parser release];
    [responseString release];
    
    [self processRequestResponse:resultDictionary];
}

-(void)afterConnectionDidFinishLoading{
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    PH_LOG(@"Request failed with error: %@", [error localizedDescription]);
    [self didFailWithError:error];
    
    //REQUEST_RELEASE see REQUEST_RETAIN
    [self finish];
}

#pragma mark -
-(void)processRequestResponse:(NSDictionary *)responseData{
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

-(void)didSucceedWithResponse:(NSDictionary *)responseData{
    if ([self.delegate respondsToSelector:@selector(request:didSucceedWithResponse:)]) {
        [self.delegate performSelector:@selector(request:didSucceedWithResponse:) withObject:self withObject:responseData];
    }
    
    [self finish];
}

-(void)didFailWithError:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(request:didFailWithError:)]) {
        [self.delegate performSelector:@selector(request:didFailWithError:) withObject:self withObject:error];
    }
    [self finish];
}

@end
