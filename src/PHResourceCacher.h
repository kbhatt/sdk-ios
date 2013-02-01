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

@interface PHResourceCacher : NSObject <PHConnectionManagerDelegate>
- (id)initWithThingsToDownload:(id)things;
+ (id)cacherWithThingsToDownload:(id)things;
@end
