//
//  PHURLLoader.h
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 2/9/11.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PHARCLogic.h"

@class PHURLLoader;
@protocol PHURLLoaderDelegate<NSObject>
@optional
-(void)loaderFinished:(PHURLLoader *)loader;
-(void)loaderFailed:(PHURLLoader *)loader;
@end


@interface PHURLLoader : NSObject {
    NSURLConnection *_connection;
    NSInteger _totalRedirects;
}


+(void)invalidateAllLoadersWithDelegate:(id <PHURLLoaderDelegate>) delegate;
+(PHURLLoader *)openDeviceURL:(NSString*)url;

@property (nonatomic, IF_ARC(unsafe_unretained, assign)) id <PHURLLoaderDelegate> delegate;
@property (nonatomic, retain) NSURL *targetURL;
@property (nonatomic, assign) BOOL opensFinalURLOnDevice;
@property (nonatomic, retain) id context;

-(void)open;
-(void)invalidate;
@end
