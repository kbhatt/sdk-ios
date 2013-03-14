//
//  PHStoreProductViewControllerDelegate.m
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 9/18/12.
//
//

//  This will ensure the PH_USE_STOREKIT macro is properly set.

#if PH_USE_STOREKIT != 0
#import "PHStoreProductViewControllerDelegate.h"

static PHStoreProductViewControllerDelegate *_delegate = nil;

@interface PHStoreProductViewControllerDelegate()
- (UIViewController *)visibleViewController;
@end

@implementation PHStoreProductViewControllerDelegate
+ (PHStoreProductViewControllerDelegate *)getDelegate
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_delegate == nil) {
            _delegate = [PHStoreProductViewControllerDelegate new];
            [[NSNotificationCenter defaultCenter] addObserver:_delegate
                                                     selector:@selector(appDidEnterBackground)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:nil];
        }
    });

    return _delegate;
}

// TODO: This class isn't following retain/release principles correctly and is missing dealloc. Investigate further
- (UIViewController *)visibleViewController
{
    if (_visibleViewController == nil) {
        _visibleViewController = [[UIViewController alloc] init];
    }

    UIWindow *applicationWindow = [[[UIApplication sharedApplication]windows] objectAtIndex:0];
    [applicationWindow addSubview:_visibleViewController.view];

    return _visibleViewController;
}

- (BOOL)showProductId:(NSString *)productId
{
    if ([SKStoreProductViewController class]) {
        SKStoreProductViewController *controller = [SKStoreProductViewController new];
        NSDictionary *parameters = [NSDictionary dictionaryWithObject:productId forKey:SKStoreProductParameterITunesItemIdentifier];
        controller.delegate = self;
        [controller loadProductWithParameters:parameters completionBlock:nil];

        [[self visibleViewController] presentModalViewController:controller animated:YES];
        [controller release];
        return true;
    }

    return false;
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:^(void){
        [_visibleViewController.view removeFromSuperview];
    }];
}

#pragma mark -
#pragma NSNotification Observers
- (void)appDidEnterBackground
{
    // This will automatically dismiss the view controller when the app is backgrounded
    if (_visibleViewController.modalViewController)
        [_visibleViewController dismissModalViewControllerAnimated:NO];
    [_visibleViewController.view removeFromSuperview];
}
@end
#endif
