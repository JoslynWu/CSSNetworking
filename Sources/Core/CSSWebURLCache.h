//
//  CSSWebURLCache.h
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/26.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSSWebURLCache : NSURLCache

+ (CSSWebURLCache *)sharedURLCache;

- (void)storeCache:(id)responseObject withRespone:(NSURLResponse *)response forRequest:(NSURLRequest *)request;

- (NSDictionary *)cacheForRequest:(NSURLRequest *)request;

- (void)removeCacheForRequest:(NSURLRequest *)request;

@end
