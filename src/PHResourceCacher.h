//
//  PHResourceCacher.h
//  playhaven-sdk-ios
//
//  Created by Lilli Szafranski on 1/31/13.
//  Copyright 2013 Playhaven. All rights reserved.
//

#import <Foundation/Foundation.h>

// TODO: Optimize the imports
#import "PHConnectionManager.h"
#import "PlayHavenSDK.h"


typedef enum
{
    PHPriorityStartImmediately,
    PHPriorityStartNext,
    PHPriorityStartLater,
} PHCacherPriority;

@interface PHResourceCacher : NSObject <PHConnectionManagerDelegate, UIWebViewDelegate, PHPublisherContentRequestDelegate>
@property (nonatomic, retain) UIWebView *webView;

//- (id)initWithThingsToDownload:(id)things;
//+ (id)cacherWithThingsToDownload:(id)things;

+ (void)cacheObject:(NSDictionary *)object withPriority:(PHCacherPriority)priority;
+ (BOOL)isRequestPending:(NSURLRequest *)request;
//+ (BOOL)isRequestComplete:(NSURLRequest *)request;

+ (void)pause;
+ (void)resume;

+ (void)setToken:(NSString *)token andSecret:(NSString *)secret;
@end
