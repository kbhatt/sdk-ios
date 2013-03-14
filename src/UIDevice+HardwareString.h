//
//  UIDevice+PlatformString.h
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 4/20/11.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * @file
 * @internal
 * @brief Category on UIDevice to find the <tt>hw.machine</tt> name of the current device
 * (<tt>iPhone4,1</tt> for instance), special cases for handling simulator builds
 **/
// TODO: Move this out of a category.
@interface UIDevice (HardwareString)
- (NSString *)hardware;
@end
