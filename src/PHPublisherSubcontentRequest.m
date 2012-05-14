//
//  PHPublisherSubcontentRequest.m
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 5/19/11.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import "PHPublisherSubContentRequest.h"
#import "PHConstants.h"
#import "PHARCLogic.h"

@implementation PHPublisherSubContentRequest

@synthesize source = _source;
@synthesize callback = _callback;

-(NSURL *) URL{
    if (_URL == nil) {
        NSString *urlString = [self urlPath];
        _URL = [[NSURL alloc] initWithString:urlString]; 
    }
    
    return _URL;
}

NO_ARC(
-(void)dealloc{
    ([_callback release], _callback = nil);
    [super dealloc];
}
)

@end
