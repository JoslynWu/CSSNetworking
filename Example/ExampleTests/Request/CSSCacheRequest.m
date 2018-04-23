//
//  CSSCacheRequest.m
//  CSSNetworkingTests
//
//  Created by Joslyn Wu on 2018/2/7.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSCacheRequest.h"
#import "CSSNormalRequest.h"
#import "CSSRequestDefine.h"

@implementation CSSCacheRequest

- (NSString *)urlForRequest {
    return [NSString stringWithFormat:@"%@%@", baseUrl,@"post"];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.responseDataClass = [CSSNormalResponseData class];
    return self;
}

- (BOOL)isNeedCache {
    return YES;
}

- (CSSNetworkingLogOptions)logOptions {
    return None;
}

@end


@implementation CSSForwarkCacheRequest

- (BOOL)isisNeedForwardCache {
    return YES;
}

@end
