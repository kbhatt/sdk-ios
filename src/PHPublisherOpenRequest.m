//
//  PHPublisherOpenRequest.m
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 3/30/11.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import "PHPublisherOpenRequest.h"
#import "PHConstants.h"
#import "SDURLSDURLCache.h"
#import "PHURLPrefetchOperation.h"

#if PH_USE_OPENUDID == 1
#import "OpenUDID.h"
#endif

#if PH_USE_MAC_ADDRESS == 1
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <mach-o/dyld.h>

NSString *getMACAddress(void);

NSString *getMACAddress(){
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;

    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;

    if ((mib[5] = if_nametoindex("en0")) == 0) 
    {
        PH_NOTE(@"Error: if_nametoindex error\n");
        return NULL;
    }

    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
    {
        PH_NOTE(@"Error: sysctl, take 1\n");
        return NULL;
    }

    if ((buf = malloc(len)) == NULL) 
    {
        PH_NOTE(@"Could not allocate memory. error!\n");
        return NULL;
    }

    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) 
    {
        PH_NOTE(@"Error: sysctl, take 2");
        return NULL;
    }

    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *macAddress = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X", 
                            *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    macAddress = [macAddress lowercaseString];
    free(buf);

    return macAddress;
}
#endif


@interface PHAPIRequest(Private)
-(void)finish;
+(void)setSession:(NSString *)session;
@end

@implementation PHPublisherOpenRequest

+(void)initialize{
    
    if  (self == [PHPublisherOpenRequest class]){
        // Initializes pre-fetching and webview caching
        SDURLCache *urlSDURLCache = [[SDURLCache alloc] initWithMemoryCapacity:PH_MAX_SIZE_MEMORY_SDURLCache
                                                                 diskCapacity:PH_MAX_SIZE_FILESYSTEM_SDURLCache
                                                                     diskPath:[SDURLCache defaultSDURLCachePath]];
        [NSURLSDURLCache setSharedURLSDURLCache:urlSDURLCache];
        [urlSDURLCache release];
    }
}

-(id)init{
    self = [super init];
    if (self) {
        [self.prefetchOperations addObserver:self forKeyPath:@"operations" options:0 context:NULL];
    }
    
    return  self;
}

@synthesize customUDID = _customUDID;

-(NSDictionary *)additionalParameters{    
    NSMutableDictionary *additionalParameters = [NSMutableDictionary dictionary];

    if (!!self.customUDID) {
        [additionalParameters setValue:self.customUDID forKey:@"d_custom"];
    }
    
#if PH_USE_OPENUDID == 1
        [additionalParameters setValue:[OpenUDID value] forKey:@"d_odid"];
#endif
#if PH_USE_MAC_ADDRESS == 1
    if (![PHAPIRequest optOutStatus]) {
        [additionalParameters setValue:getMACAddress() forKey:@"d_mac"];
    }
#endif
    
    return  additionalParameters;
}

-(NSString *)urlPath{
    return PH_URL(/v3/publisher/open/);
}

-(NSOperationQueue *)prefetchOperations{
    if (_prefetchOperations == nil) {
        _prefetchOperations = [[NSOperationQueue alloc] init];
        [_prefetchOperations setMaxConcurrentOperationCount:PH_MAX_CONCURRENT_OPERATIONS];
    }
    
    return _prefetchOperations;
}

#pragma mark - PHAPIRequest response delegate

-(void)didSucceedWithResponse:(NSDictionary *)responseData{
    
    if ([responseData count] > 0){
        
        NSString *SDURLCachePlist = [PHURLPrefetchOperation getSDURLCachePlistFile];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        if ([fileManager fileExistsAtPath:SDURLCachePlist]){
            
            [fileManager removeItemAtPath:SDURLCachePlist error:NULL];
        }
        [responseData writeToFile:SDURLCachePlist atomically:YES];
        
        NSArray *urlArray = (NSArray *)[responseData valueForKey:@"preSDURLCache"];
        for (NSString *urlString in urlArray){
            
            NSURL *url = [NSURL URLWithString:urlString];
            PHURLPrefetchOperation *urlpo = [[PHURLPrefetchOperation alloc] initWithURL:url];
            [self.prefetchOperations addOperation:urlpo];
            [urlpo release];
        }
        
        NSString *session = (NSString *)[responseData valueForKey:@"session"];
        if (!!session){
            [PHAPIRequest setSession:session];
        }
        
        [fileManager release];
    }
    
    // Don't finish the request before prefetching has completed!
    if ([self.delegate respondsToSelector:@selector(request:didSucceedWithResponse:)]) {
        [self.delegate performSelector:@selector(request:didSucceedWithResponse:) withObject:self withObject:responseData];
    }
}

#pragma mark - PreSDURLCache URL selectors

-(void) downloadPrefetchURLs{
    
    NSString *SDURLCachePlist = [PHURLPrefetchOperation getSDURLCachePlistFile];
    if ([[[[NSFileManager alloc] init] autorelease] fileExistsAtPath:SDURLCachePlist]){
        
        NSMutableDictionary *prefetchUrlDictionary = [[[NSMutableDictionary alloc] initWithContentsOfFile:SDURLCachePlist] autorelease];
        NSArray *urlArray = (NSArray *)[prefetchUrlDictionary objectForKey:@"preSDURLCache"];
        for (NSString *urlString in urlArray){
            
            NSURL *url = [NSURL URLWithString:urlString];
            PHURLPrefetchOperation *urlpo = [[PHURLPrefetchOperation alloc] initWithURL:url];
            [self.prefetchOperations addOperation:urlpo];
            [urlpo release];
        }
    }
}

-(void) cancelPrefetchDownload{
    [self.prefetchOperations cancelAllOperations];
}

-(void) clearPrefetchSDURLCache{
    
}

#pragma mark - NSObject

- (void)dealloc{
    [self.prefetchOperations removeObserver:self forKeyPath:@"operations"];
    
    [_prefetchOperations release], _prefetchOperations = nil;
    [_customUDID release], _customUDID = nil;
    [super dealloc];
}

#pragma mark - NSOperationQueue observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)operation change:(NSDictionary *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"operations"]){
        
        if ([self.prefetchOperations.operations count] == 0){
            if ([self.delegate respondsToSelector:@selector(requestFinishedPrefetching:)]){
                [self.delegate performSelector:@selector(requestFinishedPrefetching:) withObject:self];
            }
            //REQUEST_RELEASE see REQUEST_RETAIN
            [self finish];
        }
    }
}
@end
