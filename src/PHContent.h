//
//  PHContent.h (formerly PHContent.h)
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 3/31/11.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum{
    PHContentTransitionUnknown,
    PHContentTransitionModal,
    PHContentTransitionDialog
} PHContentTransitionType;

@interface PHContent : NSObject {
    NSDictionary *_contentFrameDict;
    NSDictionary *_totalFrameDict;
    NSDictionary *_closeButtonOffsetDict;
    NSDictionary *_chromeDict;
    NSURL *_URL;
    PHContentTransitionType _transition;
    NSDictionary *_context;
    NSTimeInterval _closeButtonDelay;
    NSString *_closeButtonURLPath;
}

+(id)contentWithDictionary:(NSDictionary *)dictionaryRepresentation;

@property (nonatomic, retain) NSURL *URL;
@property (nonatomic, assign) PHContentTransitionType transition;
@property (nonatomic, retain) NSDictionary *context;
@property (nonatomic, assign) NSTimeInterval closeButtonDelay;
@property (nonatomic, copy) NSString *closeButtonURLPath;
@property (nonatomic, retain) NSDictionary *chromeDict;
@property (nonatomic, retain) NSDictionary *closeStatesURLs;
@property (nonatomic, copy) NSString *borderFrameURL;

-(CGRect)contentFrameForOrientation:(UIInterfaceOrientation)orientation;
-(void)setContentFrameWithDictionary:(NSDictionary *)contentFrameDict;

-(CGRect)totalFrameForOrientation:(UIInterfaceOrientation)orientation;
-(void)setTotalFrameWithDictionary:(NSDictionary *)totalFrameDict;

-(CGPoint)closeOffsetForOrientation:(UIInterfaceOrientation)orientation;
-(void)setCloseOffsetWithDictionary:(NSDictionary *)closeOffsetDict;

-(NSDictionary*)closeButtonStateURLs;

-(BOOL)hasCustomBorder;
@end
