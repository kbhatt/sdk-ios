//
//  PHContent.m (formerly PHContent.m)
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 3/31/11.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import "PHContent.h"

@interface PHContent ()
-(CGRect)frameForOrientation:(UIInterfaceOrientation)orientation fromDict:(NSDictionary*)dict;
@end

@implementation PHContent

+(id) contentWithDictionary:(NSDictionary *)dictionaryRepresentation{
    BOOL 
    shouldCreateInstance = !![dictionaryRepresentation valueForKey:@"frame"];
    shouldCreateInstance = shouldCreateInstance && !![dictionaryRepresentation valueForKey:@"url"];
    shouldCreateInstance = shouldCreateInstance && !![dictionaryRepresentation valueForKey:@"transition"];
    
    if (shouldCreateInstance) {
        PHContent *result = [[[PHContent alloc] init] autorelease];
        
        // complete encapsulating frame (with border graphic)
        id totalFrameValue = [dictionaryRepresentation valueForKey:@"frame"];
        if ([totalFrameValue isKindOfClass:[NSString class]]) {
            [result setTotalFrameWithDictionary:
             [NSDictionary dictionaryWithObjectsAndKeys:
              totalFrameValue, totalFrameValue, nil]]; // in case of PH_FULLSCREEN
            
        } else if ([totalFrameValue isKindOfClass:[NSDictionary class]]) {
            [result setTotalFrameWithDictionary:totalFrameValue];
        } else {
            //we seem to have some invalid value here, yuck
            return nil;
        }
        
        // content area (without border graphic). Also used for legacy.
        id contentFrameValue = [dictionaryRepresentation valueForKey:@"content_frame"];
        if ([contentFrameValue isKindOfClass:[NSString class]]) {
            [result setContentFrameWithDictionary:
             [NSDictionary dictionaryWithObjectsAndKeys:
              contentFrameValue, contentFrameValue, nil]]; // in case of PH_FULLSCREEN
            
        } else if ([contentFrameValue isKindOfClass:[NSDictionary class]]) {
            [result setContentFrameWithDictionary:contentFrameValue];
        } else {
            [result setContentFrameWithDictionary:nil]; // legacy so doesn't have content frame, only complete frame
        }
        
        result.chromeDict = [dictionaryRepresentation valueForKey:@"chrome"];
        
        if (result.chromeDict) {
            result.closeStatesURLs = [result.chromeDict objectForKey:@"close_btn"];
            result.borderFrameURL = [result.chromeDict objectForKey:@"border_frame"];
        }
        
        NSDictionary *closeOffset = [dictionaryRepresentation valueForKey:@"close_offset"];
        [result setCloseOffsetWithDictionary:closeOffset];
        
        NSString *url = [dictionaryRepresentation valueForKey:@"url"];
        result.URL = [NSURL URLWithString:url];
        
        NSString *transition = [dictionaryRepresentation valueForKey:@"transition"];
        if ([@"PH_MODAL" isEqualToString:transition]) {
            result.transition = PHContentTransitionModal;
        } else if ([@"PH_DIALOG" isEqualToString:transition]) {
            result.transition = PHContentTransitionDialog;
        }
        
        NSDictionary *payload = [dictionaryRepresentation valueForKey:@"context"];
        result.context = payload;
        
        NSTimeInterval closeButtonDelay = [[dictionaryRepresentation valueForKey:@"close_delay"] floatValue];
        if (closeButtonDelay > 0.0f) {
            result.closeButtonDelay = closeButtonDelay;
        }
        
        NSString *closeButtonURLPath = [dictionaryRepresentation valueForKey:@"close_ping"];
        result.closeButtonURLPath = closeButtonURLPath;
        
        
        return result;
    } else {
        return nil;
    }
    
}

-(id)init{
    if ((self = [super init])) {
        _closeButtonDelay = 10.0f;
    }
    
    return  self;
}


@synthesize URL = _URL, transition = _transition, context = _context, closeButtonDelay = _closeButtonDelay, closeButtonURLPath = _closeButtonURLPath,
            chromeDict = _chromeDict, borderFrameURL = _borderFrameURL, closeStatesURLs = _closeStatesURLs;

-(void) dealloc{
    [_URL release], _URL = nil;
    [_context release], _context = nil;
    [_closeButtonURLPath release], _closeButtonURLPath = nil;
    [_contentFrameDict release], _contentFrameDict = nil;
    [_totalFrameDict release], _totalFrameDict = nil;
    [super dealloc];
}

-(CGRect)frameForOrientation:(UIInterfaceOrientation)orientation fromDict:(NSDictionary *)dict {
    NSString *orientationKey = (UIInterfaceOrientationIsLandscape(orientation)) ? @"PH_LANDSCAPE" : @"PH_PORTRAIT";
    NSDictionary *frameValue = [dict valueForKey:orientationKey];
    
    if (!![dict valueForKey:@"PH_FULLSCREEN"]) {
        CGRect frame = [UIScreen mainScreen].applicationFrame;
        CGFloat 
        width = frame.size.width,
        height = frame.size.height;
        
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            return CGRectMake(0, 0, height, width);
        } else {
            return CGRectMake(0, 0, width, height);
        }
    } else if (!!frameValue){
        
        CGFloat
        x = [[frameValue valueForKey:@"x"] floatValue],
        y = [[frameValue valueForKey:@"y"] floatValue],
        w = [[frameValue valueForKey:@"w"] floatValue],
        h = [[frameValue valueForKey:@"h"] floatValue];
        
        return CGRectMake(x, y, w, h);
    } else {
        //no frame data for this orientation
        return CGRectNull;
    }
}

-(CGRect)contentFrameForOrientation:(UIInterfaceOrientation)orientation{
    
    if (_contentFrameDict)
        return [self frameForOrientation:orientation fromDict:_contentFrameDict];
    else
        return [self frameForOrientation:orientation fromDict:_totalFrameDict]; // legacy so no difference between frames
}

-(CGRect)totalFrameForOrientation:(UIInterfaceOrientation)orientation {
    return [self frameForOrientation:orientation fromDict:_totalFrameDict];
}

-(CGPoint)closeOffsetForOrientation:(UIInterfaceOrientation)orientation {
    NSString *orientationKey = (UIInterfaceOrientationIsLandscape(orientation)) ? @"PH_LANDSCAPE" : @"PH_PORTRAIT";
    NSDictionary *frameValue = [_closeButtonOffsetDict valueForKey:orientationKey];
    
    if (frameValue) {
        CGFloat
        x_offset = [[frameValue valueForKey:@"x-offset"] floatValue],
        y_offset = [[frameValue valueForKey:@"y-offset"] floatValue];
        
        return CGPointMake(x_offset, y_offset);
    } else {
        return CGPointZero;
    }
    
}

-(void)setCloseOffsetWithDictionary:(NSDictionary *)closeOffsetDict {
    if (_closeButtonOffsetDict != closeOffsetDict) {
        [_closeButtonOffsetDict release], _closeButtonOffsetDict = closeOffsetDict;
    }
}
-(void)setTotalFrameWithDictionary:(NSDictionary *)totalFrameDict {
    if (_totalFrameDict != totalFrameDict) {
        [_totalFrameDict release], _totalFrameDict = [totalFrameDict retain];
    }
}

-(void)setContentFrameWithDictionary:(NSDictionary *)contentFrameDict {
    if (_contentFrameDict != contentFrameDict) {
        [_contentFrameDict release], _contentFrameDict = [contentFrameDict retain];
    }
}

-(BOOL)hasCustomBorder {
    return (self.borderFrameURL != nil);
}
@end
