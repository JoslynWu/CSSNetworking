//
//  CSSNetworkingManager.h
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/26.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "CSSNetworkingDefine.h"

@class CSSNetworkingManager;
@class CSSWebRequestTask;
@class CSSWebResponse;
@class CSSWebResponseData;

@protocol CSSNetworingHandleDelegate <NSObject>

@optional
/**
 配置全局header

 @param manager manager
 @param task task
 @return 全局header
 */
- (NSDictionary *)manager:(CSSNetworkingManager *)manager globalHeaderForTask:(CSSWebRequestTask *)task;

/**
 成功的默认全局操作
 
 @param manager manager
 @param task task
 */
- (void)manager:(CSSNetworkingManager *)manager globalSuccessHandleForTask:(CSSWebRequestTask *)task;

/**
 失败的默认全局操作
 
 @param manager manager
 @param task task
 */
- (void)manager:(CSSNetworkingManager *)manager globalFailureHandleForTask:(CSSWebRequestTask *)task;

/**
 严格的成功界定（业务的成功)
 使用场景：
 - 本地缓存的条件之一。
 - `CSSMultiRequestViewModel`的成功界定。

 @param manager manager
 @param resp resp
 @return 业务的成功界定
 */
- (BOOL)manager:(CSSNetworkingManager *)manager strictSuccessForResponse:(CSSWebResponse *)resp;

#pragma mark - ********************* 加解密 *********************
/**
 加密
 request->needEncrypt为YES时调用
 
 @param manager manager
 @param data 被加密数据
 @return 加密后数据
 */
- (id)manager:(CSSNetworkingManager *)manager encryptData:(id)data;

/**
 解密
 request->needEncrypt为YES时调用
 
 @param manager manager
 @param data 被解密数据
 @return 解密后数据
 */
- (id)manager:(CSSNetworkingManager *)manager decryptData:(id)data;


#pragma mark - ********************* 自定义数据解析（Json -> Model） *********************
/**
 自定义数据解析

 @param manager manager
 @param resp 响应的数据
 @return 解析后的数据
 */
- (CSSWebResponseData *)manager:(CSSNetworkingManager *)manager customProcessForResponse:(CSSWebResponse *)resp;

@end


@interface CSSNetworkingManager : AFHTTPSessionManager

+ (instancetype)sharedClient;

/**
 与业务强关联的处理代理。
 注意：这个代理是 强应用 ，所以只需要将handle实例赋值给delgate，而无需自己强应用。
 e.g: [CSSNetworkingManager sharedClient].delgate = [CSSNetworkingHandle new];
 */
@property (nonatomic, strong) id<CSSNetworingHandleDelegate> delgate;

/** 日志开关。仅DEBUG下有效，默认Single. */
@property (nonatomic, assign) CSSNetworkingLogOptions logOptions;

/** 超时时间 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

+ (BOOL)isNetworkReachable;
+ (BOOL)isNetworkViaWifi;
+ (BOOL)isNetworkViaWWAN;

@end

