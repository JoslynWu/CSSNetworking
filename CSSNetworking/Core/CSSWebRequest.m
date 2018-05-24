//
//  CSSWebRequest.m
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/27.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSWebRequest.h"
#import <CSSModel/CSSModel.h>
#import "CSSWebRequestService.h"
#import "CSSNetworkingDefine.h"
#import "CSSNetworkingManager+Private.h"
#import "CSSWebRequestTaskCollector.h"

@implementation CSSWebRequestData

@end


@interface CSSWebRequest()

@property (nonatomic, assign, readwrite)  NSInteger requestId;

@end

@implementation CSSWebRequest

#pragma mark - lifecycle
- (void)dealloc {
    [self cancelFetch];
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _responseDataClass = [CSSWebResponseData class];
    _logOptions = None;
    return self;
}

#pragma mark  -  public
- (NSString *)sign {
    return _sign ?: @"";
}

- (CSSResponseSerializerType)responseSerializerType {
    return _responseSerializerType;
}

- (CSSWebRequestMethod)requestMethod {
    return _requestMethod;
}

- (BOOL)isNeedCache {
    return _needCache;
}

- (BOOL)isNeedEncrypt {
    return _needEncrypt;
}

- (CSSProcessStyle)processStyle {
    return _processStyle;
}

- (NSDictionary *)formData {
    return _formData;
}

- (NSString *)urlForRequest {
    return _urlForRequest;
}

- (NSDictionary *)headers {
    return _headers;
}

- (NSDictionary *)parameters {
    if(self.requestData) {
        _parameters = (NSDictionary *)[self.requestData css_JSONObject];
    }
    return _parameters;
}

- (void)cancelFetch {
    if (self.requestId == 0 || self.requestId == CSSRequestInvalidID) {
        return;
    }
    [[CSSWebRequestService shareService] cancelAPI:self.requestId];
}

- (void)sendRequest {
    [self cancelFetch];
    CSSWebRequestTask *task = [self _buildWebRequest];
    self.requestId = [[CSSWebRequestService shareService] requestApiAsynchronous:task];
    [[CSSNetworkingManager sharedClient] startRequestWithTask:task];
    [self _logWithTask:task];
}

#pragma mark  -  private
-(CSSWebRequestTask *)_buildWebRequest {
    CSSWebRequestTask *task = [CSSWebRequestTask new];
    task.webRequest = self;
    task.kernel = [[CSSWebRequestService shareService] requestBlockOutputWithTask:task];
    
    return task;
}

- (void)_logWithTask:(CSSWebRequestTask *)task {
    BOOL flag = NO;
    if (([CSSNetworkingManager sharedClient].logOptions & Request) == Request) {
        flag = YES;
    }
    
    if (([CSSNetworkingManager sharedClient].logOptions & Single) == Single) {
        if ((self.logOptions & Request) == Request) {
            flag = YES;
        }
    }
    if (!flag) {
        return;
    }
    
    CSSNetworkLog(@"\n****************** [CSSNetworking] start request: ****************** \
                 \nclass: %@ \
                 \nid: %zd \
                 \nurl: %@ \
                 \nparameters: \n%@ \
                 \n********************************************************************",
                 NSStringFromClass([self class]),
                 task.tid,
                 task.dataTask.originalRequest.URL.absoluteString,
                 task.webRequest.parameters);
}

@end

