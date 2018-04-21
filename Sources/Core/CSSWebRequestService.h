//
//  CSSWebRequestService.h
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/27.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSNetworking.h"
#import "AFSecurityPolicy.h"

@interface CSSWebRequestService : NSObject

+ (instancetype)shareService;
- (BOOL)containRequestUID:(CSSRequestID)tid;
- (void)cancelAPI:(CSSRequestID)apiUID;
- (CSSRequestID)requestApiAsynchronous:(CSSWebRequestTask *)kernel;

+ (void)parseSuccedData:(id)responseObj task:(CSSWebRequestTask *)task;
+ (void)parseFailedDataWithError:(NSError*)error task:(CSSWebRequestTask *)task;
+ (void)loadDataFromCacheWithTask:(CSSWebRequestTask *)task;

- (CSSWebRequestKernel *)requestBlockOutputWithTask:(CSSWebRequestTask *)task;

@end

