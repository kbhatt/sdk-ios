//
//  IAPHelper.m
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 3/2/12.
//  Copyright (c) 2012 Playhaven. All rights reserved.
//

#import "IAPHelper.h"
#import "PlayHavenSDK.h"
#import "PHPurchase.h"
#import "PHARCLogic.h"

@interface NSObject(hash)
-(NSString *)hashString;
@end

@implementation NSObject(hash)
-(NSString *)hashString{
    return [NSString stringWithFormat:@"%d",[self hash]];
}
@end

@interface SKProduct (LocalizedPrice)
@property (nonatomic, readonly) NSString *localizedPrice;
@end

@implementation SKProduct (LocalizedPrice)
- (NSString *)localizedPrice {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:self.priceLocale];
    NSString *formattedString = [numberFormatter stringFromNumber:self.price];
    NO_ARC([numberFormatter release];)
    return formattedString;
}
@end


@interface IAPHelper(Private)
-(void)reportPurchase:(PHPurchase *)purchase withResolution:(PHPurchaseResolutionType)resolution;
-(void)reportPurchase:(PHPurchase *)purchase withError:(NSError *)error;
@end

static IAPHelper *sharedIAPHelper;

@implementation IAPHelper

+(IAPHelper *)sharedIAPHelper{
    @synchronized(self){
        if  (sharedIAPHelper == nil){
            sharedIAPHelper = [[super allocWithZone:NULL] init];
        }
    }
    return sharedIAPHelper;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedIAPHelper] retain];
}
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
- (id)retain {
    return self;
}
- (unsigned)retainCount {
    return UINT_MAX; //denotes an object that cannot be released
}
- (oneway void)release {
    // never release
}
- (id)autorelease {
    return self;
}

NO_ARC(
- (void)dealloc {
    // Should never be called, but just here for clarity really.
   ([_pendingPurchases release], _pendingPurchases = nil);
   ([_pendingRequests release], _pendingRequests = nil);
   [super dealloc];
}
)

#pragma mark -
-(NSMutableDictionary *)pendingPurchases{
    if (_pendingPurchases == nil) {
        _pendingPurchases = [[NSMutableDictionary alloc] init];
    }
    return _pendingPurchases;
}

-(NSMutableDictionary *)pendingRequests{
    if (_pendingRequests == nil) {
        _pendingRequests = [[NSMutableDictionary alloc] init];
    }
    return _pendingRequests;
}

-(void)startPurchase:(PHPurchase *)purchase{
    // The first step is requesting product information for this purchase.
    if (!!purchase){
        NSSet *productIdentifiers = [NSSet setWithObject:purchase.productIdentifier];
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
        request.delegate = self;
        [request start];
        
        //storing the purchase and the product request to retrieve later
        [self.pendingPurchases setValue:purchase forKey:[request hashString]];
        [self.pendingRequests setValue:request forKey:[request hashString]];
        NO_ARC([request release];)
    }
}

-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    NSString *key = [request hashString];
    PHPurchase *purchase = [self.pendingPurchases valueForKey:key];
    NSArray *products = response.products;
    SKProduct *product = [products count] == 1 ? [products objectAtIndex:0] : nil;
    
    if ([purchase.productIdentifier isEqualToString:product.productIdentifier]) {
        //ask the user to choose to purchase or not purchase an item
        NSString *message = [NSString stringWithFormat:@"Do you want to buy %d %@ for %@?",purchase.quantity, product.localizedTitle, product.localizedPrice];
        UIAlertView *purchaseAlert = [[UIAlertView alloc] initWithTitle:@"In-Game Store" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Buy", nil];
        [purchaseAlert show];        
        [self.pendingPurchases setObject:purchase forKey:[purchaseAlert hashString]];
        
        NO_ARC([purchaseAlert release];)
    } else {
        //either the purchase or the product request is invalid, report as an error
        [self reportPurchase:purchase withResolution:PHPurchaseResolutionError];
    }
    
    //either way clean up the stored purchase and request
    [self.pendingPurchases removeObjectForKey:key];
    [self.pendingRequests removeObjectForKey:key];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *key = [alertView hashString];
    PHPurchase *purchase = (PHPurchase *)[self.pendingPurchases objectForKey:key];
    if (buttonIndex == 0) {
        //the user has canceled the request
        [self reportPurchase:purchase withResolution:PHPurchaseResolutionCancel];
    } else if (buttonIndex == 1) {
        //start an app store request
        SKPayment *payment = [SKPayment paymentWithProductIdentifier:purchase.productIdentifier];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
        [self.pendingRequests setValue:purchase forKey:[payment hashString]];
    }
    
    //either way, clean up the stored alertview
    [self.pendingPurchases removeObjectForKey:key];
}

#pragma mark-
#pragma VGP Support Implementation


-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    //Adding IAP reporting and VGP to transactions requires some modifications to the
    //payment queue observer. Send IAP Purchase tracking requests whenever a transaction
    //is purchased (SKTransactionStatePurchased), and send IAP Error tracking requests 
    //whenever a transaction dails (SKTransactionStateFailed)
    for (SKPaymentTransaction *transaction in transactions) {
        NSString *key = [transaction.payment hashString];
        PHPurchase *purchase = [self.pendingRequests valueForKey:key];
        if (purchase == nil){
            //In the case that a transcaction is being restored, we need to
            //generate a new purchase object so that IAP transactions may
            //be reported accurately.
            purchase = [PHPurchase new];
            purchase.productIdentifier = transaction.payment.productIdentifier;
            purchase.quantity = transaction.payment.quantity;
            NO_ARC([purchase autorelease];)
        }
        
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                //This would normallly be the point where an in app purchase would
                //be delivered. Instead we're just doing the necessary reporting
                //to support IAP tracking and VGP content units.
                
                NSLog(@"IAPHelper: Purchased %@!", transaction.payment.productIdentifier);
                [self reportPurchase:purchase withResolution:PHPurchaseResolutionBuy];
                [self.pendingPurchases removeObjectForKey:key];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                //Reporting failed transactions and finalizing them.
                NSLog(@"IAPHelper: Failed to purchase %@!", transaction.payment.productIdentifier);
                [self reportPurchase:purchase withError:transaction.error];
                [self.pendingPurchases removeObjectForKey:key];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            default:
                break;
        }
    }
}

-(void)reportPurchase:(PHPurchase *)purchase withResolution:(PHPurchaseResolutionType)resolution{
    //PHPurchase objects are generated from VGP content units. It is important to preserve
    //these instances throughout the IAP process. This way, these purchase instances may be
    //used to report purchases to PlayHaven, as well as back to the originating content unit.
    if (!!purchase) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *token = [defaults valueForKey:@"ExampleToken"];
        NSString *secret = [defaults valueForKey:@"ExampleSecret"];
        
        //Reporting to the Tracking API
        PHPublisherIAPTrackingRequest *request = [PHPublisherIAPTrackingRequest requestForApp:token secret:secret product:purchase.productIdentifier quantity:purchase.quantity resolution:resolution];
        [request send];
        
        //Reporting back to the content unit.
        [purchase reportResolution:resolution];
    }
}

-(void)reportPurchase:(PHPurchase *)purchase withError:(NSError *)error{
    //To get a more complete picture of your IAP implementation, report any errors, user
    //cancellations, or other incomplete transactions to PlayHaven. It is also important
    //to inform the originating content unit (for VGP-driven purchases) of the error.
    if (!!purchase){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *token = [defaults valueForKey:@"ExampleToken"];
        NSString *secret = [defaults valueForKey:@"ExampleSecret"];
        
        //Reporting to the Tracking API
        PHPublisherIAPTrackingRequest *request = [PHPublisherIAPTrackingRequest requestForApp:token secret:secret product:purchase.productIdentifier quantity:purchase.quantity error:error];
        [request send];
        
        //Reporting back to the content unit
        [purchase reportResolution:request.resolution];
    }
}

-(void)restorePurchases{
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

@end
