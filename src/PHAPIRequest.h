//
//  PHAPIRequest.h
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 3/30/11.
//  Copyright 2011 Playhaven. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PHARCLogic.h"

@class PHAPIRequest;
@protocol PHAPIRequestDelegate <NSObject>
-(void)request:(PHAPIRequest *)request didSucceedWithResponse:(NSDictionary *)responseData;
-(void)request:(PHAPIRequest *)request didFailWithError:(NSError *)error;
@end

@interface PHAPIRequest : NSObject {
    NSURLConnection *_connection;
    NSMutableData *_connectionData;
    NSURLResponse *_response;
}

+(NSString *) base64SignatureWithString:(NSString *)string;
+(NSString *) session;

+(BOOL)optOutStatus;
+(void)setOptOutStatus:(BOOL)yesOrNo;

+(id)requestForApp:(NSString *)token secret:(NSString *)secret;
+(id)requestWithHashCode:(int)hashCode;
+(void)cancelAllRequestsWithDelegate:(id) delegate;
+(int)cancelRequestWithHashCode:(int)hashCode;

@property (nonatomic, copy) NSString *urlPath;
@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, readonly) NSString *token;
@property (nonatomic, readonly) NSString *secret;
@property (nonatomic, readonly) NSDictionary *signedParameters;
@property (nonatomic, IF_ARC(unsafe_unretained, retain)) id<NSObject> delegate;
@property (nonatomic, retain) NSDictionary *additionalParameters;
@property (nonatomic, assign) int hashCode;

-(NSString *)signedParameterString;

-(void)send;
-(void)cancel;

-(void)processRequestResponse:(NSDictionary *)responseData;

-(void)didSucceedWithResponse:(NSDictionary *)responseData;
-(void)didFailWithError:(NSError *)error;

@end
