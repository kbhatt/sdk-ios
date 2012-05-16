//
//  PHContentView.h (formerly PHAdUnitView.h)
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 4/1/11.
//  Copyright 2011 Playhaven. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "PHURLLoader.h"
#import "PHARCLogic.h"

@class PHContent;
@class PHContentView;
@class PHContentWebView;
@protocol PHContentViewDelegate<NSObject>
@optional
-(void) contentViewDidShow:(PHContentView *)contentView;
-(void) contentViewDidLoad:(PHContentView *)contentView;
-(void) contentViewDidDismiss:(PHContentView *)contentView;
-(void) contentView:(PHContentView *)contentView didFailWithError:(NSError *)error;
-(UIImage *) contentView:(PHContentView *)contentView imageForCloseButtonState:(UIControlState) state;
-(UIColor *) borderColorForContentView:(PHContentView *)contentView;
@end

@interface PHContentView : UIView<UIWebViewDelegate, PHURLLoaderDelegate> {
    UIInterfaceOrientation _orientation;
    
    UIWebView *_webView;
    BOOL _willAnimate;
    
    NSMutableDictionary *_redirects;
    UIActivityIndicatorView *_activityView;
}

+(PHContentView *)dequeueContentViewInstance;
+(void)enqueueContentViewInstance:(PHContentView *)contentView;

-(id)initWithContent:(PHContent *)content;

@property(nonatomic, retain) PHContent *content;
@property(nonatomic, IF_ARC(unsafe_unretained, assign)) NSObject<PHContentViewDelegate> *delegate;
@property(nonatomic, IF_ARC(unsafe_unretained, assign)) UIView *targetView;

-(void) show:(BOOL)animated;
-(void) dismiss:(BOOL)animated;

-(void)redirectRequest:(NSString *)urlPath toTarget:(id)target action:(SEL)action;
-(BOOL)sendCallback:(NSString *)callback withResponse:(id)response error:(id)error;


-(void)dismissFromButton;
@end
