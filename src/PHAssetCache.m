//
//  PHAssetCache.m
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 10/2/12.
//
//

#import "PHAssetCache.h"
#import "PHConstants.h"

@implementation PHAsset
+(PHAsset *)assetFromNSCachedURLResponse:(NSCachedURLResponse *)cachedURLResponse{
    PHAsset *result = [PHAsset new];
    result.data = cachedURLResponse.data;
    result.MIMEType = cachedURLResponse.response.MIMEType;
    result.URL = cachedURLResponse.response.URL;
    result.textEncodingName = cachedURLResponse.response.textEncodingName;
    return [result autorelease];
}
@end

@implementation PHAssetCache
+(void)initialize{
    if  (self == [PHAssetCache class]){
        // Initializes pre-fetching and webview caching
        PH_SDURLCACHE_CLASS *urlCache = [[PH_SDURLCACHE_CLASS alloc] initWithMemoryCapacity:PH_MAX_SIZE_MEMORY_CACHE
                                                                               diskCapacity:PH_MAX_SIZE_FILESYSTEM_CACHE
                                                                                   diskPath:[PH_SDURLCACHE_CLASS defaultCachePath]];
        [NSURLCache setSharedURLCache:urlCache];
        [urlCache release];
    }
}

+(PHAssetCache *)sharedAssetCache{
    static PHAssetCache *sharedAssetCache;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sharedAssetCache == nil) {
            sharedAssetCache = [PHAssetCache new];
        }
    });
	
	return sharedAssetCache;
}

-(id)init{
    self = [super init];
    if (self) {
        _connectionDictionary = [NSMutableDictionary new];
    }
    
    return self;
}

-(BOOL)precacheAssetAtURL:(NSURL *)url{
    if ([self.connectionDictionary objectForKey:url]){
        return FALSE;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                         timeoutInterval:PH_REQUEST_TIMEOUT];
    NSURLConnection *newConnection = [NSURLConnection connectionWithRequest:request delegate:self];
    [newConnection start];
    
    [self.connectionDictionary setObject:newConnection forKey:url];
    return TRUE;
}

-(void)stopPrecaching{
    [[self.connectionDictionary allValues] makeObjectsPerformSelector:@selector(cancel)];
    [self.connectionDictionary removeAllObjects];
}

-(PHAsset *)assetAtURL:(NSURL *)url{
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:PH_REQUEST_TIMEOUT];
    
    NSCachedURLResponse *response = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    if (response) {
        return [PHAsset assetFromNSCachedURLResponse:response];
    }
    
    return nil;
}

#pragma mark - NSURLConnectionDelegate methods
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    [self removeConnection:connection];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [self removeConnection:connection];
}

-(void)removeConnection:(NSURLConnection *)connection{
    NSURL *url = connection.originalRequest.URL;
    if (url) {
        //remove this connection from the connection table
        [self.connectionDictionary removeObjectForKey:url];
    }
}


@end
