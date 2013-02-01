//
//  PHConnectionManager.h
//  playhaven-sdk-ios
//
//  Created by Lilli Szafranski on 1/31/13.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol PHConnectionManagerDelegate <NSObject>
@optional
- (void)connectionDidFinishLoadingWithRequest:(NSURLRequest *)request
                                     response:(NSURLResponse *)response
                                         data:(NSData *)data
                                   andContext:(id)context;
- (void)connectionDidFailWithError:(NSError *)error request:(NSURLRequest *)request andContext:(id)context;
- (void)connectionWasStoppedWithContext:(id)context;
@end

@interface PHConnectionManager : NSObject
{
}
+ (BOOL)createConnectionFromRequest:(NSURLRequest *)request
                        forDelegate:(id <PHConnectionManagerDelegate>)delegate
                        withContext:(id)context;

+ (void)stopConnectionsForDelegate:(id<PHConnectionManagerDelegate>)delegate;

+ (BOOL)isRequestPending:(NSURLRequest *)request;
+ (BOOL)isRequestComplete:(NSURLRequest *)request;

//+ (NSUInteger)openConnectionCount;
@end

