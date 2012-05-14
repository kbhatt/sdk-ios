//
//  PublisherOpenViewController.m
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 4/25/11.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import "PublisherOpenViewController.h"
#import "PHARCLogic.h"

@interface PHAPIRequest(Private)
+(void)setSession:(NSString *)session;
@end

@implementation PublisherOpenViewController
@synthesize customUDIDField;

-(void)startRequest{
    [super startRequest];
    
    /*
     * This is an alternate implementation which allows you you get response 
     * data from API requests. This isn't necessary for most developers.
     */
    
    PHPublisherOpenRequest * request = [PHPublisherOpenRequest requestForApp:self.token secret:self.secret];
    request.customUDID = self.customUDIDField.text;
    request.delegate = self;
    [request send];
}

NO_ARC(
-(void)dealloc{
    [PHAPIRequest cancelAllRequestsWithDelegate:self];
    [customUDIDField release];
    [super dealloc];
}
)

#pragma mark - PHAPIRequestDelegate
-(void)request:(PHAPIRequest *)request didSucceedWithResponse:(NSDictionary *)responseData{
    NSString *message = [NSString stringWithFormat:@"[OK] Success with response: %@",responseData];
    [self addMessage:message];
    
    [self finishRequest];
}

-(void)request:(PHAPIRequest *)request didFailWithError:(NSError *)error{
    NSString *message = [NSString stringWithFormat:@"[ERROR] Failed with error: %@", error];
    [self addMessage:message];
    
    [self finishRequest];
}

-(void)requestFinishedPrefetching:(PHAPIRequest *)request{
    [self addMessage:@"Finished prefetching!"];
    [self addElapsedTime];
}

- (void)viewDidUnload {
    [self setCustomUDIDField:nil];
    [super viewDidUnload];
}
- (IBAction)touchedClearGID:(id)sender {
    PHClearGID();
    [self addMessage:@"GID cleared!"];
}

- (IBAction)touchedClearSession:(id)sender{ 
    [PHAPIRequest setSession:nil];
    [self addMessage:@"session cleared!"];
}
@end
