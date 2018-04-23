//
//  CSSNetworkingManager+Private.h
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/26.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSNetworkingManager.h"

@interface CSSNetworkingManager ()

- (void)startRequestWithTask:(CSSWebRequestTask *)task;

/**
 严格的成功界定（业务的成功)
 默认为`resp.respType = success`
 */
- (BOOL)strictSuccessForResponse:(CSSWebResponse *)resp;

- (void)globalSuccessHandleForTask:(CSSWebRequestTask *)task;

- (void)globalFailureHandleForTask:(CSSWebRequestTask *)task;

- (CSSWebResponseData *)customProcessForResponse:(CSSWebResponse *)resp;

@end
