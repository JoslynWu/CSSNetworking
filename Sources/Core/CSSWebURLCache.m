//
//  CSSWebURLCache.m
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/26.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSWebURLCache.h"
#import "CSSNetworking.h"

static NSUInteger cacheMemorySize = 100*1024*1024;
static NSUInteger cacheDiskSize   = 100*1024*1024;

@implementation CSSWebURLCache

+ (CSSWebURLCache *)sharedURLCache {
    static CSSWebURLCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CSSWebURLCache alloc] initWithMemoryCapacity:cacheMemorySize diskCapacity:cacheDiskSize diskPath:@"cs_web_url_cache"];
        [NSURLCache setSharedURLCache:instance];
    });
    return instance;
}

-(NSURLRequest *)storedRquest:(NSURLRequest*)orignalURL {
    NSMutableString *urlBodyString =  [[NSMutableString alloc] initWithData:orignalURL.HTTPBody encoding:NSUTF8StringEncoding];
    NSString *sign = [orignalURL valueForHTTPHeaderField:@"sign"] ?: @"";
    NSString *urlString = [NSString stringWithFormat:@"%@_%@_%@",[orignalURL.URL absoluteString], sign, urlBodyString];
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000)
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
#elif
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#endif
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    return storeRequest;
}

-(void)storeCache:(NSDictionary *)responseObject withRespone:(NSURLResponse *)response forRequest:(NSURLRequest *)request {
    NSError *error;
    if (![NSJSONSerialization isValidJSONObject:responseObject]) {
        [self _logWithTips:@"store cache failure" Content:@"invalid json"];
        return;
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:responseObject options:kNilOptions error:&error];
    if (error) {
        [self _logWithTips:@"store cache error" Content:error.localizedFailureReason];
        return;
    }
    CSSWebURLCache *cache = [CSSWebURLCache sharedURLCache];
    NSCachedURLResponse *urlCacheResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];
    
    [cache storeCachedResponse:urlCacheResponse forRequest:[self storedRquest:request]];
}

-(NSDictionary *)cacheForRequest:(NSURLRequest *)request {
    CSSWebURLCache *cache = [CSSWebURLCache sharedURLCache];
    NSCachedURLResponse *response = [cache cachedResponseForRequest:[self storedRquest:request]];
    NSData *data = response.data;
    if (!data) {
        [self removeCacheForRequest:request];
        return nil;
    }
    NSError *error;
    NSDictionary *cacheDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        [self _logWithTips:@"load cache error" Content:error.localizedFailureReason];
        [self removeCacheForRequest:request];
        return nil;
    }
    
    if(cacheDictionary == nil) {
        [self removeCacheForRequest:request];
        return nil;
    }
    return cacheDictionary;
}

-(void)removeCacheForRequest:(NSURLRequest *)request {
    [[CSSWebURLCache sharedURLCache] removeCachedResponseForRequest:[self storedRquest:request]];
}

#pragma mark  -  private
- (void)_logWithTips:(NSString *)tips Content:(NSString *)content  {
    if (([CSSNetworkingManager sharedClient].logOptions & Exception) != Exception) {
        return;
    }
    CSSNetworkLog(@"[CSSNetworking] %@: %@", tips, content);
}

@end

