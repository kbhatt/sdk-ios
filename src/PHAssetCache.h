//
//  PHAssetCache.h
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 10/2/12.
//
//

#import <Foundation/Foundation.h>

/* Data object returned by PHAssetCache, contains all the necessary information to make use of assets */
@interface PHAsset: NSObject
+(PHAsset *)assetFromNSCachedURLResponse:(NSCachedURLResponse *)cachedURLResponse;
@property(nonatomic, retain) NSData *data;
@property(nonatomic, copy) NSString *MIMEType;
@property(nonatomic, copy) NSString *textEncodingName;
@property(nonatomic, retain) NSURL *URL;
@end

/* Singleton for transparently retrieving and restoring network assets 
   (templates, images, etc.)
   Prevents redundant preloads of assets (keeps track of assets that are being 
   preloaded, cancels preloads when actual loads will happen) */
@interface PHAssetCache : NSObject<NSURLConnectionDataDelegate>
/* Singleton accessor */
+(PHAssetCache * )sharedAssetCache;

@property (nonatomic,readonly) NSMutableDictionary *connectionDictionary;

/* Asks the cache to retrieve and store the asset at the given URL.
   Returns TRUE if a new preload is started.
   Returns FALSE if there is an active preload for this URL. */
-(BOOL)precacheAssetAtURL:(NSURL *)url;

/* Stops all active preload requests */
-(void)stopPrecaching;

/* Returns the asset for the given URL. 
   Returns nil if an asset could not be found */
-(PHAsset *)assetAtURL:(NSURL *)url;
@end
